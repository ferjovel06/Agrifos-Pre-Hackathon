import uuid
from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import UUIDPKMixin, TimestampMixin


class User(Base, UUIDPKMixin, TimestampMixin):
    __tablename__ = "users"

    name: Mapped[str] = mapped_column(String(150))
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    hashed_password: Mapped[str] = mapped_column(String(255))
    role: Mapped[str] = mapped_column(String(20), default="farmer")  # farmer | admin

    farms: Mapped[list["Farm"]] = relationship(back_populates="owner")