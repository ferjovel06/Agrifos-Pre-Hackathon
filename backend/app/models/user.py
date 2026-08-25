from sqlalchemy import Column, Date, ForeignKey, String, Table
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.db.base import Base
from app.models.mixins import TimestampMixin

auth_users = Table(
    "users",
    Base.metadata,
    Column("id", UUID(as_uuid=True), primary_key=True),
    schema="auth",
)


class User(Base, TimestampMixin):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), ForeignKey("auth.users.id", ondelete="CASCADE"), primary_key=True)
    name = Column(String(150), nullable=False)
    email = Column(String, nullable=False, unique=True)
    role = Column(String(20), nullable=False, default="farmer")
    birth_date = Column(Date, nullable=True)
    gender = Column(String(30), nullable=True)
    phone = Column(String(30), nullable=True)
    country = Column(String(80), nullable=True)
    department = Column(String(100), nullable=True)
    address = Column(String(255), nullable=True)

    farms = relationship("Farm", back_populates="owner")
