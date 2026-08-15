import uuid
from datetime import date

from pydantic import BaseModel, Field, ConfigDict


class StageTemplateCreate(BaseModel):
    crop_id: uuid.UUID
    name: str = Field(min_length=2, max_length=100)
    stage_order: int = Field(ge=1)
    duration_days: int | None = Field(default=None, ge=0)


class StageTemplateUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=100)
    stage_order: int | None = Field(default=None, ge=1)
    duration_days: int | None = Field(default=None, ge=0)


class StageTemplateRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    crop_id: uuid.UUID
    name: str
    stage_order: int
    duration_days: int | None


class StageInstanceCreate(BaseModel):
    parcel_id: uuid.UUID
    template_id: uuid.UUID
    estimated_date: date | None = None
    actual_date: date | None = None


class StageInstanceUpdate(BaseModel):
    estimated_date: date | None = None
    actual_date: date | None = None


class StageInstanceRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    parcel_id: uuid.UUID
    template_id: uuid.UUID
    name: str
    stage_order: int
    duration_days: int | None
    estimated_date: date | None
    actual_date: date | None