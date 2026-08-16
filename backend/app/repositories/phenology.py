import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import PhenologicalStage


async def get_stage(db: AsyncSession, stage_id: uuid.UUID) -> PhenologicalStage | None:
    result = await db.execute(
        select(PhenologicalStage).where(PhenologicalStage.id == stage_id)
    )
    return result.scalar_one_or_none()


async def list_templates(
    db: AsyncSession, crop_id: uuid.UUID | None = None, skip: int = 0, limit: int = 50
) -> list[PhenologicalStage]:
    query = select(PhenologicalStage).where(PhenologicalStage.parcel_id.is_(None))
    if crop_id is not None:
        query = query.where(PhenologicalStage.crop_id == crop_id)
    result = await db.execute(query.order_by(PhenologicalStage.stage_order).offset(skip).limit(limit))
    return list(result.scalars().all())


async def list_instances(
    db: AsyncSession, parcel_id: uuid.UUID, skip: int = 0, limit: int = 50
) -> list[PhenologicalStage]:
    query = select(PhenologicalStage).where(PhenologicalStage.parcel_id == parcel_id)
    result = await db.execute(query.order_by(PhenologicalStage.stage_order).offset(skip).limit(limit))
    return list(result.scalars().all())


async def create_stage(db: AsyncSession, stage: PhenologicalStage) -> PhenologicalStage:
    db.add(stage)
    await db.commit()
    await db.refresh(stage)
    return stage


async def update_stage(db: AsyncSession, stage: PhenologicalStage) -> PhenologicalStage:
    await db.commit()
    await db.refresh(stage)
    return stage


async def delete_stage(db: AsyncSession, stage: PhenologicalStage) -> None:
    await db.delete(stage)
    await db.commit()