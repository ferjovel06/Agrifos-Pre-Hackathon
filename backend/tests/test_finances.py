import unittest
import uuid
from datetime import date
from decimal import Decimal
from types import SimpleNamespace
from unittest.mock import AsyncMock, patch

from fastapi import HTTPException
from pydantic import ValidationError

from app.models import Expense, Income
from app.repositories.finance import FinanceDashboardTotals, MonthlyFinanceTotals
from app.routers import finances as router
from app.schemas.finance import (
    ExpenseCreate,
    ExpenseUpdate,
    IncomeCreate,
    IncomeUpdate,
)
from app.services import finance_service


class FinanceSchemaTests(unittest.TestCase):
    def test_amount_must_be_positive(self):
        with self.assertRaises(ValidationError):
            IncomeCreate(
                farm_id=uuid.uuid4(),
                category="Venta de café",
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

    def test_income_category_is_normalized(self):
        payload = IncomeCreate(
            farm_id=uuid.uuid4(),
            category="  Venta   de café  ",
            amount=Decimal("1250.00"),
            income_date=date.today(),
        )

        self.assertEqual(payload.category, "Venta de café")

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
            category="Venta de café",
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
        self.assertEqual(result.category, "Venta de café")

    async def test_dashboard_is_scoped_to_owned_farm(self):
        expected = object()

        with (
            patch.object(
                router.farm_repo,
                "get_farm",
                AsyncMock(return_value=self.farm),
            ),
            patch.object(
                router.finance_service,
                "get_dashboard",
                AsyncMock(return_value=expected),
            ) as dashboard_mock,
        ):
            result = await router.get_dashboard(
                farm_id=self.farm.id,
                as_of=date(2026, 9, 28),
                months=6,
                current_user=self.user,
                db=self.db,
            )

        self.assertIs(result, expected)
        dashboard_mock.assert_awaited_once_with(
            self.db, self.farm.id, date(2026, 9, 28), 6
        )

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


class FinanceDashboardServiceTests(unittest.IsolatedAsyncioTestCase):
    async def test_calculates_dashboard_metrics_and_comparable_period(self):
        farm_id = uuid.uuid4()
        db = AsyncMock()
        totals = FinanceDashboardTotals(
            current_income=Decimal("1000.00"),
            current_expenses=Decimal("600.00"),
            previous_income=Decimal("800.00"),
            previous_expenses=Decimal("500.00"),
            year_to_date_income=Decimal("7400.00"),
        )

        monthly_totals = [
            MonthlyFinanceTotals(
                year=2025,
                month=12,
                income=Decimal("1200.00"),
                expenses=Decimal("700.00"),
            ),
            MonthlyFinanceTotals(
                year=2026,
                month=3,
                income=Decimal("1000.00"),
                expenses=Decimal("600.00"),
            ),
        ]

        with (
            patch.object(
                finance_service.finance_repo,
                "get_dashboard_totals",
                AsyncMock(return_value=totals),
            ) as totals_mock,
            patch.object(
                finance_service.finance_repo,
                "get_monthly_totals",
                AsyncMock(return_value=monthly_totals),
            ) as monthly_mock,
        ):
            result = await finance_service.get_dashboard(
                db, farm_id, date(2026, 3, 15)
            )

        totals_mock.assert_awaited_once_with(
            db,
            farm_id,
            date(2026, 3, 1),
            date(2026, 3, 15),
            date(2026, 2, 1),
            date(2026, 2, 15),
            date(2026, 1, 1),
        )
        monthly_mock.assert_awaited_once_with(
            db,
            farm_id,
            date(2025, 10, 1),
            date(2026, 3, 15),
        )
        self.assertEqual(result.gross_income, Decimal("1000.00"))
        self.assertEqual(result.total_expenses, Decimal("600.00"))
        self.assertEqual(result.operating_balance, Decimal("400.00"))
        self.assertEqual(result.net_margin_percentage, Decimal("40.00"))
        self.assertEqual(
            result.balance_change_percentage, Decimal("33.33")
        )
        self.assertEqual(
            result.net_margin_change_percentage_points, Decimal("2.50")
        )
        self.assertEqual(
            result.projected_annual_income, Decimal("36500.00")
        )
        self.assertEqual(
            [point.month for point in result.cash_flow],
            [
                date(2025, 10, 1),
                date(2025, 11, 1),
                date(2025, 12, 1),
                date(2026, 1, 1),
                date(2026, 2, 1),
                date(2026, 3, 1),
            ],
        )
        self.assertEqual(result.cash_flow[0].income, Decimal("0.00"))
        self.assertEqual(result.cash_flow[2].income, Decimal("1200.00"))
        self.assertEqual(result.cash_flow[5].expenses, Decimal("600.00"))

    async def test_undefined_percentages_are_null(self):
        totals = FinanceDashboardTotals(
            current_income=Decimal("0.00"),
            current_expenses=Decimal("100.00"),
            previous_income=Decimal("0.00"),
            previous_expenses=Decimal("0.00"),
            year_to_date_income=Decimal("0.00"),
        )

        with (
            patch.object(
                finance_service.finance_repo,
                "get_dashboard_totals",
                AsyncMock(return_value=totals),
            ),
            patch.object(
                finance_service.finance_repo,
                "get_monthly_totals",
                AsyncMock(return_value=[]),
            ),
        ):
            result = await finance_service.get_dashboard(
                AsyncMock(), uuid.uuid4(), date(2026, 1, 31)
            )

        self.assertIsNone(result.net_margin_percentage)
        self.assertIsNone(result.balance_change_percentage)
        self.assertIsNone(result.net_margin_change_percentage_points)
        self.assertEqual(result.projected_annual_income, Decimal("0.00"))
        self.assertEqual(len(result.cash_flow), 6)
        self.assertTrue(
            all(
                point.income == 0 and point.expenses == 0
                for point in result.cash_flow
            )
        )


if __name__ == "__main__":
    unittest.main()
