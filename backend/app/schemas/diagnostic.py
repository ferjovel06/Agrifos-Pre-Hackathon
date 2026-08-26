import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel

from app.services.soil_reference_ranges import SoilLevel


class DiagnosticRangeRead(BaseModel):
    optimal_min: float | None
    optimal_max: float | None
    deficient_below: float | None
    critical_above: float | None
    reference_method: str
    reference_confidence: str


class DiagnosticParameterRead(BaseModel):
    parameter: str
    label: str
    value: float
    unit: str
    level: SoilLevel
    message: str
    reference: DiagnosticRangeRead


class SensorContextRead(BaseModel):
    temperature_c: float
    humidity_pct: float


class SensorDiagnosticRead(BaseModel):
    reading_id: uuid.UUID
    parcel_id: uuid.UUID
    recorded_at: datetime
    crop: str
    source: Literal["sensor"] = "sensor"
    measurement_method: Literal["seven_in_one_sensor"] = "seven_in_one_sensor"
    engine_version: str
    overall_confidence: Literal["low"] = "low"
    reference_status: Literal["transferred_reference"] = "transferred_reference"
    reference_source: str
    context: SensorContextRead
    parameters: list[DiagnosticParameterRead]
    warnings: list[str]
