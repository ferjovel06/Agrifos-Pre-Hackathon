import uuid
from dataclasses import dataclass
from datetime import date
from decimal import Decimal
from typing import TypeVar

from sqlalchemy import Select, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import InstrumentedAttribute

from app.models import Expense, Income


FinanceRecord = TypeVar("FinanceRecord", Income, Expense)


@dataclass(frozen=True)
class FinanceDashboardTotals:
    current_income: Decimal
    current_expenses: Decimal
    previous_income: Decimal
    previous_expenses: Decimal
    year_to_date_income: Decimal


async def _create(
    db: AsyncSession,
    record: FinanceRecord,
) -> FinanceRecord:
    db.add(record)
    await db.commit()
    await db.refresh(record)
    return record


async def _get(
    db: AsyncSession,
    statement: Select[tuple[FinanceRecord]],
) -> FinanceRecord | None:
    result = await db.execute(statement)
    return result.scalar_one_or_none()


async def _list(
    db: AsyncSession,
    statement: Select[tuple[FinanceRecord]],
) -> list[FinanceRecord]:
    result = await db.execute(statement)
    return list(result.scalars().all())


async def create_income(db: AsyncSession, income: Income) -> Income:
    return await _create(db, income)


async def get_income(db: AsyncSession, income_id: uuid.UUID) -> Income | None:
    return await _get(db, select(Income).where(Income.id == income_id))


async def list_incomes_by_farm(
    db: AsyncSession,
    farm_id: uuid.UUID,
    skip: int = 0,
    limit: int = 100,
) -> list[Income]:
    return await _list(
        db,
        select(Income)
        .where(Income.farm_id == farm_id)
        .order_by(Income.income_date.desc(), Income.id.desc())
        .offset(skip)
        .limit(limit),
    )


async def create_expense(db: AsyncSession, expense: Expense) -> Expense:
    return await _create(db, expense)


async def get_expense(db: AsyncSession, expense_id: uuid.UUID) -> Expense | None:
    return await _get(db, select(Expense).where(Expense.id == expense_id))


async def list_expenses_by_farm(
    db: AsyncSession,
    farm_id: uuid.UUID,
    skip: int = 0,
    limit: int = 100,
) -> list[Expense]:
    return await _list(
        db,
        select(Expense)
        .where(Expense.farm_id == farm_id)
        .order_by(Expense.expense_date.desc(), Expense.id.desc())
        .offset(skip)
        .limit(limit),
    )


def _total_for_period(
    model: type[Income] | type[Expense],
    date_column: InstrumentedAttribute,
    farm_id: uuid.UUID,
    start: date,
    end: date,
):
    return (
        select(func.coalesce(func.sum(model.amount), Decimal("0.00")))
        .where(
            model.farm_id == farm_id,
            date_column >= start,
            date_column <= end,
        )
        .scalar_subquery()
    )


async def get_dashboard_totals(
    db: AsyncSession,
    farm_id: uuid.UUID,
    current_start: date,
    current_end: date,
    previous_start: date,
    previous_end: date,
    year_start: date,
) -> FinanceDashboardTotals:
    statement = select(
        _total_for_period(
            Income, Income.income_date, farm_id, current_start, current_end
        ).label("current_income"),
        _total_for_period(
            Expense, Expense.expense_date, farm_id, current_start, current_end
        ).label("current_expenses"),
        _total_for_period(
            Income, Income.income_date, farm_id, previous_start, previous_end
        ).label("previous_income"),
        _total_for_period(
            Expense, Expense.expense_date, farm_id, previous_start, previous_end
        ).label("previous_expenses"),
        _total_for_period(
            Income, Income.income_date, farm_id, year_start, current_end
        ).label("year_to_date_income"),
    )
    row = (await db.execute(statement)).one()
    return FinanceDashboardTotals(**row._mapping)


async def update_record(
    db: AsyncSession,
    record: FinanceRecord,
) -> FinanceRecord:
    await db.commit()
    await db.refresh(record)
    return record


async def delete_record(db: AsyncSession, record: Income | Expense) -> None:
    await db.delete(record)
    await db.commit()
