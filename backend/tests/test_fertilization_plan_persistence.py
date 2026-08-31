import unittest
import uuid
from datetime import date
from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock, patch

from sqlalchemy.exc import IntegrityError

from app.models import FertilizationPlan, FertilizationPlanItem
from app.repositories.fertilization_plan import create_fertilization_plan
from app.routers import fertilization as router
from app.schemas.fertilization import (
    ApplicationRead,
    FertilizationRecommendationRead,
    FertilizationRecommendationRequest,
    FertilizerScenarioRead,
    FruitStage,
    LifeStage,
    NutrientStatus,
    ProductDoseRead,
    SoilAssessmentInput,
    SoilSource,
    YieldUnit,
)
from app.services.fertilization_fingerprint import (
    build_fertilization_input_fingerprint,
)
from tests.agronomic_config_factory import make_engine_config


def make_recommendation(parcel_id: uuid.UUID) -> FertilizationRecommendationRead:
    dose = ProductDoseRead(
        product_key="urea",
        product="Urea",
        guaranteed_analysis_pct={"N": 46.0},
        kg_ha=25.0,
        kg_manzana=17.61,
        g_plant=5.0,
        nutrient_contributions_kg_ha={"N": 11.5},
    )
    return FertilizationRecommendationRead(
        parcel_id=parcel_id,
        crop="CafÃ©",
        variety="Caturra",
        plant_age_months=40,
        life_stage=LifeStage.STABLE_PRODUCTION,
        fruit_stage=FruitStage.EXPANSION,
        target_green_kg_ha=920.0,
        engine_version="1.0.0",
        recommendation_status="reference_plan",
        nutrient_requirements=[],
        fertilizer_scenarios=[
            FertilizerScenarioRead(
                name="Escenario principal",
                selection_method="Documented cascade",
                is_mathematically_valid=True,
                products=[dose],
                application_schedule=[
                    ApplicationRead(
                        application_number=1,
                        moment="Inicio de lluvias",
                        fraction=0.25,
                        products=[dose],
                    )
                ],
            )
        ],
        limiting_nutrients=["N"],
        warnings=["Verify local conditions."],
        assumptions=["Reference efficiency."],
    )


class FertilizationPlanRepositoryTests(unittest.IsolatedAsyncioTestCase):
    async def test_persists_plan_header_and_scheduled_product_items(self):
        config = make_engine_config()
        recommendation = make_recommendation(uuid.uuid4())
        added: list[object] = []
        db = SimpleNamespace(
            add=MagicMock(side_effect=added.append),
            flush=AsyncMock(),
            commit=AsyncMock(),
            refresh=AsyncMock(),
        )

        async def assign_plan_id():
            plan = next(item for item in added if isinstance(item, FertilizationPlan))
            plan.id = uuid.uuid4()

        db.flush.side_effect = assign_plan_id

        plan = await create_fertilization_plan(
            db,
            recommendation=recommendation,
            config=config,
            method="sensor",
            input_fingerprint="a" * 64,
        )

        items = [item for item in added if isinstance(item, FertilizationPlanItem)]
        self.assertEqual(plan.reference_set_id, config.reference_set_id)
        self.assertEqual(plan.target_green_kg_ha, 920.0)
        self.assertEqual(plan.limiting_nutrients, ["N"])
        self.assertEqual(plan.input_fingerprint, "a" * 64)
        self.assertEqual(
            plan.recommendation_snapshot["parcel_id"],
            str(recommendation.parcel_id),
        )
        self.assertEqual(len(items), 1)
        self.assertEqual(items[0].fertilizer_product_id, config.products["urea"].id)
        self.assertEqual(items[0].application_number, 1)
        self.assertEqual(items[0].kg_ha, 25.0)
        db.commit.assert_awaited_once()

    async def test_returns_concurrently_created_plan_after_unique_conflict(self):
        config = make_engine_config()
        recommendation = make_recommendation(uuid.uuid4())
        existing = SimpleNamespace(id=uuid.uuid4())
        result = SimpleNamespace(scalar_one_or_none=MagicMock(return_value=existing))
        db = SimpleNamespace(
            add=MagicMock(),
            flush=AsyncMock(
                side_effect=IntegrityError("insert", {}, Exception("duplicate"))
            ),
            rollback=AsyncMock(),
            execute=AsyncMock(return_value=result),
        )

        plan = await create_fertilization_plan(
            db,
            recommendation=recommendation,
            config=config,
            method="sensor",
            input_fingerprint="b" * 64,
        )

        self.assertIs(plan, existing)
        db.rollback.assert_awaited_once()


class FertilizationPlanRouterTests(unittest.IsolatedAsyncioTestCase):
    async def test_returns_the_persisted_plan_identifier(self):
        user_id = uuid.uuid4()
        parcel_id = uuid.uuid4()
        config = make_engine_config()
        recommendation = make_recommendation(parcel_id)
        plan_id = uuid.uuid4()
        parcel = SimpleNamespace(
            id=parcel_id,
            crop_id=config.crop_id,
            planting_date=date(2023, 1, 1),
            area_hectares=1.0,
            plants_per_hectare=5000,
            farm=SimpleNamespace(user_id=user_id),
            crop=SimpleNamespace(name="CafÃ©"),
            variety=SimpleNamespace(id=uuid.uuid4(), name="Caturra"),
        )
        payload = FertilizationRecommendationRequest(
            parcel_id=parcel_id,
            target_yield=20,
            yield_unit=YieldUnit.QQ_GOLD_HA,
            fruit_stage=FruitStage.EXPANSION,
            soil=SoilAssessmentInput(
                source=SoilSource.SENSOR,
                nitrogen=NutrientStatus.DEFICIENT,
                phosphorus=NutrientStatus.DEFICIENT,
                potassium=NutrientStatus.DEFICIENT,
            ),
        )

        with (
            patch.object(
                router.parcel_repo,
                "get_parcel",
                AsyncMock(return_value=parcel),
            ),
            patch.object(
                router,
                "get_active_engine_config",
                AsyncMock(return_value=config),
            ),
            patch.object(
                router,
                "calculate_fertilization_recommendation",
                MagicMock(return_value=recommendation),
            ),
            patch.object(
                router.fertilization_plan_repo,
                "get_fertilization_plan_by_fingerprint",
                AsyncMock(return_value=None),
            ),
            patch.object(
                router.fertilization_plan_repo,
                "create_fertilization_plan",
                AsyncMock(
                    return_value=SimpleNamespace(
                        id=plan_id,
                        recommendation_snapshot=recommendation.model_dump(
                            mode="json"
                        ),
                    )
                ),
            ) as persist,
        ):
            result = await router.create_recommendation(
                payload=payload,
                current_user=SimpleNamespace(id=user_id, role="farmer"),
                db=AsyncMock(),
            )

        self.assertEqual(result.plan_id, plan_id)
        self.assertEqual(persist.await_args.kwargs["method"], "sensor")
        self.assertEqual(len(persist.await_args.kwargs["input_fingerprint"]), 64)

    async def test_reuses_a_plan_for_identical_inputs(self):
        user_id = uuid.uuid4()
        parcel_id = uuid.uuid4()
        config = make_engine_config()
        recommendation = make_recommendation(parcel_id)
        plan_id = uuid.uuid4()
        parcel = SimpleNamespace(
            id=parcel_id,
            crop_id=config.crop_id,
            planting_date=date(2023, 1, 1),
            area_hectares=1.0,
            plants_per_hectare=5000,
            farm=SimpleNamespace(user_id=user_id),
            crop=SimpleNamespace(name="Café"),
            variety=SimpleNamespace(id=uuid.uuid4(), name="Caturra"),
        )
        payload = FertilizationRecommendationRequest(
            parcel_id=parcel_id,
            target_yield=20,
            yield_unit=YieldUnit.QQ_GOLD_HA,
            fruit_stage=FruitStage.EXPANSION,
            soil=SoilAssessmentInput(
                source=SoilSource.SENSOR,
                nitrogen=NutrientStatus.DEFICIENT,
                phosphorus=NutrientStatus.DEFICIENT,
                potassium=NutrientStatus.DEFICIENT,
            ),
        )
        existing = SimpleNamespace(
            id=plan_id,
            recommendation_snapshot=recommendation.model_dump(mode="json"),
        )

        with (
            patch.object(
                router.parcel_repo,
                "get_parcel",
                AsyncMock(return_value=parcel),
            ),
            patch.object(
                router,
                "get_active_engine_config",
                AsyncMock(return_value=config),
            ),
            patch.object(
                router.fertilization_plan_repo,
                "get_fertilization_plan_by_fingerprint",
                AsyncMock(return_value=existing),
            ),
            patch.object(
                router,
                "calculate_fertilization_recommendation",
                MagicMock(),
            ) as calculate,
            patch.object(
                router.fertilization_plan_repo,
                "create_fertilization_plan",
                AsyncMock(),
            ) as persist,
        ):
            result = await router.create_recommendation(
                payload=payload,
                current_user=SimpleNamespace(id=user_id, role="farmer"),
                db=AsyncMock(),
            )

        self.assertEqual(result.plan_id, plan_id)
        calculate.assert_not_called()
        persist.assert_not_awaited()


class FertilizationFingerprintTests(unittest.TestCase):
    def test_is_stable_for_equivalent_input_order(self):
        first = build_fertilization_input_fingerprint(
            {"soil": {"ph": 5.5, "status": "deficient"}, "yield": 20}
        )
        second = build_fertilization_input_fingerprint(
            {"yield": 20, "soil": {"status": "deficient", "ph": 5.5}}
        )

        self.assertEqual(first, second)

    def test_changes_when_an_engine_input_changes(self):
        original = build_fertilization_input_fingerprint(
            {"reference_version": "1.0", "yield": 20}
        )
        changed = build_fertilization_input_fingerprint(
            {"reference_version": "1.0", "yield": 21}
        )

        self.assertNotEqual(original, changed)
