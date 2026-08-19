import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload

from app.models import Parcel


async def get_parcel(db: AsyncSession, parcel_id: uuid.UUID) -> Parcel | None:
    result = await db.execute(
        select(Parcel).options(joinedload(Parcel.farm)).where(Parcel.id == parcel_id)
    )
    return result.scalar_one_or_none()


async def list_parcels_by_farm(
    db: AsyncSession, farm_id: uuid.UUID, skip: int = 0, limit: int = 50
) -> list[Parcel]:
    result = await db.execute(
        select(Parcel).where(Parcel.farm_id == farm_id).offset(skip).limit(limit)
    )
    return list(result.scalars().all())


async def list_parcels_by_user(
    db: AsyncSession, user_id: uuid.UUID, skip: int = 0, limit: int = 50
) -> list[Parcel]:
    from app.models import Farm

    result = await db.execute(
        select(Parcel)
        .join(Farm, Farm.id == Parcel.farm_id)
        .where(Farm.user_id == user_id)
        .offset(skip)
        .limit(limit)
    )
    return list(result.scalars().all())


async def list_all_parcels(db: AsyncSession, skip: int = 0, limit: int = 50) -> list[Parcel]:
    result = await db.execute(select(Parcel).offset(skip).limit(limit))
    return list(result.scalars().all())


async def create_parcel(db: AsyncSession, parcel: Parcel) -> Parcel:
    db.add(parcel)
    await db.commit()
    await db.refresh(parcel)
    return parcel


async def update_parcel(db: AsyncSession, parcel: Parcel) -> Parcel:
    await db.commit()
    await db.refresh(parcel)
    return parcel


async def delete_parcel(db: AsyncSession, parcel: Parcel) -> None:
    await db.delete(parcel)
    await db.commit()