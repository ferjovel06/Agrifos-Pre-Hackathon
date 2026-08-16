import uuid
from datetime import datetime

from pydantic import BaseModel, Field, ConfigDict


class VarietyCreate(BaseModel):
    crop_id: uuid.UUID
    name: str = Field(min_length=2, max_length=100)


class VarietyUpdate(BaseModel):
    crop_id: uuid.UUID | None = None
    name: str | None = Field(default=None, min_length=2, max_length=100)


class VarietyRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    crop_id: uuid.UUID
    name: str
    created_at: datetime
    updated_at: datetime