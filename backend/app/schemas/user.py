import uuid
from datetime import date, datetime
from enum import Enum

from pydantic import BaseModel, EmailStr, Field, ConfigDict


class UserRole(str, Enum):
    farmer = "farmer"
    auditor = "auditor"
    admin = "admin"


class UserUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=150)
    role: UserRole | None = None
    birth_date: date | None = None
    gender: str | None = Field(default=None, max_length=30)
    phone: str | None = Field(default=None, max_length=30)
    country: str | None = Field(default=None, max_length=80)
    department: str | None = Field(default=None, max_length=100)
    address: str | None = Field(default=None, max_length=255)


class UserRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    email: str
    role: str
    birth_date: date | None
    gender: str | None
    phone: str | None
    country: str | None
    department: str | None
    address: str | None
    created_at: datetime
    updated_at: datetime
