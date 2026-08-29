import logging
from datetime import datetime
from typing import Any, Protocol

import httpx

from app.core.config import settings


logger = logging.getLogger(__name__)


class WeatherProviderError(RuntimeError):
    """Base error raised when the meteorological provider cannot be used."""


class WeatherProviderTimeout(WeatherProviderError):
    pass


class WeatherProviderUnavailable(WeatherProviderError):
    pass


class WeatherProviderRateLimited(WeatherProviderUnavailable):
    pass


class WeatherProvider(Protocol):
    async def fetch_forecast(
        self,
        latitude: float,
        longitude: float,
        days: int,
    ) -> dict[str, Any]: ...


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
                if error.response.status_code == 429:
                    raise WeatherProviderRateLimited(
                        "The weather service rate limit was reached."
                    ) from error
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


class MetNorwayProvider:
    """Fallback adapter for MET Norway Locationforecast 2.0 compact data."""

    def __init__(
        self,
        client: httpx.AsyncClient | None = None,
        base_url: str | None = None,
        user_agent: str | None = None,
    ):
        self._client = client
        self._base_url = (
            base_url or settings.WEATHER_FALLBACK_API_BASE_URL
        ).rstrip("/")
        self._user_agent = user_agent or settings.WEATHER_FALLBACK_USER_AGENT

    async def fetch_forecast(
        self,
        latitude: float,
        longitude: float,
        days: int,
    ) -> dict[str, Any]:
        params = {
            "lat": round(latitude, 4),
            "lon": round(longitude, 4),
        }
        headers = {
            "User-Agent": self._user_agent,
            "Accept": "application/json",
        }
        try:
            if self._client is not None:
                response = await self._client.get(
                    f"{self._base_url}/compact",
                    params=params,
                    headers=headers,
                )
            else:
                timeout = httpx.Timeout(15.0, connect=5.0)
                async with httpx.AsyncClient(timeout=timeout) as client:
                    response = await client.get(
                        f"{self._base_url}/compact",
                        params=params,
                        headers=headers,
                    )
            response.raise_for_status()
        except httpx.TimeoutException as error:
            raise WeatherProviderTimeout(
                "The fallback weather service took too long to respond."
            ) from error
        except httpx.HTTPStatusError as error:
            raise WeatherProviderUnavailable(
                "The fallback weather service returned "
                f"HTTP {error.response.status_code}."
            ) from error
        except httpx.RequestError as error:
            raise WeatherProviderUnavailable(
                "The fallback weather service could not be reached."
            ) from error

        try:
            payload = response.json()
            return self._normalize(payload, latitude, longitude, days)
        except (KeyError, TypeError, ValueError) as error:
            raise WeatherProviderUnavailable(
                "The fallback weather service returned invalid data."
            ) from error

    def _normalize(
        self,
        payload: dict[str, Any],
        latitude: float,
        longitude: float,
        days: int,
    ) -> dict[str, Any]:
        timeseries = payload["properties"]["timeseries"]
        if not isinstance(timeseries, list) or not timeseries:
            raise ValueError("The fallback forecast has no time series.")

        first = timeseries[0]
        current_details = first["data"]["instant"]["details"]
        current_period = _met_period(first["data"])
        daily_values: dict[str, dict[str, Any]] = {}

        for entry in timeseries:
            observed_at = _parse_met_time(entry["time"])
            day_key = observed_at.date().isoformat()
            if day_key not in daily_values and len(daily_values) >= days:
                continue
            details = entry["data"]["instant"]["details"]
            period = _met_period(entry["data"])
            values = daily_values.setdefault(
                day_key,
                {
                    "temperatures": [],
                    "precipitation": 0.0,
                    "probabilities": [],
                    "weather_codes": [],
                },
            )
            values["temperatures"].append(details["air_temperature"])
            if period is not None:
                period_details = period.get("details", {})
                values["precipitation"] += period_details.get(
                    "precipitation_amount", 0.0
                )
                probability = period_details.get("probability_of_precipitation")
                if probability is not None:
                    values["probabilities"].append(round(probability))
                symbol = period.get("summary", {}).get("symbol_code")
                if symbol:
                    values["weather_codes"].append(_met_weather_code(symbol))

        dates = list(daily_values)[:days]
        coordinates = payload.get("geometry", {}).get("coordinates", [])
        normalized_latitude = (
            coordinates[1] if len(coordinates) >= 2 else latitude
        )
        normalized_longitude = (
            coordinates[0] if len(coordinates) >= 2 else longitude
        )
        current_period_details = (
            current_period.get("details", {}) if current_period else {}
        )
        current_symbol = (
            current_period.get("summary", {}).get("symbol_code")
            if current_period
            else None
        )

        return {
            "provider": "MET Norway",
            "latitude": normalized_latitude,
            "longitude": normalized_longitude,
            "timezone": "UTC",
            "current": {
                "time": first["time"],
                "temperature_2m": current_details["air_temperature"],
                "relative_humidity_2m": round(
                    current_details["relative_humidity"]
                ),
                "precipitation": current_period_details.get(
                    "precipitation_amount", 0.0
                ),
                "weather_code": _met_weather_code(current_symbol),
                "wind_speed_10m": current_details["wind_speed"],
            },
            "daily": {
                "time": dates,
                "weather_code": [
                    _representative_weather_code(
                        daily_values[day]["weather_codes"]
                    )
                    for day in dates
                ],
                "temperature_2m_max": [
                    max(daily_values[day]["temperatures"]) for day in dates
                ],
                "temperature_2m_min": [
                    min(daily_values[day]["temperatures"]) for day in dates
                ],
                "precipitation_sum": [
                    round(daily_values[day]["precipitation"], 2) for day in dates
                ],
                "precipitation_probability_max": [
                    max(daily_values[day]["probabilities"])
                    if daily_values[day]["probabilities"]
                    else None
                    for day in dates
                ],
                "et0_fao_evapotranspiration": [None for _ in dates],
            },
        }


class FallbackWeatherProvider:
    def __init__(
        self,
        primary: WeatherProvider | None = None,
        fallback: WeatherProvider | None = None,
    ):
        self._primary = primary or OpenMeteoProvider()
        self._fallback = fallback or MetNorwayProvider()

    async def fetch_forecast(
        self,
        latitude: float,
        longitude: float,
        days: int,
    ) -> dict[str, Any]:
        try:
            return await self._primary.fetch_forecast(latitude, longitude, days)
        except WeatherProviderError as primary_error:
            logger.warning(
                "Primary weather provider failed; using fallback: %s",
                primary_error,
            )
            try:
                return await self._fallback.fetch_forecast(
                    latitude,
                    longitude,
                    days,
                )
            except WeatherProviderError as fallback_error:
                raise WeatherProviderUnavailable(
                    "Both weather services are temporarily unavailable."
                ) from fallback_error


def _parse_met_time(value: str) -> datetime:
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def _met_period(data: dict[str, Any]) -> dict[str, Any] | None:
    for key in ("next_1_hours", "next_6_hours", "next_12_hours"):
        period = data.get(key)
        if isinstance(period, dict):
            return period
    return None


def _met_weather_code(symbol: str | None) -> int:
    if not symbol:
        return 3
    base = symbol.removesuffix("_day").removesuffix("_night").removesuffix(
        "_polartwilight"
    )
    if "thunder" in base:
        return 95
    if "heavyrainshowers" in base:
        return 82
    if "rainshowers" in base:
        return 81
    if "heavysnowshowers" in base or "snowshowers" in base:
        return 85
    if "heavysleet" in base or "sleet" in base:
        return 67
    if "heavyrain" in base:
        return 65
    if "lightrain" in base or "rain" in base:
        return 63
    if "heavysnow" in base:
        return 75
    if "lightsnow" in base or "snow" in base:
        return 73
    if "fog" in base:
        return 45
    if "partlycloudy" in base:
        return 2
    if "cloudy" in base:
        return 3
    if "fair" in base:
        return 1
    if "clearsky" in base:
        return 0
    return 3


def _representative_weather_code(codes: list[int]) -> int:
    return max(codes, default=3)
