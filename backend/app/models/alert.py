import uuid
from datetime import date, datetime
from sqlalchemy import Boolean, Date, DateTime, Float, ForeignKey, String, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import UUIDPKMixin


class Alert(Base, UUIDPKMixin):
    __tablename__ = "alerts"
    __table_args__ = (
        UniqueConstraint(
            "farm_id",
            "type",
            "event_date",
            name="uq_alert_farm_type_event_date",
        ),
    )

    farm_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("farms.id"), nullable=False)
    parcel_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("parcels.id"), nullable=True
    )

    type: Mapped[str] = mapped_column(String(30))  # weather | phenology
    title: Mapped[str] = mapped_column(String(150))
    message: Mapped[str] = mapped_column(String(500))
    severity: Mapped[str] = mapped_column(String(20), default="warning")
    event_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    risk_score: Mapped[float | None] = mapped_column(Float, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    farm: Mapped["Farm"] = relationship(back_populates="alerts")
    parcel: Mapped["Parcel | None"] = relationship(back_populates="alerts")
