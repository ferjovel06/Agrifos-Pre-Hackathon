import unittest
import uuid
from datetime import date, datetime, timedelta, timezone
from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock, patch

from fastapi import HTTPException

from app.routers import parcels
from app.schemas.parcel import ParcelConfigurationUpdate


class ParcelConfigurationTests(unittest.IsolatedAsyncioTestCase):
    def setUp(self):
        self.user = SimpleNamespace(id=uuid.uuid4(), role="farmer")
        self.crop_id = uuid.uuid4()
        self.variety_id = uuid.uuid4()
        self.stage_id = uuid.uuid4()
        self.parcel = SimpleNamespace(
            id=uuid.uuid4(),
            farm_id=uuid.uuid4(),
            crop_id=uuid.uuid4(),
            variety_id=None,
            name="Old parcel",
            area_hectares=1.0,
            plants_per_hectare=3000,
            planting_date=date(2025, 1, 1),
        )
        self.payload = ParcelConfigurationUpdate(
            crop_id=self.crop_id,
            variety_id=self.variety_id,
            phenological_stage_template_id=self.stage_id,
            name="Updated parcel",
            area_hectares=2.0,
            plants_per_hectare=4000,
            planting_date=date(2025, 2, 1),
        )
        self.db = MagicMock()
        self.db.commit = AsyncMock()
        self.db.rollback = AsyncMock()
        self.db.refresh = AsyncMock()

    def patches(self, *, instances=None, template_crop_id=None):
        return (
            patch.object(
                parcels,
                "_get_owned_parcel",
                AsyncMock(return_value=self.parcel),
            ),
            patch.object(
                parcels.stage_repo,
                "get_template",
                AsyncMock(
                    return_value=SimpleNamespace(
                        crop_id=template_crop_id or self.crop_id
                    )
                ),
            ),
            patch.object(
                parcels.stage_repo,
                "list_instances",
                AsyncMock(return_value=instances or []),
            ),
            patch.object(
                parcels.variety_repo,
                "get_variety",
                AsyncMock(
                    return_value=SimpleNamespace(crop_id=self.crop_id)
                ),
            ),
        )

    async def test_updates_parcel_and_stage_with_one_commit(self):
        patches = self.patches()
        with patches[0], patches[1], patches[2], patches[3]:
            result = await parcels.update_parcel_configuration(
                parcel_id=self.parcel.id,
                payload=self.payload,
                current_user=self.user,
                db=self.db,
            )

        self.assertIs(result, self.parcel)
        self.assertEqual(self.parcel.crop_id, self.crop_id)
        self.assertEqual(self.parcel.variety_id, self.variety_id)
        created_stage = self.db.add.call_args.args[0]
        self.assertEqual(created_stage.template_id, self.stage_id)
        self.db.commit.assert_awaited_once()
        self.db.rollback.assert_not_awaited()

    async def test_rolls_back_when_the_single_commit_fails(self):
        self.db.commit.side_effect = RuntimeError("database unavailable")
        patches = self.patches()
        with patches[0], patches[1], patches[2], patches[3]:
            with self.assertRaisesRegex(RuntimeError, "database unavailable"):
                await parcels.update_parcel_configuration(
                    parcel_id=self.parcel.id,
                    payload=self.payload,
                    current_user=self.user,
                    db=self.db,
                )

        self.db.rollback.assert_awaited_once()
        self.db.refresh.assert_not_awaited()

    async def test_rejects_a_stage_from_another_crop_before_writing(self):
        patches = self.patches(template_crop_id=uuid.uuid4())
        with patches[0], patches[1], patches[2], patches[3]:
            with self.assertRaises(HTTPException) as raised:
                await parcels.update_parcel_configuration(
                    parcel_id=self.parcel.id,
                    payload=self.payload,
                    current_user=self.user,
                    db=self.db,
                )

        self.assertEqual(raised.exception.status_code, 422)
        self.db.commit.assert_not_awaited()

    async def test_same_day_backward_selection_becomes_current(self):
        now = datetime.now(timezone.utc)
        higher_stage = SimpleNamespace(
            template_id=uuid.uuid4(),
            actual_date=date.today(),
            selected_at=now - timedelta(minutes=1),
        )
        selected_stage = SimpleNamespace(
            template_id=self.stage_id,
            actual_date=date.today(),
            selected_at=now - timedelta(minutes=2),
        )
        patches = self.patches(instances=[selected_stage, higher_stage])
        with patches[0], patches[1], patches[2], patches[3]:
            await parcels.update_parcel_configuration(
                parcel_id=self.parcel.id,
                payload=self.payload,
                current_user=self.user,
                db=self.db,
            )

        self.assertGreater(selected_stage.selected_at, higher_stage.selected_at)
        self.assertIs(
            max(
                [selected_stage, higher_stage],
                key=lambda stage: stage.selected_at,
            ),
            selected_stage,
        )


if __name__ == "__main__":
    unittest.main()
