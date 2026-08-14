import uuid
from datetime import datetime

from pydantic import BaseModel, Field, ConfigDict


class FarmCreate(BaseModel):
    name: str = Field(min_length=2, max_length=150)
    area_hectares: float = Field(gt=0)
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)


class FarmUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=150)
    area_hectares: float | None = Field(default=None, gt=0)
    latitude: float | None = Field(default=None, ge=-90, le=90)
    longitude: float | None = Field(default=None, ge=-180, le=180)


class FarmRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    name: str
    area_hectares: float
    latitude: float
    longitude: float
    created_at: datetime
    updated_at: datetime