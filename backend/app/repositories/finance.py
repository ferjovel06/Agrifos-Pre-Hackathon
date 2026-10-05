import uuid
from dataclasses import dataclass
from datetime import date
from decimal import Decimal
from typing import TypeVar

from sqlalchemy import Numeric, Select, func, literal, select, union_all
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


@dataclass(frozen=True)
class MonthlyFinanceTotals:
    year: int
    month: int
    income: Decimal
    expenses: Decimal


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


async def get_monthly_totals(
    db: AsyncSession,
    farm_id: uuid.UUID,
    start: date,
    end: date,
) -> list[MonthlyFinanceTotals]:
    zero = literal(Decimal("0.00")).cast(Numeric(12, 2))
    income_totals = select(
        func.extract("year", Income.income_date).label("year"),
        func.extract("month", Income.income_date).label("month"),
        func.sum(Income.amount).label("income"),
        zero.label("expenses"),
    ).where(
        Income.farm_id == farm_id,
        Income.income_date >= start,
        Income.income_date <= end,
    ).group_by("year", "month")
    expense_totals = select(
        func.extract("year", Expense.expense_date).label("year"),
        func.extract("month", Expense.expense_date).label("month"),
        zero.label("income"),
        func.sum(Expense.amount).label("expenses"),
    ).where(
        Expense.farm_id == farm_id,
        Expense.expense_date >= start,
        Expense.expense_date <= end,
    ).group_by("year", "month")
    combined = union_all(income_totals, expense_totals).subquery()
    statement = (
        select(
            combined.c.year,
            combined.c.month,
            func.sum(combined.c.income).label("income"),
            func.sum(combined.c.expenses).label("expenses"),
        )
        .group_by(combined.c.year, combined.c.month)
        .order_by(combined.c.year, combined.c.month)
    )
    rows = (await db.execute(statement)).all()
    return [
        MonthlyFinanceTotals(
            year=int(row.year),
            month=int(row.month),
            income=row.income,
            expenses=row.expenses,
        )
        for row in rows
    ]


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
