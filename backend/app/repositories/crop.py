import uuid

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Crop


async def get_crop(db: AsyncSession, crop_id: uuid.UUID) -> Crop | None:
    result = await db.execute(select(Crop).where(Crop.id == crop_id))
    return result.scalar_one_or_none()


async def list_crops(db: AsyncSession, skip: int = 0, limit: int = 50) -> list[Crop]:
    result = await db.execute(select(Crop).offset(skip).limit(limit))
    return list(result.scalars().all())


async def create_crop(db: AsyncSession, crop: Crop) -> Crop:
    db.add(crop)
    try:
        await db.commit()
    except IntegrityError:
        await db.rollback()
        raise
    await db.refresh(crop)
    return crop


async def update_crop(db: AsyncSession, crop: Crop) -> Crop:
    try:
        await db.commit()
    except IntegrityError:
        await db.rollback()
        raise
    await db.refresh(crop)
    return crop


async def delete_crop(db: AsyncSession, crop: Crop) -> None:
    await db.delete(crop)
    await db.commit()