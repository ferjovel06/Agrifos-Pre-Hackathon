import uuid
from datetime import date
from decimal import Decimal

from sqlalchemy import Date, Float, ForeignKey, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import UUIDPKMixin


class Expense(Base, UUIDPKMixin):
    __tablename__ = "expenses"

    farm_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("farms.id"), nullable=False)
    category: Mapped[str] = mapped_column(String(50))
    amount: Mapped[Decimal] = mapped_column(Numeric(12, 2))
    expense_date: Mapped[date] = mapped_column(Date)

    farm: Mapped["Farm"] = relationship(back_populates="expenses")


class Income(Base, UUIDPKMixin):
    __tablename__ = "incomes"

    farm_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("farms.id"), nullable=False)
    amount: Mapped[Decimal] = mapped_column(Numeric(12, 2))
    income_date: Mapped[date] = mapped_column(Date)

    farm: Mapped["Farm"] = relationship(back_populates="incomes")
    productions: Mapped[list["Production"]] = relationship(back_populates="income")


class Production(Base, UUIDPKMixin):
    __tablename__ = "productions"

    farm_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("farms.id"), nullable=False)
    income_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("incomes.id"), nullable=True
    )

    quantity: Mapped[float] = mapped_column(Float)
    unit: Mapped[str] = mapped_column(String(20))  # qq | ton
    harvest_date: Mapped[date] = mapped_column(Date)

    farm: Mapped["Farm"] = relationship(back_populates="productions")
    income: Mapped["Income | None"] = relationship(back_populates="productions")
