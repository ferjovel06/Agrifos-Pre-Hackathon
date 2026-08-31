import uuid
from sqlalchemy import String, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import UUIDPKMixin, TimestampMixin


class Crop(Base, UUIDPKMixin, TimestampMixin):
    __tablename__ = "crops"

    name: Mapped[str] = mapped_column(String(100), unique=True)

    varieties: Mapped[list["Variety"]] = relationship(back_populates="crop")
    parcels: Mapped[list["Parcel"]] = relationship(back_populates="crop")
    stage_templates: Mapped[list["PhenologicalStageTemplate"]] = relationship(
        back_populates="crop"
    )
    optimal_requirements: Mapped[list["OptimalRequirement"]] = relationship(
        back_populates="crop"
    )
    extraction_indices: Mapped[list["ExtractionIndex"]] = relationship(
        back_populates="crop"
    )


class Variety(Base, UUIDPKMixin, TimestampMixin):
    __tablename__ = "varieties"

    crop_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("crops.id"), nullable=False)
    name: Mapped[str] = mapped_column(String(100))

    crop: Mapped["Crop"] = relationship(back_populates="varieties")
    parcels: Mapped[list["Parcel"]] = relationship(back_populates="variety")
    factors: Mapped[list["VarietyFactor"]] = relationship(back_populates="variety")
