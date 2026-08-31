import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.models import FertilizationPlan, FertilizationPlanItem
from app.schemas.fertilization import FertilizationRecommendationRead
from app.services.agronomic_config import AgronomicEngineConfig


async def create_fertilization_plan(
    db: AsyncSession,
    *,
    recommendation: FertilizationRecommendationRead,
    config: AgronomicEngineConfig,
    method: str,
    reading_id: uuid.UUID | None = None,
    lab_analysis_id: uuid.UUID | None = None,
) -> FertilizationPlan:
    plan = FertilizationPlan(
        parcel_id=recommendation.parcel_id,
        reading_id=reading_id,
        lab_analysis_id=lab_analysis_id,
        reference_set_id=config.reference_set_id,
        method=method,
        target_green_kg_ha=recommendation.target_green_kg_ha,
        plant_age_months=recommendation.plant_age_months,
        life_stage=recommendation.life_stage.value,
        fruit_stage=recommendation.fruit_stage.value,
        engine_version=recommendation.engine_version,
        recommendation_status=recommendation.recommendation_status,
        nutrient_requirements=[
            requirement.model_dump(mode="json")
            for requirement in recommendation.nutrient_requirements
        ],
        limiting_nutrients=list(recommendation.limiting_nutrients),
        warnings=list(recommendation.warnings),
        assumptions=list(recommendation.assumptions),
    )
    db.add(plan)
    await db.flush()

    for scenario in recommendation.fertilizer_scenarios:
        for application in scenario.application_schedule:
            for dose in application.products:
                product = config.products.get(dose.product_key)
                if product is None:
                    raise ValueError(
                        "Recommendation uses unknown fertilizer product "
                        f"'{dose.product_key}'."
                    )
                db.add(
                    FertilizationPlanItem(
                        plan_id=plan.id,
                        fertilizer_product_id=product.id,
                        scenario_name=scenario.name,
                        selection_method=scenario.selection_method,
                        scenario_is_valid=scenario.is_mathematically_valid,
                        application_number=application.application_number,
                        moment=application.moment,
                        fraction=application.fraction,
                        kg_ha=dose.kg_ha,
                        kg_manzana=dose.kg_manzana,
                        g_plant=dose.g_plant,
                        guaranteed_analysis_pct=dict(dose.guaranteed_analysis_pct),
                        nutrient_contributions_kg_ha=dict(
                            dose.nutrient_contributions_kg_ha
                        ),
                    )
                )

    await db.commit()
    await db.refresh(plan)
    return plan
