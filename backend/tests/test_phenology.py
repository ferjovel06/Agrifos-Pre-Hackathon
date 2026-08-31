import unittest
import uuid
from datetime import date
from types import SimpleNamespace
from unittest.mock import AsyncMock, patch

from fastapi import HTTPException

from app.models import ParcelPhenologicalStage, PhenologicalStageTemplate
from app.routers import phenology as router
from app.schemas.phenology import StageInstanceCreate, StageInstanceRead


class PhenologyModelTests(unittest.TestCase):
    def test_template_and_instance_are_separate_entities(self):
        self.assertEqual(
            PhenologicalStageTemplate.__tablename__,
            "phenological_stage_templates",
        )
        self.assertEqual(
            ParcelPhenologicalStage.__tablename__,
            "parcel_phenological_stages",
        )
        self.assertFalse(
            PhenologicalStageTemplate.__table__.c.crop_id.nullable
        )
        self.assertFalse(ParcelPhenologicalStage.__table__.c.parcel_id.nullable)
        self.assertFalse(ParcelPhenologicalStage.__table__.c.template_id.nullable)

    def test_instance_response_exposes_its_template_details(self):
        template = PhenologicalStageTemplate(
            crop_id=uuid.uuid4(),
            name="FloraciÃ³n",
            stage_order=3,
            duration_days=15,
        )
        template.id = uuid.uuid4()
        instance = ParcelPhenologicalStage(
            parcel_id=uuid.uuid4(),
            template_id=template.id,
            estimated_date=date(2026, 10, 1),
            actual_date=date(2026, 10, 3),
            template=template,
        )
        instance.id = uuid.uuid4()

        response = StageInstanceRead.model_validate(instance)

        self.assertEqual(response.name, "FloraciÃ³n")
        self.assertEqual(response.stage_order, 3)
        self.assertEqual(response.duration_days, 15)


class PhenologyRouterTests(unittest.IsolatedAsyncioTestCase):
    async def test_creates_an_instance_linked_to_a_compatible_template(self):
        user_id = uuid.uuid4()
        crop_id = uuid.uuid4()
        parcel = SimpleNamespace(
            id=uuid.uuid4(),
            crop_id=crop_id,
            farm_id=uuid.uuid4(),
        )
        template = PhenologicalStageTemplate(
            crop_id=crop_id,
            name="FloraciÃ³n",
            stage_order=3,
            duration_days=15,
        )
        template.id = uuid.uuid4()
        payload = StageInstanceCreate(
            parcel_id=parcel.id,
            template_id=template.id,
            estimated_date=date(2026, 10, 1),
        )

        async def save_instance(_db, instance):
            instance.id = uuid.uuid4()
            instance.template_id = template.id
            return instance

        with (
            patch.object(
                router.parcel_repo,
                "get_parcel",
                AsyncMock(return_value=parcel),
            ),
            patch.object(
                router.farm_repo,
                "get_farm",
                AsyncMock(return_value=SimpleNamespace(user_id=user_id)),
            ),
            patch.object(
                router.stage_repo,
                "get_template",
                AsyncMock(return_value=template),
            ),
            patch.object(
                router.stage_repo,
                "create_instance",
                AsyncMock(side_effect=save_instance),
            ) as create_instance,
        ):
            result = await router.create_instance(
                payload=payload,
                current_user=SimpleNamespace(id=user_id, role="farmer"),
                db=AsyncMock(),
            )

        self.assertIs(result.template, template)
        self.assertEqual(result.parcel_id, parcel.id)
        create_instance.assert_awaited_once()

    async def test_rejects_a_template_for_a_different_crop(self):
        user_id = uuid.uuid4()
        parcel = SimpleNamespace(
            id=uuid.uuid4(),
            crop_id=uuid.uuid4(),
            farm_id=uuid.uuid4(),
        )
        template = PhenologicalStageTemplate(
            crop_id=uuid.uuid4(),
            name="FloraciÃ³n",
            stage_order=3,
            duration_days=15,
        )
        template.id = uuid.uuid4()

        with (
            patch.object(
                router.parcel_repo,
                "get_parcel",
                AsyncMock(return_value=parcel),
            ),
            patch.object(
                router.farm_repo,
                "get_farm",
                AsyncMock(return_value=SimpleNamespace(user_id=user_id)),
            ),
            patch.object(
                router.stage_repo,
                "get_template",
                AsyncMock(return_value=template),
            ),
        ):
            with self.assertRaises(HTTPException) as raised:
                await router.create_instance(
                    payload=StageInstanceCreate(
                        parcel_id=parcel.id,
                        template_id=template.id,
                    ),
                    current_user=SimpleNamespace(id=user_id, role="farmer"),
                    db=AsyncMock(),
                )

        self.assertEqual(raised.exception.status_code, 422)
