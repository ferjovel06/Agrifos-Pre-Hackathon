import unittest
import uuid
from types import SimpleNamespace
from unittest.mock import AsyncMock, patch

import httpx
from fastapi import HTTPException

from app.integrations.weather_provider import (
    OpenMeteoProvider,
    WeatherProviderRateLimited,
    WeatherProviderTimeout,
    WeatherProviderUnavailable,
)
from app.routers import weather as router
from app.services.weather_service import (
    InvalidWeatherDataError,
    WeatherForecastCache,
    WeatherService,
)


def provider_payload(days: int = 2):
    dates = [f"2026-09-0{index + 1}" for index in range(days)]
    return {
        "latitude": 12.1,
        "longitude": -86.2,
        "timezone": "America/Managua",
        "current": {
            "time": "2026-09-01T10:00",
            "temperature_2m": 27.4,
            "relative_humidity_2m": 78,
            "precipitation": 0.2,
            "weather_code": 61,
            "wind_speed_10m": 8.5,
        },
        "daily": {
            "time": dates,
            "weather_code": [61] * days,
            "temperature_2m_max": [30.0] * days,
            "temperature_2m_min": [21.0] * days,
            "precipitation_sum": [8.2] * days,
            "precipitation_probability_max": [75] * days,
            "et0_fao_evapotranspiration": [3.1] * days,
        },
    }


class OpenMeteoProviderTests(unittest.IsolatedAsyncioTestCase):
    async def test_requests_forecast_for_coordinates_and_days(self):
        async def handler(request: httpx.Request):
            self.assertEqual(request.url.params["latitude"], "12.1")
            self.assertEqual(request.url.params["longitude"], "-86.2")
            self.assertEqual(request.url.params["forecast_days"], "2")
            self.assertEqual(request.url.params["timezone"], "auto")
            self.assertIn("precipitation_sum", request.url.params["daily"])
            return httpx.Response(200, json=provider_payload())

        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            provider = OpenMeteoProvider(
                client=client,
                base_url="https://weather.test/v1",
            )
            result = await provider.fetch_forecast(12.1, -86.2, 2)

        self.assertEqual(result["timezone"], "America/Managua")

    async def test_translates_provider_timeout(self):
        attempts = 0

        async def handler(request: httpx.Request):
            nonlocal attempts
            attempts += 1
            raise httpx.ReadTimeout("timeout", request=request)

        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            provider = OpenMeteoProvider(client=client)
            with self.assertRaises(WeatherProviderTimeout):
                await provider.fetch_forecast(12.1, -86.2, 7)

        self.assertEqual(attempts, 2)

    async def test_retries_a_transient_provider_failure(self):
        attempts = 0

        async def handler(request: httpx.Request):
            nonlocal attempts
            attempts += 1
            if attempts == 1:
                raise httpx.ConnectError("temporary failure", request=request)
            return httpx.Response(200, json=provider_payload())

        async with httpx.AsyncClient(
            transport=httpx.MockTransport(handler)
        ) as client:
            provider = OpenMeteoProvider(client=client)
            result = await provider.fetch_forecast(12.1, -86.2, 2)

        self.assertEqual(attempts, 2)
        self.assertEqual(result["timezone"], "America/Managua")

    async def test_does_not_retry_rate_limit_response(self):
        attempts = 0

        async def handler(request: httpx.Request):
            nonlocal attempts
            attempts += 1
            return httpx.Response(429, request=request)

        async with httpx.AsyncClient(
            transport=httpx.MockTransport(handler)
        ) as client:
            provider = OpenMeteoProvider(client=client)
            with self.assertRaises(WeatherProviderRateLimited):
                await provider.fetch_forecast(12.1, -86.2, 7)

        self.assertEqual(attempts, 1)


class WeatherServiceTests(unittest.IsolatedAsyncioTestCase):
    def setUp(self):
        self.farm = SimpleNamespace(
            id=uuid.uuid4(),
            name="Finca El Edén",
            latitude=12.1,
            longitude=-86.2,
        )

    async def test_normalizes_current_and_daily_forecast(self):
        provider = SimpleNamespace(
            fetch_forecast=AsyncMock(return_value=provider_payload())
        )
        result = await WeatherService(provider=provider).forecast(self.farm, 2)

        provider.fetch_forecast.assert_awaited_once_with(
            latitude=12.1,
            longitude=-86.2,
            days=2,
        )
        self.assertEqual(result.farm_id, self.farm.id)
        self.assertEqual(result.current.condition, "Lluvia")
        self.assertEqual(result.daily[0].precipitation_probability_pct, 75)
        self.assertEqual(len(result.daily), 2)

    async def test_rejects_incomplete_daily_forecast(self):
        payload = provider_payload(days=1)
        provider = SimpleNamespace(fetch_forecast=AsyncMock(return_value=payload))

        with self.assertRaises(InvalidWeatherDataError):
            await WeatherService(
                provider=provider,
                cache=WeatherForecastCache(),
            ).forecast(self.farm, 2)

    async def test_reuses_a_fresh_cached_forecast(self):
        provider = SimpleNamespace(
            fetch_forecast=AsyncMock(return_value=provider_payload())
        )
        service = WeatherService(
            provider=provider,
            cache=WeatherForecastCache(),
        )

        first = await service.forecast(self.farm, 2)
        second = await service.forecast(self.farm, 2)

        self.assertIs(second, first)
        provider.fetch_forecast.assert_awaited_once()

    async def test_returns_stale_cache_during_provider_failure(self):
        now = 0.0
        provider = SimpleNamespace(
            fetch_forecast=AsyncMock(return_value=provider_payload())
        )
        cache = WeatherForecastCache(
            fresh_seconds=10,
            stale_seconds=60,
            clock=lambda: now,
        )
        service = WeatherService(provider=provider, cache=cache)
        first = await service.forecast(self.farm, 2)
        now = 20.0
        provider.fetch_forecast.side_effect = WeatherProviderUnavailable(
            "rate limited"
        )

        second = await service.forecast(self.farm, 2)

        self.assertIs(second, first)


class WeatherRouterTests(unittest.IsolatedAsyncioTestCase):
    def setUp(self):
        self.user = SimpleNamespace(id=uuid.uuid4(), role="farmer")
        self.farm = SimpleNamespace(
            id=uuid.uuid4(),
            user_id=self.user.id,
            name="Finca El Edén",
            latitude=12.1,
            longitude=-86.2,
        )
        self.db = AsyncMock()

    async def test_returns_forecast_for_owned_farm(self):
        expected = SimpleNamespace(provider="Open-Meteo")
        service = SimpleNamespace(forecast=AsyncMock(return_value=expected))
        with patch.object(
            router.farm_repo,
            "get_farm",
            AsyncMock(return_value=self.farm),
        ):
            result = await router.get_farm_forecast(
                farm_id=self.farm.id,
                days=7,
                current_user=self.user,
                db=self.db,
                service=service,
            )

        self.assertIs(result, expected)
        service.forecast.assert_awaited_once_with(self.farm, 7)

    async def test_rejects_foreign_farm(self):
        foreign_farm = SimpleNamespace(
            **{**self.farm.__dict__, "user_id": uuid.uuid4()}
        )
        service = SimpleNamespace(forecast=AsyncMock())
        with patch.object(
            router.farm_repo,
            "get_farm",
            AsyncMock(return_value=foreign_farm),
        ):
            with self.assertRaises(HTTPException) as raised:
                await router.get_farm_forecast(
                    farm_id=self.farm.id,
                    days=7,
                    current_user=self.user,
                    db=self.db,
                    service=service,
                )

        self.assertEqual(raised.exception.status_code, 403)
        service.forecast.assert_not_awaited()


if __name__ == "__main__":
    unittest.main()
