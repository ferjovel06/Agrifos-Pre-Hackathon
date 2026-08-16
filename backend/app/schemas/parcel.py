import uuid
from datetime import date, datetime

from pydantic import BaseModel, Field, ConfigDict


class ParcelCreate(BaseModel):
    farm_id: uuid.UUID
    crop_id: uuid.UUID
    variety_id: uuid.UUID | None = None
    name: str = Field(min_length=2, max_length=150)
    area_hectares: float = Field(gt=0)
    planting_date: date


class ParcelUpdate(BaseModel):
    crop_id: uuid.UUID | None = None
    variety_id: uuid.UUID | None = None
    name: str | None = Field(default=None, min_length=2, max_length=150)
    area_hectares: float | None = Field(default=None, gt=0)
    planting_date: date | None = None


class ParcelRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    farm_id: uuid.UUID
    crop_id: uuid.UUID
    variety_id: uuid.UUID | None
    name: str
    area_hectares: float
    planting_date: date
    created_at: datetime
    updated_at: datetime