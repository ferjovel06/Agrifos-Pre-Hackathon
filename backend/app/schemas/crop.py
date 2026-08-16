import uuid
from datetime import datetime

from pydantic import BaseModel, Field, ConfigDict


class CropCreate(BaseModel):
    name: str = Field(min_length=2, max_length=100)


class CropUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=100)


class CropRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    created_at: datetime
    updated_at: datetime