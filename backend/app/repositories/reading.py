import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Reading


async def create_reading(db: AsyncSession, reading: Reading) -> Reading:
    db.add(reading)
    await db.commit()
    await db.refresh(reading)
    return reading


async def get_reading(db: AsyncSession, reading_id: uuid.UUID) -> Reading | None:
    result = await db.execute(select(Reading).where(Reading.id == reading_id))
    return result.scalar_one_or_none()


async def list_readings_by_parcel(
    db: AsyncSession,
    parcel_id: uuid.UUID,
    skip: int = 0,
    limit: int = 100,
) -> list[Reading]:
    result = await db.execute(
        select(Reading)
        .where(Reading.parcel_id == parcel_id)
        .order_by(Reading.recorded_at.desc())
        .offset(skip)
        .limit(limit)
    )
    return list(result.scalars().all())