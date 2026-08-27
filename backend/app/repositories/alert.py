import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Alert


WEATHER_ALERT_TYPES = ("weather_fertilization", "weather_heat")


async def list_farm_alerts(
    db: AsyncSession,
    farm_id: uuid.UUID,
    active_only: bool = True,
) -> list[Alert]:
    statement = select(Alert).where(Alert.farm_id == farm_id)
    if active_only:
        statement = statement.where(Alert.is_active.is_(True))
    result = await db.execute(
        statement.order_by(Alert.event_date.asc().nullslast(), Alert.created_at.desc())
    )
    return list(result.scalars().all())


async def sync_weather_alerts(
    db: AsyncSession,
    farm_id: uuid.UUID,
    candidates: list[Alert],
) -> list[Alert]:
    result = await db.execute(
        select(Alert).where(
            Alert.farm_id == farm_id,
            Alert.type.in_(WEATHER_ALERT_TYPES),
            Alert.is_active.is_(True),
        )
    )
    existing = {
        (alert.type, alert.event_date): alert for alert in result.scalars().all()
    }
    active_keys = {(candidate.type, candidate.event_date) for candidate in candidates}
    synced: list[Alert] = []

    for candidate in candidates:
        key = (candidate.type, candidate.event_date)
        alert = existing.get(key)
        if alert is None:
            db.add(candidate)
            alert = candidate
        else:
            alert.title = candidate.title
            alert.message = candidate.message
            alert.severity = candidate.severity
            alert.risk_score = candidate.risk_score
            alert.is_active = True
        synced.append(alert)

    for key, alert in existing.items():
        if key not in active_keys:
            alert.is_active = False

    await db.commit()
    for alert in synced:
        await db.refresh(alert)
    return synced
