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