import uuid
from typing import TypeVar

from sqlalchemy import Select, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Expense, Income


FinanceRecord = TypeVar("FinanceRecord", Income, Expense)


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
