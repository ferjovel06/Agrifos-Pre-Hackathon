import uuid
from sqlalchemy import String, Float, Integer, Date, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import UUIDPKMixin, TimestampMixin


class Farm(Base, UUIDPKMixin, TimestampMixin):
    __tablename__ = "farms"

    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), nullable=False)
    name: Mapped[str] = mapped_column(String(150))
    area_hectares: Mapped[float] = mapped_column(Float)
    latitude: Mapped[float] = mapped_column(Float)
    longitude: Mapped[float] = mapped_column(Float)

    owner: Mapped["User"] = relationship(back_populates="farms")
    parcels: Mapped[list["Parcel"]] = relationship(back_populates="farm")
    alerts: Mapped[list["Alert"]] = relationship(back_populates="farm")
    expenses: Mapped[list["Expense"]] = relationship(back_populates="farm")
    incomes: Mapped[list["Income"]] = relationship(back_populates="farm")
    productions: Mapped[list["Production"]] = relationship(back_populates="farm")


class Parcel(Base, UUIDPKMixin, TimestampMixin):
    __tablename__ = "parcels"

    farm_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("farms.id"), nullable=False)
    crop_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("crops.id"), nullable=False)
    variety_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("varieties.id"), nullable=True
    )

    name: Mapped[str] = mapped_column(String(150))
    area_hectares: Mapped[float] = mapped_column(Float)
    plants_per_hectare: Mapped[int | None] = mapped_column(Integer, nullable=True)
    planting_date: Mapped[Date] = mapped_column(Date)

    farm: Mapped["Farm"] = relationship(back_populates="parcels")
    crop: Mapped["Crop"] = relationship(back_populates="parcels")
    variety: Mapped["Variety | None"] = relationship(back_populates="parcels")

    readings: Mapped[list["Reading"]] = relationship(back_populates="parcel")
    lab_analyses: Mapped[list["LabAnalysis"]] = relationship(back_populates="parcel")
    stage_instances: Mapped[list["ParcelPhenologicalStage"]] = relationship(
        back_populates="parcel"
    )
    fertilization_plans: Mapped[list["FertilizationPlan"]] = relationship(
        back_populates="parcel"
    )
    alerts: Mapped[list["Alert"]] = relationship(back_populates="parcel")
