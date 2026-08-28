from typing import Any

import httpx

from app.core.config import settings


class WeatherProviderError(RuntimeError):
    """Base error raised when the meteorological provider cannot be used."""


class WeatherProviderTimeout(WeatherProviderError):
    pass


class WeatherProviderUnavailable(WeatherProviderError):
    pass


class OpenMeteoProvider:
    """Small adapter around Open-Meteo's public forecast endpoint."""

    _CURRENT_FIELDS = (
        "temperature_2m",
        "relative_humidity_2m",
        "precipitation",
        "weather_code",
        "wind_speed_10m",
    )
    _DAILY_FIELDS = (
        "weather_code",
        "temperature_2m_max",
        "temperature_2m_min",
        "precipitation_sum",
        "precipitation_probability_max",
        "et0_fao_evapotranspiration",
    )

    def __init__(
        self,
        client: httpx.AsyncClient | None = None,
        base_url: str | None = None,
    ):
        self._client = client
        self._base_url = (base_url or settings.WEATHER_API_BASE_URL).rstrip("/")

    async def fetch_forecast(
        self,
        latitude: float,
        longitude: float,
        days: int,
    ) -> dict[str, Any]:
        params = {
            "latitude": latitude,
            "longitude": longitude,
            "current": ",".join(self._CURRENT_FIELDS),
            "daily": ",".join(self._DAILY_FIELDS),
            "timezone": "auto",
            "forecast_days": days,
            "temperature_unit": "celsius",
            "wind_speed_unit": "kmh",
            "precipitation_unit": "mm",
        }
        response = await self._request_with_retry(params)

        try:
            payload = response.json()
        except ValueError as error:
            raise WeatherProviderUnavailable(
                "The weather service returned an invalid response."
            ) from error
        if not isinstance(payload, dict):
            raise WeatherProviderUnavailable(
                "The weather service returned an invalid response."
            )
        return payload

    async def _request_with_retry(self, params: dict[str, Any]) -> httpx.Response:
        """Retry one transient provider failure before giving up.

        Render free instances and the upstream weather service can both be
        briefly slow after an idle period. A single retry keeps that transient
        delay from turning into an unavailable dashboard card.
        """
        last_error: httpx.RequestError | None = None
        for attempt in range(2):
            try:
                if self._client is not None:
                    response = await self._client.get(
                        f"{self._base_url}/forecast",
                        params=params,
                    )
                else:
                    timeout = httpx.Timeout(15.0, connect=5.0)
                    async with httpx.AsyncClient(timeout=timeout) as client:
                        response = await client.get(
                            f"{self._base_url}/forecast",
                            params=params,
                        )
                response.raise_for_status()
                return response
            except httpx.TimeoutException as error:
                last_error = error
                if attempt == 0:
                    continue
                raise WeatherProviderTimeout(
                    "The weather service took too long to respond."
                ) from error
            except httpx.HTTPStatusError as error:
                if error.response.status_code >= 500 and attempt == 0:
                    continue
                raise WeatherProviderUnavailable(
                    f"The weather service returned HTTP {error.response.status_code}."
                ) from error
            except httpx.RequestError as error:
                last_error = error
                if attempt == 0:
                    continue
                raise WeatherProviderUnavailable(
                    "The weather service could not be reached."
                ) from error

        raise WeatherProviderUnavailable(
            "The weather service could not be reached."
        ) from last_error
