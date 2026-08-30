import uuid
from datetime import datetime
from sqlalchemy import String, DateTime, ForeignKey, CheckConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import UUIDPKMixin


class FertilizationPlan(Base, UUIDPKMixin):
    __tablename__ = "fertilization_plans"
    __table_args__ = (
        CheckConstraint(
            "NOT (reading_id IS NOT NULL AND lab_analysis_id IS NOT NULL)",
            name="ck_fertilization_plan_single_source",
        ),
    )

    parcel_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("parcels.id"), nullable=False)
    reading_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("readings.id"), nullable=True
    )
    lab_analysis_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("lab_analyses.id"), nullable=True
    )

    method: Mapped[str] = mapped_column(String(20))  # sensor | lab | manual
    generated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    parcel: Mapped["Parcel"] = relationship(back_populates="fertilization_plans")
    reading: Mapped["Reading | None"] = relationship(
        back_populates="fertilization_plans"
    )
    lab_analysis: Mapped["LabAnalysis | None"] = relationship(
        back_populates="fertilization_plans"
    )