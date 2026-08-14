import uuid
from datetime import date, datetime
from enum import Enum

from pydantic import BaseModel, Field, ConfigDict


class CoffeeFertilizationStage(str, Enum):
    PRE_FLOWERING = "PRE_FLOWERING"
    FLOWERING = "FLOWERING"
    FRUIT_SET = "FRUIT_SET"
    FRUIT_DEVELOPMENT = "FRUIT_DEVELOPMENT"
    POST_HARVEST = "POST_HARVEST"


class CornFertilizationStage(str, Enum):
    PRE_PLANTING = "PRE_PLANTING"
    VEGETATIVE = "VEGETATIVE"
    V6 = "V6"
    V10 = "V10"
    VT = "VT"
    R1 = "R1"
    GRAIN_FILL = "GRAIN_FILL"


GrowthStage = CoffeeFertilizationStage | CornFertilizationStage


class ParcelCreate(BaseModel):
    farm_id: uuid.UUID
    crop_id: uuid.UUID
    variety_id: uuid.UUID | None = None
    name: str = Field(min_length=2, max_length=150)
    area_hectares: float = Field(gt=0)
    planting_date: date
    growth_stage: GrowthStage


class ParcelUpdate(BaseModel):
    crop_id: uuid.UUID | None = None
    variety_id: uuid.UUID | None = None
    name: str | None = Field(default=None, min_length=2, max_length=150)
    area_hectares: float | None = Field(default=None, gt=0)
    planting_date: date | None = None
    growth_stage: GrowthStage | None = None


class ParcelRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    farm_id: uuid.UUID
    crop_id: uuid.UUID
    variety_id: uuid.UUID | None
    name: str
    area_hectares: float
    planting_date: date
    growth_stage: str
    created_at: datetime
    updated_at: datetime