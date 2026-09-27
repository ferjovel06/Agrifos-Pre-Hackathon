import inspect
import unittest
import uuid
from types import SimpleNamespace
from unittest.mock import AsyncMock, patch

from fastapi import HTTPException

from app.core.auth import (
    get_current_user,
    has_global_read_access,
    require_write_access,
)
from app.routers import (
    alerts,
    diagnostic,
    farms,
    finances,
    fertilization,
    lab_analysis,
    parcels,
    phenology,
    readings,
    weather,
)
from app.schemas.user import UserRole, UserUpdate


class AuditorPolicyTests(unittest.IsolatedAsyncioTestCase):
    def setUp(self):
        self.auditor = SimpleNamespace(id=uuid.uuid4(), role="auditor")

    def test_auditor_is_a_valid_assignable_role(self):
        update = UserUpdate(role="auditor")

        self.assertEqual(update.role, UserRole.auditor)

    def test_auditor_has_global_read_access(self):
        farmer = SimpleNamespace(role="farmer")
        admin = SimpleNamespace(role="admin")

        self.assertTrue(has_global_read_access(self.auditor))
        self.assertTrue(has_global_read_access(admin))
        self.assertFalse(has_global_read_access(farmer))

    async def test_auditor_is_rejected_by_write_policy(self):
        with self.assertRaises(HTTPException) as raised:
            await require_write_access(self.auditor)

        self.assertEqual(raised.exception.status_code, 403)
        self.assertEqual(raised.exception.detail, "This role has read-only access.")

    async def test_farmer_and_admin_keep_write_access(self):
        farmer = SimpleNamespace(role="farmer")
        admin = SimpleNamespace(role="admin")

        self.assertIs(await require_write_access(farmer), farmer)
        self.assertIs(await require_write_access(admin), admin)

    async def test_auditor_can_read_a_farm_owned_by_another_user(self):
        farm = SimpleNamespace(id=uuid.uuid4(), user_id=uuid.uuid4())

        with patch.object(
            farms.farm_repo,
            "get_farm",
            AsyncMock(return_value=farm),
        ):
            result = await farms.get_farm(
                farm_id=farm.id,
                current_user=self.auditor,
                db=AsyncMock(),
            )

        self.assertIs(result, farm)

    def test_domain_mutations_require_write_access(self):
        endpoints = (
            farms.create_farm,
            farms.update_farm,
            farms.delete_farm,
            finances.create_income,
            finances.update_income,
            finances.delete_income,
            finances.create_expense,
            finances.update_expense,
            finances.delete_expense,
            parcels.create_parcel,
            parcels.update_parcel,
            parcels.update_parcel_configuration,
            parcels.delete_parcel,
            readings.create_reading,
            lab_analysis.create_lab_analysis,
            lab_analysis.update_lab_analysis,
            lab_analysis.delete_lab_analysis,
            phenology.create_instance,
            phenology.update_instance,
            phenology.delete_instance,
            alerts.evaluate_farm_alerts,
            fertilization.create_recommendation,
        )

        for endpoint in endpoints:
            with self.subTest(endpoint=endpoint.__name__):
                dependency = inspect.signature(endpoint).parameters[
                    "current_user"
                ].default
                self.assertIs(dependency.dependency, require_write_access)

    def test_auditor_read_endpoints_keep_standard_authentication(self):
        endpoints = (
            farms.list_farms,
            farms.get_farm,
            finances.list_incomes,
            finances.get_income,
            finances.list_expenses,
            finances.get_expense,
            parcels.list_parcels,
            parcels.get_parcel,
            readings.list_readings,
            readings.get_reading,
            lab_analysis.list_lab_analyses,
            lab_analysis.get_lab_analysis,
            phenology.list_instances,
            phenology.get_instance,
            alerts.list_farm_alerts,
            diagnostic.diagnose_reading,
            weather.get_farm_forecast,
        )

        for endpoint in endpoints:
            with self.subTest(endpoint=endpoint.__name__):
                dependency = inspect.signature(endpoint).parameters[
                    "current_user"
                ].default
                self.assertIs(dependency.dependency, get_current_user)


if __name__ == "__main__":
    unittest.main()
