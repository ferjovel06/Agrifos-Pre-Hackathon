import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Variety


async def get_variety(db: AsyncSession, variety_id: uuid.UUID) -> Variety | None:
    result = await db.execute(select(Variety).where(Variety.id == variety_id))
    return result.scalar_one_or_none()


async def list_varieties(
    db: AsyncSession, crop_id: uuid.UUID | None = None, skip: int = 0, limit: int = 50
) -> list[Variety]:
    query = select(Variety)
    if crop_id is not None:
        query = query.where(Variety.crop_id == crop_id)
    result = await db.execute(query.offset(skip).limit(limit))
    return list(result.scalars().all())


async def create_variety(db: AsyncSession, variety: Variety) -> Variety:
    db.add(variety)
    await db.commit()
    await db.refresh(variety)
    return variety


async def update_variety(db: AsyncSession, variety: Variety) -> Variety:
    await db.commit()
    await db.refresh(variety)
    return variety


async def delete_variety(db: AsyncSession, variety: Variety) -> None:
    await db.delete(variety)
    await db.commit()