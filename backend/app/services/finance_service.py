import calendar
import uuid
from datetime import date, timedelta
from decimal import Decimal, ROUND_HALF_UP

from sqlalchemy.ext.asyncio import AsyncSession

from app.repositories import finance as finance_repo
from app.schemas.finance import FinanceDashboardRead


MONEY_PRECISION = Decimal("0.01")
PERCENTAGE_PRECISION = Decimal("0.01")


def _round_money(value: Decimal) -> Decimal:
    return value.quantize(MONEY_PRECISION, rounding=ROUND_HALF_UP)


def _round_percentage(value: Decimal) -> Decimal:
    return value.quantize(PERCENTAGE_PRECISION, rounding=ROUND_HALF_UP)


def _margin(income: Decimal, expenses: Decimal) -> Decimal | None:
    if income == 0:
        return None
    return _round_percentage(((income - expenses) / income) * 100)


def _percentage_change(current: Decimal, previous: Decimal) -> Decimal | None:
    if previous == 0:
        return None
    return _round_percentage(((current - previous) / abs(previous)) * 100)


def _comparison_period(as_of: date) -> tuple[date, date]:
    previous_month_end = as_of.replace(day=1) - timedelta(days=1)
    previous_month_start = previous_month_end.replace(day=1)
    comparable_day = min(as_of.day, previous_month_end.day)
    return previous_month_start, previous_month_end.replace(day=comparable_day)


async def get_dashboard(
    db: AsyncSession,
    farm_id: uuid.UUID,
    as_of: date,
) -> FinanceDashboardRead:
    period_start = as_of.replace(day=1)
    previous_start, previous_end = _comparison_period(as_of)
    year_start = as_of.replace(month=1, day=1)

    totals = await finance_repo.get_dashboard_totals(
        db,
        farm_id,
        period_start,
        as_of,
        previous_start,
        previous_end,
        year_start,
    )

    operating_balance = totals.current_income - totals.current_expenses
    previous_balance = totals.previous_income - totals.previous_expenses
    current_margin = _margin(totals.current_income, totals.current_expenses)
    previous_margin = _margin(totals.previous_income, totals.previous_expenses)
    elapsed_days = (as_of - year_start).days + 1
    days_in_year = 366 if calendar.isleap(as_of.year) else 365
    projected_annual_income = (
        totals.year_to_date_income * days_in_year / elapsed_days
    )

    return FinanceDashboardRead(
        farm_id=farm_id,
        period_start=period_start,
        period_end=as_of,
        gross_income=_round_money(totals.current_income),
        total_expenses=_round_money(totals.current_expenses),
        operating_balance=_round_money(operating_balance),
        net_margin_percentage=current_margin,
        balance_change_percentage=_percentage_change(
            operating_balance, previous_balance
        ),
        net_margin_change_percentage_points=(
            None
            if current_margin is None or previous_margin is None
            else _round_percentage(current_margin - previous_margin)
        ),
        projected_annual_income=_round_money(projected_annual_income),
    )
