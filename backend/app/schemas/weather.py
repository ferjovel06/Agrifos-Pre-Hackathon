import uuid
from datetime import date, datetime

from pydantic import BaseModel, Field


class CurrentWeatherRead(BaseModel):
    observed_at: datetime
    temperature_c: float
    relative_humidity_pct: int = Field(ge=0, le=100)
    precipitation_mm: float = Field(ge=0)
    weather_code: int
    condition: str
    wind_speed_kmh: float = Field(ge=0)


class DailyWeatherRead(BaseModel):
    date: date
    weather_code: int
    condition: str
    temperature_max_c: float
    temperature_min_c: float
    precipitation_mm: float = Field(ge=0)
    precipitation_probability_pct: int | None = Field(default=None, ge=0, le=100)
    reference_evapotranspiration_mm: float | None = Field(default=None, ge=0)


class WeatherForecastRead(BaseModel):
    farm_id: uuid.UUID
    farm_name: str
    provider: str
    latitude: float
    longitude: float
    timezone: str
    current: CurrentWeatherRead
    daily: list[DailyWeatherRead]
