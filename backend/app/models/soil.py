import uuid
from datetime import datetime
from sqlalchemy import Float, String, DateTime, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import UUIDPKMixin


class Reading(Base, UUIDPKMixin):
    """NPK readings from sensors."""
    __tablename__ = "readings"

    parcel_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("parcels.id"), nullable=False)

    nitrogen: Mapped[float] = mapped_column(Float)
    phosphorus: Mapped[float] = mapped_column(Float)
    potassium: Mapped[float] = mapped_column(Float)
    ec: Mapped[float] = mapped_column(Float)
    ph: Mapped[float] = mapped_column(Float)
    temperature: Mapped[float] = mapped_column(Float)
    humidity: Mapped[float] = mapped_column(Float)

    recorded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    parcel: Mapped["Parcel"] = relationship(back_populates="readings")
    fertilization_plans: Mapped[list["FertilizationPlan"]] = relationship(
        back_populates="reading"
    )


class LabAnalysis(Base, UUIDPKMixin):
    """Lab analysis of soil samples."""
    __tablename__ = "lab_analyses"

    parcel_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("parcels.id"), nullable=False)

    ph: Mapped[float] = mapped_column(Float)
    organic_matter_pct: Mapped[float] = mapped_column(Float)
    cic: Mapped[float] = mapped_column(Float)
    clay_pct: Mapped[float] = mapped_column(Float)
    silt_pct: Mapped[float] = mapped_column(Float)
    sand_pct: Mapped[float] = mapped_column(Float)
    nitrogen: Mapped[float] = mapped_column(Float)
    phosphorus: Mapped[float] = mapped_column(Float)
    potassium: Mapped[float] = mapped_column(Float)
    calcium: Mapped[float] = mapped_column(Float)
    magnesium: Mapped[float] = mapped_column(Float)
    sulfur: Mapped[float] = mapped_column(Float)
    lab: Mapped[str] = mapped_column(String(150))

    recorded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    parcel: Mapped["Parcel"] = relationship(back_populates="lab_analyses")
    fertilization_plans: Mapped[list["FertilizationPlan"]] = relationship(
        back_populates="lab_analysis"
    )