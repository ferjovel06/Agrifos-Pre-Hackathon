import uuid
from sqlalchemy import String, Float, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import UUIDPKMixin


class OptimalRequirement(Base, UUIDPKMixin):
    """Optimal nutrient range for a crop and phenological stage."""
    __tablename__ = "optimal_requirements"

    reference_set_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("agronomic_reference_sets.id", ondelete="RESTRICT"), nullable=True
    )

    crop_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("crops.id"), nullable=False)
    stage_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("phenological_stages.id"), nullable=False
    )
    nutrient: Mapped[str] = mapped_column(String(30))
    min_value: Mapped[float] = mapped_column(Float)
    max_value: Mapped[float] = mapped_column(Float)

    crop: Mapped["Crop"] = relationship(back_populates="optimal_requirements")
    stage: Mapped["PhenologicalStage"] = relationship(
        back_populates="optimal_requirements"
    )


class ExtractionIndex(Base, UUIDPKMixin):
    """Base nutrient extraction index for a crop."""
    __tablename__ = "extraction_indices"

    reference_set_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("agronomic_reference_sets.id", ondelete="RESTRICT"), nullable=True
    )

    crop_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("crops.id"), nullable=False)
    nutrient: Mapped[str] = mapped_column(String(30))
    ie_value: Mapped[float] = mapped_column(Float)

    crop: Mapped["Crop"] = relationship(back_populates="extraction_indices")


class VarietyFactor(Base, UUIDPKMixin):
    """Nutrient correction factor for a crop variety."""
    __tablename__ = "variety_factors"

    reference_set_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("agronomic_reference_sets.id", ondelete="RESTRICT"), nullable=True
    )

    variety_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("varieties.id"), nullable=False
    )
    nutrient: Mapped[str] = mapped_column(String(30))
    fv_factor: Mapped[float] = mapped_column(Float)

    variety: Mapped["Variety"] = relationship(back_populates="factors")


class StageFactor(Base, UUIDPKMixin):
    """Nutrient distribution factor for a phenological stage."""
    __tablename__ = "stage_factors"

    reference_set_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("agronomic_reference_sets.id", ondelete="RESTRICT"), nullable=True
    )

    stage_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("phenological_stages.id"), nullable=False
    )
    nutrient: Mapped[str] = mapped_column(String(30))
    fe_factor: Mapped[float] = mapped_column(Float)

    stage: Mapped["PhenologicalStage"] = relationship(back_populates="factors")


class SoilType(Base, UUIDPKMixin):
    __tablename__ = "soil_types"

    name: Mapped[str] = mapped_column(String(100), unique=True)
    description: Mapped[str | None] = mapped_column(String(255), nullable=True)

    efficiency_factors: Mapped[list["EfficiencyFactor"]] = relationship(
        back_populates="soil_type"
    )


class EfficiencyFactor(Base, UUIDPKMixin):
    """Nutrient absorption-efficiency range for a soil type."""
    __tablename__ = "efficiency_factors"

    reference_set_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("agronomic_reference_sets.id", ondelete="RESTRICT"), nullable=True
    )

    soil_type_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("soil_types.id"), nullable=False
    )
    nutrient: Mapped[str] = mapped_column(String(30))
    ef_min: Mapped[float] = mapped_column(Float)
    ef_max: Mapped[float] = mapped_column(Float)

    soil_type: Mapped["SoilType"] = relationship(back_populates="efficiency_factors")
