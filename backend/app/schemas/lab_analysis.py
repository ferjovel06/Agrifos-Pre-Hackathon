import uuid
from datetime import datetime, timezone

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator


class LabAnalysisValues(BaseModel):
    sample_code: str = Field(min_length=1, max_length=100)
    sampled_at: datetime
    depth_start_cm: float = Field(ge=0, le=200)
    depth_end_cm: float = Field(gt=0, le=300)

    lab: str = Field(min_length=2, max_length=150)
    ph: float = Field(ge=2, le=10)
    ph_method: str = Field(min_length=2, max_length=100)
    ec: float = Field(ge=0, le=20)
    ec_method: str = Field(min_length=2, max_length=100)
    organic_matter_pct: float = Field(ge=0, le=100)
    cic: float = Field(ge=0, le=200)

    clay_pct: float = Field(ge=0, le=100)
    silt_pct: float = Field(ge=0, le=100)
    sand_pct: float = Field(ge=0, le=100)

    nitrogen: float = Field(ge=0)
    phosphorus: float = Field(ge=0)
    phosphorus_method: str = Field(min_length=2, max_length=100)
    potassium: float = Field(ge=0)
    potassium_method: str = Field(min_length=2, max_length=100)
    calcium: float = Field(ge=0)
    magnesium: float = Field(ge=0)
    sulfur: float = Field(ge=0)

    @field_validator("sampled_at")
    @classmethod
    def sampled_at_not_in_future(cls, value: datetime) -> datetime:
        comparable = value
        if comparable.tzinfo is None:
            comparable = comparable.replace(tzinfo=timezone.utc)
        if comparable > datetime.now(timezone.utc):
            raise ValueError("sampled_at cannot be a future date.")
        return value

    @model_validator(mode="after")
    def validate_depth_and_texture(self):
        if self.depth_end_cm <= self.depth_start_cm:
            raise ValueError("depth_end_cm must be greater than depth_start_cm.")
        texture_total = self.clay_pct + self.silt_pct + self.sand_pct
        if not 99.5 <= texture_total <= 100.5:
            raise ValueError("clay_pct, silt_pct and sand_pct must total 100%.")
        return self


class LabAnalysisCreate(LabAnalysisValues):
    parcel_id: uuid.UUID


class LabAnalysisUpdate(BaseModel):
    sample_code: str | None = Field(default=None, min_length=1, max_length=100)
    sampled_at: datetime | None = None
    depth_start_cm: float | None = Field(default=None, ge=0, le=200)
    depth_end_cm: float | None = Field(default=None, gt=0, le=300)

    lab: str | None = Field(default=None, min_length=2, max_length=150)
    ph: float | None = Field(default=None, ge=2, le=10)
    ph_method: str | None = Field(default=None, min_length=2, max_length=100)
    ec: float | None = Field(default=None, ge=0, le=20)
    ec_method: str | None = Field(default=None, min_length=2, max_length=100)
    organic_matter_pct: float | None = Field(default=None, ge=0, le=100)
    cic: float | None = Field(default=None, ge=0, le=200)

    clay_pct: float | None = Field(default=None, ge=0, le=100)
    silt_pct: float | None = Field(default=None, ge=0, le=100)
    sand_pct: float | None = Field(default=None, ge=0, le=100)

    nitrogen: float | None = Field(default=None, ge=0)
    phosphorus: float | None = Field(default=None, ge=0)
    phosphorus_method: str | None = Field(default=None, min_length=2, max_length=100)
    potassium: float | None = Field(default=None, ge=0)
    potassium_method: str | None = Field(default=None, min_length=2, max_length=100)
    calcium: float | None = Field(default=None, ge=0)
    magnesium: float | None = Field(default=None, ge=0)
    sulfur: float | None = Field(default=None, ge=0)

    @field_validator("sampled_at")
    @classmethod
    def sampled_at_not_in_future(cls, value: datetime | None) -> datetime | None:
        if value is None:
            return value
        comparable = value
        if comparable.tzinfo is None:
            comparable = comparable.replace(tzinfo=timezone.utc)
        if comparable > datetime.now(timezone.utc):
            raise ValueError("sampled_at cannot be a future date.")
        return value


class LabAnalysisRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    parcel_id: uuid.UUID
    sample_code: str | None
    sampled_at: datetime | None
    depth_start_cm: float | None
    depth_end_cm: float | None
    lab: str
    ph: float
    ph_method: str | None
    ec: float | None
    ec_method: str | None
    organic_matter_pct: float
    cic: float
    clay_pct: float
    silt_pct: float
    sand_pct: float
    nitrogen: float
    phosphorus: float
    phosphorus_method: str | None
    potassium: float
    potassium_method: str | None
    calcium: float
    magnesium: float
    sulfur: float
    recorded_at: datetime
