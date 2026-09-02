import uuid
from datetime import datetime

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import UUIDPKMixin


class AgronomicReferenceSet(Base, UUIDPKMixin):
    """Immutable, identifiable group of values used by an engine run."""

    __tablename__ = "agronomic_reference_sets"
    __table_args__ = (
        UniqueConstraint("key", "version", name="uq_reference_set_key_version"),
    )

    key: Mapped[str] = mapped_column(String(80), nullable=False)
    version: Mapped[str] = mapped_column(String(40), nullable=False)
    source: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    soil_ranges: Mapped[list["SoilReferenceRange"]] = relationship(
        back_populates="reference_set", cascade="all, delete-orphan"
    )
    products: Mapped[list["FertilizerProduct"]] = relationship(
        back_populates="reference_set", cascade="all, delete-orphan"
    )
    schedules: Mapped[list["ApplicationScheduleRule"]] = relationship(
        back_populates="reference_set", cascade="all, delete-orphan"
    )
    parameters: Mapped[list["AgronomicParameter"]] = relationship(
        back_populates="reference_set", cascade="all, delete-orphan"
    )


class SoilReferenceRange(Base, UUIDPKMixin):
    __tablename__ = "soil_reference_ranges"
    __table_args__ = (
        UniqueConstraint(
            "reference_set_id",
            "crop_id",
            "parameter",
            name="uq_soil_range_set_crop_parameter",
        ),
        CheckConstraint(
            "optimal_min IS NULL OR optimal_max IS NULL OR optimal_min <= optimal_max",
            name="ck_soil_range_valid_optimal_bounds",
        ),
    )

    reference_set_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("agronomic_reference_sets.id", ondelete="CASCADE"), nullable=False
    )
    crop_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("crops.id", ondelete="CASCADE"), nullable=False
    )
    parameter: Mapped[str] = mapped_column(String(50), nullable=False)
    label_es: Mapped[str] = mapped_column(String(120), nullable=False)
    unit: Mapped[str] = mapped_column(String(40), nullable=False)
    method: Mapped[str] = mapped_column(Text, nullable=False)
    confidence: Mapped[str] = mapped_column(String(30), nullable=False)
    deficient_below: Mapped[float | None] = mapped_column(Float, nullable=True)
    optimal_min: Mapped[float | None] = mapped_column(Float, nullable=True)
    optimal_max: Mapped[float | None] = mapped_column(Float, nullable=True)
    critical_above: Mapped[float | None] = mapped_column(Float, nullable=True)
    high_is_generally_favorable: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False
    )
    notes: Mapped[str] = mapped_column(Text, nullable=False)

    reference_set: Mapped["AgronomicReferenceSet"] = relationship(
        back_populates="soil_ranges"
    )


class FertilizerProduct(Base, UUIDPKMixin):
    __tablename__ = "fertilizer_products"
    __table_args__ = (
        UniqueConstraint(
            "reference_set_id", "key", name="uq_fertilizer_product_set_key"
        ),
    )

    reference_set_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("agronomic_reference_sets.id", ondelete="CASCADE"), nullable=False
    )
    key: Mapped[str] = mapped_column(String(60), nullable=False)
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    is_low_chloride: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False
    )
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    reference_set: Mapped["AgronomicReferenceSet"] = relationship(
        back_populates="products"
    )
    nutrients: Mapped[list["FertilizerProductNutrient"]] = relationship(
        back_populates="product", cascade="all, delete-orphan"
    )


class FertilizerProductNutrient(Base, UUIDPKMixin):
    __tablename__ = "fertilizer_product_nutrients"
    __table_args__ = (
        UniqueConstraint("product_id", "nutrient", name="uq_product_nutrient"),
        CheckConstraint(
            "fraction > 0 AND fraction <= 1",
            name="ck_product_nutrient_fraction",
        ),
    )

    product_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("fertilizer_products.id", ondelete="CASCADE"), nullable=False
    )
    nutrient: Mapped[str] = mapped_column(String(30), nullable=False)
    fraction: Mapped[float] = mapped_column(Float, nullable=False)

    product: Mapped["FertilizerProduct"] = relationship(back_populates="nutrients")


class ApplicationScheduleRule(Base, UUIDPKMixin):
    __tablename__ = "application_schedule_rules"
    __table_args__ = (
        UniqueConstraint(
            "reference_set_id",
            "crop_id",
            "life_stage",
            "sequence",
            name="uq_application_rule_set_crop_stage_sequence",
        ),
        CheckConstraint(
            "fraction > 0 AND fraction <= 1", name="ck_application_rule_fraction"
        ),
    )

    reference_set_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("agronomic_reference_sets.id", ondelete="CASCADE"), nullable=False
    )
    crop_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("crops.id", ondelete="CASCADE"), nullable=False
    )
    life_stage: Mapped[str] = mapped_column(String(40), nullable=False)
    sequence: Mapped[int] = mapped_column(Integer, nullable=False)
    moment: Mapped[str] = mapped_column(String(150), nullable=False)
    month_after_planting: Mapped[int | None] = mapped_column(Integer, nullable=True)
    fraction: Mapped[float] = mapped_column(Float, nullable=False)

    reference_set: Mapped["AgronomicReferenceSet"] = relationship(
        back_populates="schedules"
    )


class AgronomicParameter(Base, UUIDPKMixin):
    __tablename__ = "agronomic_parameters"
    __table_args__ = (
        UniqueConstraint(
            "reference_set_id",
            "crop_id",
            "key",
            name="uq_agronomic_parameter_set_crop_key",
        ),
    )

    reference_set_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("agronomic_reference_sets.id", ondelete="CASCADE"), nullable=False
    )
    crop_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("crops.id", ondelete="CASCADE"), nullable=False
    )
    key: Mapped[str] = mapped_column(String(100), nullable=False)
    value: Mapped[float] = mapped_column(Float, nullable=False)
    unit: Mapped[str | None] = mapped_column(String(40), nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    reference_set: Mapped["AgronomicReferenceSet"] = relationship(
        back_populates="parameters"
    )
