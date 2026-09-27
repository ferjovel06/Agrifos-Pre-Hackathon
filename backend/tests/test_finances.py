import unittest
import uuid
from datetime import date
from decimal import Decimal
from types import SimpleNamespace
from unittest.mock import AsyncMock, patch

from fastapi import HTTPException
from pydantic import ValidationError

from app.models import Expense, Income
from app.routers import finances as router
from app.schemas.finance import (
    ExpenseCreate,
    ExpenseUpdate,
    IncomeCreate,
    IncomeUpdate,
)


class FinanceSchemaTests(unittest.TestCase):
    def test_amount_must_be_positive(self):
        with self.assertRaises(ValidationError):
            IncomeCreate(
                farm_id=uuid.uuid4(),
                amount=Decimal("0"),
                income_date=date.today(),
            )

    def test_expense_category_is_normalized(self):
        payload = ExpenseCreate(
            farm_id=uuid.uuid4(),
            category="  Mano   de obra  ",
            amount=Decimal("125.50"),
            expense_date=date.today(),
        )

        self.assertEqual(payload.category, "Mano de obra")

    def test_blank_expense_category_is_rejected_on_update(self):
        with self.assertRaises(ValidationError):
            ExpenseUpdate(category="   ")

    def test_empty_or_null_updates_are_rejected(self):
        with self.assertRaises(ValidationError):
            IncomeUpdate()
        with self.assertRaises(ValidationError):
            IncomeUpdate(amount=None)


class FinanceRouterTests(unittest.IsolatedAsyncioTestCase):
    def setUp(self):
        self.user = SimpleNamespace(id=uuid.uuid4(), role="farmer")
        self.farm = SimpleNamespace(id=uuid.uuid4(), user_id=self.user.id)
        self.db = AsyncMock()

    async def test_create_income_for_owned_farm(self):
        payload = IncomeCreate(
            farm_id=self.farm.id,
            amount=Decimal("850.25"),
            income_date=date(2026, 9, 27),
        )

        with (
            patch.object(
                router.farm_repo,
                "get_farm",
                AsyncMock(return_value=self.farm),
            ),
            patch.object(
                router.finance_repo,
                "create_income",
                AsyncMock(side_effect=lambda _db, income: income),
            ),
        ):
            result = await router.create_income(
                payload=payload,
                current_user=self.user,
                db=self.db,
            )

        self.assertIsInstance(result, Income)
        self.assertEqual(result.farm_id, self.farm.id)
        self.assertEqual(result.amount, Decimal("850.25"))

    async def test_foreign_farm_is_rejected(self):
        foreign_farm = SimpleNamespace(id=uuid.uuid4(), user_id=uuid.uuid4())

        with patch.object(
            router.farm_repo,
            "get_farm",
            AsyncMock(return_value=foreign_farm),
        ):
            with self.assertRaises(HTTPException) as raised:
                await router.list_expenses(
                    farm_id=foreign_farm.id,
                    skip=0,
                    limit=100,
                    current_user=self.user,
                    db=self.db,
                )

        self.assertEqual(raised.exception.status_code, 403)

    async def test_list_expenses_for_owned_farm(self):
        expense = Expense(
            farm_id=self.farm.id,
            category="Insumos",
            amount=Decimal("42.00"),
            expense_date=date(2026, 9, 26),
        )

        with (
            patch.object(
                router.farm_repo,
                "get_farm",
                AsyncMock(return_value=self.farm),
            ),
            patch.object(
                router.finance_repo,
                "list_expenses_by_farm",
                AsyncMock(return_value=[expense]),
            ) as list_mock,
        ):
            result = await router.list_expenses(
                farm_id=self.farm.id,
                skip=10,
                limit=20,
                current_user=self.user,
                db=self.db,
            )

        self.assertEqual(result, [expense])
        list_mock.assert_awaited_once_with(self.db, self.farm.id, 10, 20)

    async def test_update_expense_preserves_farm_scope(self):
        expense = Expense(
            farm_id=self.farm.id,
            category="Transporte",
            amount=Decimal("50.00"),
            expense_date=date(2026, 9, 25),
        )
        expense.id = uuid.uuid4()
        payload = ExpenseUpdate(amount=Decimal("75.25"))

        with (
            patch.object(
                router.finance_repo,
                "get_expense",
                AsyncMock(return_value=expense),
            ),
            patch.object(
                router.farm_repo,
                "get_farm",
                AsyncMock(return_value=self.farm),
            ),
            patch.object(
                router.finance_repo,
                "update_record",
                AsyncMock(side_effect=lambda _db, record: record),
            ),
        ):
            result = await router.update_expense(
                expense_id=expense.id,
                payload=payload,
                current_user=self.user,
                db=self.db,
            )

        self.assertEqual(result.amount, Decimal("75.25"))
        self.assertEqual(result.category, "Transporte")

    async def test_delete_missing_income_returns_not_found(self):
        with patch.object(
            router.finance_repo,
            "get_income",
            AsyncMock(return_value=None),
        ):
            with self.assertRaises(HTTPException) as raised:
                await router.delete_income(
                    income_id=uuid.uuid4(),
                    current_user=self.user,
                    db=self.db,
                )

        self.assertEqual(raised.exception.status_code, 404)


if __name__ == "__main__":
    unittest.main()
