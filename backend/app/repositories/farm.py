import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Farm


async def get_farm(db: AsyncSession, farm_id: uuid.UUID) -> Farm | None:
    result = await db.execute(select(Farm).where(Farm.id == farm_id))
    return result.scalar_one_or_none()


async def list_farms_by_user(
    db: AsyncSession, user_id: uuid.UUID, skip: int = 0, limit: int = 50
) -> list[Farm]:
    result = await db.execute(
        select(Farm).where(Farm.user_id == user_id).offset(skip).limit(limit)
    )
    return list(result.scalars().all())


async def list_all_farms(db: AsyncSession, skip: int = 0, limit: int = 50) -> list[Farm]:
    result = await db.execute(select(Farm).offset(skip).limit(limit))
    return list(result.scalars().all())


async def create_farm(db: AsyncSession, farm: Farm) -> Farm:
    db.add(farm)
    await db.commit()
    await db.refresh(farm)
    return farm


async def update_farm(db: AsyncSession, farm: Farm) -> Farm:
    await db.commit()
    await db.refresh(farm)
    return farm


async def delete_farm(db: AsyncSession, farm: Farm) -> None:
    await db.delete(farm)
    await db.commit()