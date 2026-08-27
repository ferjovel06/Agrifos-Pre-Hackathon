from datetime import date, datetime
from typing import Any

from app.integrations.weather_provider import OpenMeteoProvider
from app.models import Farm
from app.schemas.weather import (
    CurrentWeatherRead,
    DailyWeatherRead,
    WeatherForecastRead,
)


class InvalidWeatherDataError(RuntimeError):
    pass


class WeatherService:
    def __init__(self, provider: OpenMeteoProvider | None = None):
        self._provider = provider or OpenMeteoProvider()

    async def forecast(self, farm: Farm, days: int) -> WeatherForecastRead:
        payload = await self._provider.fetch_forecast(
            latitude=farm.latitude,
            longitude=farm.longitude,
            days=days,
        )
        try:
            current_data = payload["current"]
            daily_data = payload["daily"]
            current = CurrentWeatherRead(
                observed_at=datetime.fromisoformat(current_data["time"]),
                temperature_c=current_data["temperature_2m"],
                relative_humidity_pct=current_data["relative_humidity_2m"],
                precipitation_mm=current_data["precipitation"],
                weather_code=current_data["weather_code"],
                condition=weather_condition(current_data["weather_code"]),
                wind_speed_kmh=current_data["wind_speed_10m"],
            )
            daily = self._daily_forecast(daily_data, days)
            return WeatherForecastRead(
                farm_id=farm.id,
                farm_name=farm.name,
                provider="Open-Meteo",
                latitude=payload.get("latitude", farm.latitude),
                longitude=payload.get("longitude", farm.longitude),
                timezone=payload["timezone"],
                current=current,
                daily=daily,
            )
        except (KeyError, TypeError, ValueError) as error:
            raise InvalidWeatherDataError(
                "The weather provider returned incomplete forecast data."
            ) from error

    def _daily_forecast(
        self,
        values: dict[str, list[Any]],
        requested_days: int,
    ) -> list[DailyWeatherRead]:
        required = (
            "time",
            "weather_code",
            "temperature_2m_max",
            "temperature_2m_min",
            "precipitation_sum",
            "precipitation_probability_max",
            "et0_fao_evapotranspiration",
        )
        if any(not isinstance(values.get(field), list) for field in required):
            raise InvalidWeatherDataError(
                "The weather provider returned incomplete daily data."
            )
        available = min(len(values[field]) for field in required)
        if available < requested_days:
            raise InvalidWeatherDataError(
                "The weather provider returned fewer days than requested."
            )
        return [
            DailyWeatherRead(
                date=date.fromisoformat(values["time"][index]),
                weather_code=values["weather_code"][index],
                condition=weather_condition(values["weather_code"][index]),
                temperature_max_c=values["temperature_2m_max"][index],
                temperature_min_c=values["temperature_2m_min"][index],
                precipitation_mm=values["precipitation_sum"][index],
                precipitation_probability_pct=values[
                    "precipitation_probability_max"
                ][index],
                reference_evapotranspiration_mm=values[
                    "et0_fao_evapotranspiration"
                ][index],
            )
            for index in range(requested_days)
        ]


def weather_condition(code: int) -> str:
    if code == 0:
        return "Despejado"
    if code in {1, 2}:
        return "Parcialmente nublado"
    if code == 3:
        return "Nublado"
    if code in {45, 48}:
        return "Niebla"
    if 51 <= code <= 57:
        return "Llovizna"
    if 61 <= code <= 67:
        return "Lluvia"
    if 71 <= code <= 77:
        return "Nieve"
    if 80 <= code <= 82:
        return "Chubascos"
    if 85 <= code <= 86:
        return "Chubascos de nieve"
    if 95 <= code <= 99:
        return "Tormenta eléctrica"
    return "Condición desconocida"
