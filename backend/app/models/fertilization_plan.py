import uuid
from datetime import datetime

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    JSON,
    String,
    UniqueConstraint,
    func,
)
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
    reference_set_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("agronomic_reference_sets.id", ondelete="RESTRICT"), nullable=False
    )

    method: Mapped[str] = mapped_column(String(20))  # sensor | laboratory | mixed
    target_green_kg_ha: Mapped[float] = mapped_column(Float, nullable=False)
    plant_age_months: Mapped[int] = mapped_column(Integer, nullable=False)
    life_stage: Mapped[str] = mapped_column(String(40), nullable=False)
    fruit_stage: Mapped[str] = mapped_column(String(40), nullable=False)
    engine_version: Mapped[str] = mapped_column(String(40), nullable=False)
    recommendation_status: Mapped[str] = mapped_column(String(60), nullable=False)
    nutrient_requirements: Mapped[list[dict]] = mapped_column(JSON, nullable=False)
    limiting_nutrients: Mapped[list[str]] = mapped_column(JSON, nullable=False)
    warnings: Mapped[list[str]] = mapped_column(JSON, nullable=False)
    assumptions: Mapped[list[str]] = mapped_column(JSON, nullable=False)
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
    items: Mapped[list["FertilizationPlanItem"]] = relationship(
        back_populates="plan", cascade="all, delete-orphan"
    )


class FertilizationPlanItem(Base, UUIDPKMixin):
    __tablename__ = "fertilization_plan_items"
    __table_args__ = (
        UniqueConstraint(
            "plan_id",
            "scenario_name",
            "application_number",
            "fertilizer_product_id",
            name="uq_plan_item_scenario_application_product",
        ),
        CheckConstraint("fraction > 0 AND fraction <= 1", name="ck_plan_item_fraction"),
        CheckConstraint(
            "kg_ha >= 0 AND kg_manzana >= 0 AND g_plant >= 0",
            name="ck_plan_item_nonnegative_doses",
        ),
    )

    plan_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("fertilization_plans.id", ondelete="CASCADE"), nullable=False
    )
    fertilizer_product_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("fertilizer_products.id", ondelete="RESTRICT"), nullable=False
    )
    scenario_name: Mapped[str] = mapped_column(String(100), nullable=False)
    selection_method: Mapped[str] = mapped_column(String(255), nullable=False)
    scenario_is_valid: Mapped[bool] = mapped_column(Boolean, nullable=False)
    application_number: Mapped[int] = mapped_column(Integer, nullable=False)
    moment: Mapped[str] = mapped_column(String(150), nullable=False)
    fraction: Mapped[float] = mapped_column(Float, nullable=False)
    kg_ha: Mapped[float] = mapped_column(Float, nullable=False)
    kg_manzana: Mapped[float] = mapped_column(Float, nullable=False)
    g_plant: Mapped[float] = mapped_column(Float, nullable=False)
    guaranteed_analysis_pct: Mapped[dict[str, float]] = mapped_column(
        JSON, nullable=False
    )
    nutrient_contributions_kg_ha: Mapped[dict[str, float]] = mapped_column(
        JSON, nullable=False
    )

    plan: Mapped["FertilizationPlan"] = relationship(back_populates="items")
