import uuid
from datetime import datetime
from sqlalchemy import String, DateTime, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import UUIDPKMixin


class Alert(Base, UUIDPKMixin):
    __tablename__ = "alerts"

    farm_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("farms.id"), nullable=False)
    parcel_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("parcels.id"), nullable=True
    )

    type: Mapped[str] = mapped_column(String(30))  # weather | phenology
    message: Mapped[str] = mapped_column(String(500))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    farm: Mapped["Farm"] = relationship(back_populates="alerts")
    parcel: Mapped["Parcel | None"] = relationship(back_populates="alerts")