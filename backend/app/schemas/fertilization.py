import uuid
from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field, model_validator


class YieldUnit(str, Enum):
    KG_GREEN_HA = "kg_green_ha"
    QQ_GOLD_HA = "qq_gold_ha"
    QQ_CHERRY_HA = "qq_cherry_ha"


class SoilSource(str, Enum):
    SENSOR = "sensor"
    LABORATORY = "laboratory"
    MIXED = "mixed"


class NutrientStatus(str, Enum):
    DEFICIENT = "deficient"
    PROBABLE_RESPONSE = "probable_response"
    ADEQUATE = "adequate"
    HIGH = "high"


class FruitStage(str, Enum):
    NO_FLOWERING = "no_flowering"
    FLOWERING = "flowering"
    FRUIT_SET = "fruit_set"
    EXPANSION = "expansion"
    FILLING = "filling"
    RIPENING = "ripening"
    HARVEST = "harvest"


class LifeStage(str, Enum):
    NURSERY = "nursery"
    ESTABLISHMENT = "establishment"
    VEGETATIVE_GROWTH = "vegetative_growth"
    INITIAL_PRODUCTION = "initial_production"
    STABLE_PRODUCTION = "stable_production"


class SoilAssessmentInput(BaseModel):
    source: SoilSource
    nitrogen: NutrientStatus
    phosphorus: NutrientStatus
    potassium: NutrientStatus
    phosphorus_method: str | None = None
    potassium_method: str | None = None
    ph: float | None = Field(default=None, ge=2, le=10)
    ec_ds_m: float | None = Field(default=None, ge=0, le=20)
    acidity_reserve_available: bool = False

    @model_validator(mode="after")
    def require_laboratory_methods(self):
        if self.source in {SoilSource.LABORATORY, SoilSource.MIXED}:
            if (
                not self.phosphorus_method
                or not self.phosphorus_method.strip()
                or not self.potassium_method
                or not self.potassium_method.strip()
            ):
                raise ValueError(
                    "Laboratory and mixed assessments require phosphorus_method "
                    "and potassium_method."
                )
        return self


class FertilizationRecommendationRequest(BaseModel):
    parcel_id: uuid.UUID
    target_yield: float | None = Field(default=None, gt=0)
    yield_unit: YieldUnit
    fruit_stage: FruitStage
    soil: SoilAssessmentInput | None = None
    reading_id: uuid.UUID | None = None
    lab_analysis_id: uuid.UUID | None = None

    @model_validator(mode="after")
    def require_exactly_one_soil_source(self):
        if (self.soil is None) == (self.lab_analysis_id is None):
            raise ValueError(
                "Provide exactly one of soil or lab_analysis_id."
            )
        if self.reading_id is not None and (
            self.soil is None or self.soil.source != SoilSource.SENSOR
        ):
            raise ValueError("reading_id can only accompany a sensor assessment.")
        return self


class NutrientRequirementRead(BaseModel):
    nutrient: str
    unit: str
    exported_kg_ha: float
    total_demand_kg_ha: float
    soil_credit_kg_ha: float
    fertilizer_requirement_kg_ha: float
    soil_status: NutrientStatus


class ProductDoseRead(BaseModel):
    product_key: str
    product: str
    guaranteed_analysis_pct: dict[str, float]
    kg_ha: float
    kg_manzana: float
    g_plant: float
    nutrient_contributions_kg_ha: dict[str, float]


class ApplicationRead(BaseModel):
    application_number: int
    moment: str
    month_after_planting: int | None = None
    fraction: float
    products: list[ProductDoseRead]


class FertilizerScenarioRead(BaseModel):
    name: str
    selection_method: str
    is_mathematically_valid: bool
    products: list[ProductDoseRead]
    application_schedule: list[ApplicationRead]


class FertilizationRecommendationRead(BaseModel):
    plan_id: uuid.UUID | None = None
    source_type: str | None = None
    source_recorded_at: datetime | None = None
    parcel_id: uuid.UUID
    crop: str
    variety: str
    plant_age_months: int
    life_stage: LifeStage
    fruit_stage: FruitStage
    target_green_kg_ha: float
    engine_version: str
    recommendation_status: str
    nutrient_requirements: list[NutrientRequirementRead]
    fertilizer_scenarios: list[FertilizerScenarioRead]
    limiting_nutrients: list[str]
    warnings: list[str]
    assumptions: list[str]
