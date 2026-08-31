import uuid
from datetime import date

from sqlalchemy import Date, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import UUIDPKMixin


class PhenologicalStageTemplate(Base, UUIDPKMixin):
    """Standard stage in the lifecycle defined for a crop."""

    __tablename__ = "phenological_stage_templates"
    __table_args__ = (
        UniqueConstraint(
            "crop_id",
            "stage_order",
            name="uq_stage_template_crop_order",
        ),
    )

    crop_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("crops.id", ondelete="CASCADE"), nullable=False
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    stage_order: Mapped[int] = mapped_column(Integer, nullable=False)
    duration_days: Mapped[int | None] = mapped_column(Integer, nullable=True)

    crop: Mapped["Crop"] = relationship(back_populates="stage_templates")
    parcel_stages: Mapped[list["ParcelPhenologicalStage"]] = relationship(
        back_populates="template"
    )
    optimal_requirements: Mapped[list["OptimalRequirement"]] = relationship(
        back_populates="stage"
    )
    factors: Mapped[list["StageFactor"]] = relationship(back_populates="stage")


class ParcelPhenologicalStage(Base, UUIDPKMixin):
    """Scheduled or observed occurrence of a stage for one parcel."""

    __tablename__ = "parcel_phenological_stages"
    __table_args__ = (
        UniqueConstraint(
            "parcel_id",
            "template_id",
            name="uq_parcel_phenological_stage_template",
        ),
    )

    parcel_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("parcels.id", ondelete="CASCADE"), nullable=False
    )
    template_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("phenological_stage_templates.id", ondelete="RESTRICT"),
        nullable=False,
    )
    estimated_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    actual_date: Mapped[date | None] = mapped_column(Date, nullable=True)

    parcel: Mapped["Parcel"] = relationship(back_populates="stage_instances")
    template: Mapped["PhenologicalStageTemplate"] = relationship(
        back_populates="parcel_stages"
    )

    @property
    def name(self) -> str:
        return self.template.name

    @property
    def stage_order(self) -> int:
        return self.template.stage_order

    @property
    def duration_days(self) -> int | None:
        return self.template.duration_days
