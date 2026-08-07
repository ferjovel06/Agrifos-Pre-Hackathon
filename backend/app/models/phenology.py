import uuid
from datetime import date
from sqlalchemy import String, Integer, Date, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import UUIDPKMixin


class PhenologicalStage(Base, UUIDPKMixin):
    """
    Catalog + instances of phenological stages for crops and parcels.
    """
    __tablename__ = "phenological_stages"

    template_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("phenological_stages.id"), nullable=True
    )
    crop_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("crops.id"), nullable=True
    )
    parcel_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("parcels.id"), nullable=True
    )

    name: Mapped[str] = mapped_column(String(100))
    stage_order: Mapped[int] = mapped_column(Integer)
    duration_days: Mapped[int | None] = mapped_column(Integer, nullable=True)
    estimated_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    actual_date: Mapped[date | None] = mapped_column(Date, nullable=True)

    # relación recursiva
    template: Mapped["PhenologicalStage | None"] = relationship(
        remote_side="PhenologicalStage.id", back_populates="instances"
    )
    instances: Mapped[list["PhenologicalStage"]] = relationship(
        back_populates="template"
    )

    crop: Mapped["Crop | None"] = relationship(
        back_populates="stage_templates", foreign_keys=[crop_id]
    )
    parcel: Mapped["Parcel | None"] = relationship(
        back_populates="stage_instances", foreign_keys=[parcel_id]
    )

    optimal_requirements: Mapped[list["OptimalRequirement"]] = relationship(
        back_populates="stage"
    )
    factors: Mapped[list["StageFactor"]] = relationship(back_populates="stage")