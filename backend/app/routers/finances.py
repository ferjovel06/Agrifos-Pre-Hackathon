import uuid
from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import (
    get_current_user,
    has_global_read_access,
    require_write_access,
)
from app.db.session import get_db
from app.models import Expense, Farm, Income, User
from app.repositories import farm as farm_repo
from app.repositories import finance as finance_repo
from app.schemas.finance import (
    ExpenseCreate,
    ExpenseRead,
    ExpenseUpdate,
    FinanceDashboardRead,
    IncomeCreate,
    IncomeRead,
    IncomeUpdate,
)
from app.services import finance_service


router = APIRouter(prefix="/finances", tags=["finances"])


async def _get_authorized_farm(
    db: AsyncSession,
    farm_id: uuid.UUID,
    user: User,
) -> Farm:
    farm = await farm_repo.get_farm(db, farm_id)
    if not farm:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Farm not found.",
        )
    if not has_global_read_access(user) and farm.user_id != user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions.",
        )
    return farm


async def _get_authorized_income(
    db: AsyncSession,
    income_id: uuid.UUID,
    user: User,
) -> Income:
    income = await finance_repo.get_income(db, income_id)
    if not income:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Income not found.",
        )
    await _get_authorized_farm(db, income.farm_id, user)
    return income


async def _get_authorized_expense(
    db: AsyncSession,
    expense_id: uuid.UUID,
    user: User,
) -> Expense:
    expense = await finance_repo.get_expense(db, expense_id)
    if not expense:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Expense not found.",
        )
    await _get_authorized_farm(db, expense.farm_id, user)
    return expense


@router.get("/dashboard", response_model=FinanceDashboardRead)
async def get_dashboard(
    farm_id: uuid.UUID = Query(..., description="Farm to query"),
    as_of: date = Query(
        default_factory=date.today,
        description="Last date included in the current-month metrics",
    ),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _get_authorized_farm(db, farm_id, current_user)
    return await finance_service.get_dashboard(db, farm_id, as_of)


@router.post(
    "/incomes",
    response_model=IncomeRead,
    status_code=status.HTTP_201_CREATED,
)
async def create_income(
    payload: IncomeCreate,
    current_user: User = Depends(require_write_access),
    db: AsyncSession = Depends(get_db),
):
    await _get_authorized_farm(db, payload.farm_id, current_user)
    return await finance_repo.create_income(db, Income(**payload.model_dump()))


@router.get("/incomes", response_model=list[IncomeRead])
async def list_incomes(
    farm_id: uuid.UUID = Query(..., description="Farm to query"),
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=100, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _get_authorized_farm(db, farm_id, current_user)
    return await finance_repo.list_incomes_by_farm(db, farm_id, skip, limit)


@router.get("/incomes/{income_id}", response_model=IncomeRead)
async def get_income(
    income_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await _get_authorized_income(db, income_id, current_user)


@router.patch("/incomes/{income_id}", response_model=IncomeRead)
async def update_income(
    income_id: uuid.UUID,
    payload: IncomeUpdate,
    current_user: User = Depends(require_write_access),
    db: AsyncSession = Depends(get_db),
):
    income = await _get_authorized_income(db, income_id, current_user)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(income, field, value)
    return await finance_repo.update_record(db, income)


@router.delete("/incomes/{income_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_income(
    income_id: uuid.UUID,
    current_user: User = Depends(require_write_access),
    db: AsyncSession = Depends(get_db),
):
    income = await _get_authorized_income(db, income_id, current_user)
    await finance_repo.delete_record(db, income)


@router.post(
    "/expenses",
    response_model=ExpenseRead,
    status_code=status.HTTP_201_CREATED,
)
async def create_expense(
    payload: ExpenseCreate,
    current_user: User = Depends(require_write_access),
    db: AsyncSession = Depends(get_db),
):
    await _get_authorized_farm(db, payload.farm_id, current_user)
    return await finance_repo.create_expense(db, Expense(**payload.model_dump()))


@router.get("/expenses", response_model=list[ExpenseRead])
async def list_expenses(
    farm_id: uuid.UUID = Query(..., description="Farm to query"),
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=100, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _get_authorized_farm(db, farm_id, current_user)
    return await finance_repo.list_expenses_by_farm(db, farm_id, skip, limit)


@router.get("/expenses/{expense_id}", response_model=ExpenseRead)
async def get_expense(
    expense_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await _get_authorized_expense(db, expense_id, current_user)


@router.patch("/expenses/{expense_id}", response_model=ExpenseRead)
async def update_expense(
    expense_id: uuid.UUID,
    payload: ExpenseUpdate,
    current_user: User = Depends(require_write_access),
    db: AsyncSession = Depends(get_db),
):
    expense = await _get_authorized_expense(db, expense_id, current_user)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(expense, field, value)
    return await finance_repo.update_record(db, expense)


@router.delete("/expenses/{expense_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_expense(
    expense_id: uuid.UUID,
    current_user: User = Depends(require_write_access),
    db: AsyncSession = Depends(get_db),
):
    expense = await _get_authorized_expense(db, expense_id, current_user)
    await finance_repo.delete_record(db, expense)
