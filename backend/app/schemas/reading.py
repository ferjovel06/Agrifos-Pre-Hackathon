import uuid
from datetime import datetime, timezone

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.schemas.diagnostic import SensorDiagnosticRead


class ReadingCreate(BaseModel):
    """Payload sent by the IoT sensor or the application when registering a reading."""

    parcel_id: uuid.UUID

    nitrogen: float = Field(..., ge=0, le=1000, description="Nitrogen (mg/kg)")
    phosphorus: float = Field(..., ge=0, le=1000, description="Phosphorus (mg/kg)")
    potassium: float = Field(..., ge=0, le=1000, description="Potassium (mg/kg)")
    ec: float = Field(..., ge=0, le=20, description="Electrical conductivity (dS/m)")
    ph: float = Field(..., ge=2, le=10, description="pH of the soil")
    temperature: float = Field(..., ge=-10, le=60, description="Temperature (°C)")
    humidity: float = Field(..., ge=0, le=100, description="Relative humidity (%)")

    # If the sensor does not send a timestamp, the server's time is used (server_default).
    recorded_at: datetime | None = Field(
        default=None, description="Timestamp of the reading (optional, defined by the sensor)."
    )

    @field_validator("recorded_at")
    @classmethod
    def recorded_at_not_in_future(cls, value: datetime | None) -> datetime | None:
        if value is None:
            return value
        if value.tzinfo is None:
            value = value.replace(tzinfo=timezone.utc)
        if value > datetime.now(timezone.utc):
            raise ValueError("recorded_at cannot be a future date.")
        return value


class ReadingRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    parcel_id: uuid.UUID
    nitrogen: float
    phosphorus: float
    potassium: float
    ec: float
    ph: float
    temperature: float
    humidity: float
    recorded_at: datetime


class ReadingCreateResponse(ReadingRead):
    diagnosis: SensorDiagnosticRead
