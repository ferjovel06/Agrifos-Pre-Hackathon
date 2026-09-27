import uuid
from datetime import date
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator


Amount = Decimal


class IncomeValues(BaseModel):
    amount: Amount = Field(gt=0, max_digits=12, decimal_places=2)
    income_date: date


class IncomeCreate(IncomeValues):
    farm_id: uuid.UUID


class IncomeUpdate(BaseModel):
    amount: Amount | None = Field(
        default=None,
        gt=0,
        max_digits=12,
        decimal_places=2,
    )
    income_date: date | None = None

    @model_validator(mode="before")
    @classmethod
    def require_non_null_update(cls, value):
        return _validate_update(value)


class IncomeRead(IncomeValues):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    farm_id: uuid.UUID


class ExpenseValues(BaseModel):
    category: str = Field(min_length=1, max_length=50)
    amount: Amount = Field(gt=0, max_digits=12, decimal_places=2)
    expense_date: date

    @field_validator("category")
    @classmethod
    def normalize_category(cls, value: str) -> str:
        normalized = " ".join(value.split())
        if not normalized:
            raise ValueError("category cannot be blank.")
        return normalized


class ExpenseCreate(ExpenseValues):
    farm_id: uuid.UUID


class ExpenseUpdate(BaseModel):
    category: str | None = Field(default=None, min_length=1, max_length=50)
    amount: Amount | None = Field(
        default=None,
        gt=0,
        max_digits=12,
        decimal_places=2,
    )
    expense_date: date | None = None

    @model_validator(mode="before")
    @classmethod
    def require_non_null_update(cls, value):
        return _validate_update(value)

    @field_validator("category")
    @classmethod
    def normalize_category(cls, value: str | None) -> str | None:
        if value is None:
            return value
        normalized = " ".join(value.split())
        if not normalized:
            raise ValueError("category cannot be blank.")
        return normalized


class ExpenseRead(ExpenseValues):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    farm_id: uuid.UUID


def _validate_update(value):
    if not isinstance(value, dict) or not value:
        raise ValueError("At least one field must be provided.")
    if any(field_value is None for field_value in value.values()):
        raise ValueError("Finance fields cannot be null.")
    return value
