import uuid
from datetime import date, datetime

from pydantic import BaseModel, ConfigDict


class AlertRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    farm_id: uuid.UUID
    parcel_id: uuid.UUID | None
    type: str
    title: str
    message: str
    severity: str
    event_date: date | None
    risk_score: float | None
    is_active: bool
    created_at: datetime


class AlertEvaluationRead(BaseModel):
    farm_id: uuid.UUID
    evaluated_days: int
    active_alerts: list[AlertRead]
