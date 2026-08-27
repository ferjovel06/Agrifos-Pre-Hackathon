import unittest
import uuid
from datetime import datetime, timedelta, timezone
from types import SimpleNamespace
from unittest.mock import AsyncMock, patch

from fastapi import HTTPException
from pydantic import ValidationError

from app.models import LabAnalysis
from app.routers import lab_analysis as router
from app.schemas.lab_analysis import LabAnalysisCreate, LabAnalysisUpdate


def valid_payload(**overrides):
    values = {
        "parcel_id": uuid.uuid4(),
        "sample_code": "LAB-CAF-001",
        "sampled_at": datetime.now(timezone.utc) - timedelta(days=1),
        "depth_start_cm": 0,
        "depth_end_cm": 20,
        "lab": "Laboratorio regional",
        "ph": 5.2,
        "ph_method": "Potenciométrico 1:1",
        "ec": 0.5,
        "ec_method": "Extracto 1:2",
        "organic_matter_pct": 9.4,
        "cic": 18,
        "clay_pct": 30,
        "silt_pct": 30,
        "sand_pct": 40,
        "nitrogen": 4000,
        "phosphorus": 8,
        "phosphorus_method": "Bray II",
        "potassium": 70,
        "potassium_method": "Acetato de amonio",
        "calcium": 450,
        "magnesium": 80,
        "sulfur": 8,
    }
    values.update(overrides)
    return values


class LabAnalysisSchemaTests(unittest.TestCase):
    def test_accepts_complete_documented_analysis(self):
        payload = LabAnalysisCreate(**valid_payload())

        self.assertEqual(payload.sample_code, "LAB-CAF-001")
        self.assertEqual(payload.phosphorus_method, "Bray II")
        self.assertEqual(payload.clay_pct + payload.silt_pct + payload.sand_pct, 100)

    def test_rejects_invalid_depth_and_texture(self):
        with self.assertRaises(ValidationError):
            LabAnalysisCreate(
                **valid_payload(depth_start_cm=20, depth_end_cm=10)
            )

        with self.assertRaises(ValidationError):
            LabAnalysisCreate(**valid_payload(sand_pct=20))

    def test_rejects_future_sample_date_and_negative_nutrients(self):
        with self.assertRaises(ValidationError):
            LabAnalysisCreate(
                **valid_payload(
                    sampled_at=datetime.now(timezone.utc) + timedelta(days=1)
                )
            )

        with self.assertRaises(ValidationError):
            LabAnalysisCreate(**valid_payload(phosphorus=-1))

    def test_update_accepts_partial_payload(self):
        update = LabAnalysisUpdate(ph=5.4)

        self.assertEqual(update.model_dump(exclude_unset=True), {"ph": 5.4})


class LabAnalysisRouterTests(unittest.IsolatedAsyncioTestCase):
    def setUp(self):
        self.user_id = uuid.uuid4()
        self.user = SimpleNamespace(id=self.user_id, role="farmer")
        self.parcel = SimpleNamespace(
            id=uuid.uuid4(),
            farm=SimpleNamespace(user_id=self.user_id),
        )
        self.db = AsyncMock()

    async def test_create_associates_analysis_with_owned_parcel(self):
        payload = LabAnalysisCreate(
            **valid_payload(parcel_id=self.parcel.id)
        )

        with (
            patch.object(
                router.parcel_repo,
                "get_parcel",
                AsyncMock(return_value=self.parcel),
            ),
            patch.object(
                router.lab_repo,
                "create_lab_analysis",
                AsyncMock(side_effect=lambda _db, analysis: analysis),
            ) as create_mock,
        ):
            result = await router.create_lab_analysis(
                payload=payload,
                current_user=self.user,
                db=self.db,
            )

        self.assertEqual(result.parcel_id, self.parcel.id)
        create_mock.assert_awaited_once()

    async def test_create_rejects_parcel_owned_by_another_user(self):
        payload = LabAnalysisCreate(
            **valid_payload(parcel_id=self.parcel.id)
        )
        foreign_parcel = SimpleNamespace(
            id=self.parcel.id,
            farm=SimpleNamespace(user_id=uuid.uuid4()),
        )

        with patch.object(
            router.parcel_repo,
            "get_parcel",
            AsyncMock(return_value=foreign_parcel),
        ):
            with self.assertRaises(HTTPException) as raised:
                await router.create_lab_analysis(
                    payload=payload,
                    current_user=self.user,
                    db=self.db,
                )

        self.assertEqual(raised.exception.status_code, 403)

    async def test_list_and_get_return_only_owned_parcel_data(self):
        analysis = SimpleNamespace(
            id=uuid.uuid4(),
            parcel_id=self.parcel.id,
        )

        with (
            patch.object(
                router.parcel_repo,
                "get_parcel",
                AsyncMock(return_value=self.parcel),
            ),
            patch.object(
                router.lab_repo,
                "list_lab_analyses_by_parcel",
                AsyncMock(return_value=[analysis]),
            ),
            patch.object(
                router.lab_repo,
                "get_lab_analysis",
                AsyncMock(return_value=analysis),
            ),
        ):
            listed = await router.list_lab_analyses(
                parcel_id=self.parcel.id,
                skip=0,
                limit=100,
                current_user=self.user,
                db=self.db,
            )
            fetched = await router.get_lab_analysis(
                analysis_id=analysis.id,
                current_user=self.user,
                db=self.db,
            )

        self.assertEqual(listed, [analysis])
        self.assertIs(fetched, analysis)

    async def test_update_changes_an_owned_analysis(self):
        values = valid_payload(parcel_id=self.parcel.id)
        values.pop("parcel_id")
        analysis = LabAnalysis(parcel_id=self.parcel.id, **values)
        analysis.id = uuid.uuid4()

        with (
            patch.object(
                router.lab_repo,
                "get_lab_analysis",
                AsyncMock(return_value=analysis),
            ),
            patch.object(
                router.parcel_repo,
                "get_parcel",
                AsyncMock(return_value=self.parcel),
            ),
            patch.object(
                router.lab_repo,
                "update_lab_analysis",
                AsyncMock(side_effect=lambda _db, item: item),
            ) as update_mock,
        ):
            updated = await router.update_lab_analysis(
                analysis_id=analysis.id,
                payload=LabAnalysisUpdate(ph=5.4),
                current_user=self.user,
                db=self.db,
            )

        self.assertEqual(updated.ph, 5.4)
        update_mock.assert_awaited_once_with(self.db, analysis)

    async def test_update_validates_the_merged_texture(self):
        values = valid_payload(parcel_id=self.parcel.id)
        values.pop("parcel_id")
        analysis = LabAnalysis(parcel_id=self.parcel.id, **values)
        analysis.id = uuid.uuid4()

        with (
            patch.object(
                router.lab_repo,
                "get_lab_analysis",
                AsyncMock(return_value=analysis),
            ),
            patch.object(
                router.parcel_repo,
                "get_parcel",
                AsyncMock(return_value=self.parcel),
            ),
        ):
            with self.assertRaises(HTTPException) as raised:
                await router.update_lab_analysis(
                    analysis_id=analysis.id,
                    payload=LabAnalysisUpdate(clay_pct=50),
                    current_user=self.user,
                    db=self.db,
                )

        self.assertEqual(raised.exception.status_code, 422)

    async def test_delete_removes_an_owned_analysis(self):
        analysis = SimpleNamespace(
            id=uuid.uuid4(),
            parcel_id=self.parcel.id,
        )

        with (
            patch.object(
                router.lab_repo,
                "get_lab_analysis",
                AsyncMock(return_value=analysis),
            ),
            patch.object(
                router.parcel_repo,
                "get_parcel",
                AsyncMock(return_value=self.parcel),
            ),
            patch.object(
                router.lab_repo,
                "delete_lab_analysis",
                AsyncMock(),
            ) as delete_mock,
        ):
            await router.delete_lab_analysis(
                analysis_id=analysis.id,
                current_user=self.user,
                db=self.db,
            )

        delete_mock.assert_awaited_once_with(self.db, analysis)


if __name__ == "__main__":
    unittest.main()
