import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models import ParcelPhenologicalStage, PhenologicalStageTemplate


async def get_template(
    db: AsyncSession, template_id: uuid.UUID
) -> PhenologicalStageTemplate | None:
    result = await db.execute(
        select(PhenologicalStageTemplate).where(
            PhenologicalStageTemplate.id == template_id
        )
    )
    return result.scalar_one_or_none()


async def get_instance(
    db: AsyncSession, instance_id: uuid.UUID
) -> ParcelPhenologicalStage | None:
    result = await db.execute(
        select(ParcelPhenologicalStage)
        .options(selectinload(ParcelPhenologicalStage.template))
        .where(ParcelPhenologicalStage.id == instance_id)
    )
    return result.scalar_one_or_none()


async def list_templates(
    db: AsyncSession,
    crop_id: uuid.UUID | None = None,
    skip: int = 0,
    limit: int = 50,
) -> list[PhenologicalStageTemplate]:
    query = select(PhenologicalStageTemplate)
    if crop_id is not None:
        query = query.where(PhenologicalStageTemplate.crop_id == crop_id)
    result = await db.execute(
        query.order_by(PhenologicalStageTemplate.stage_order)
        .offset(skip)
        .limit(limit)
    )
    return list(result.scalars().all())


async def list_instances(
    db: AsyncSession,
    parcel_id: uuid.UUID,
    skip: int = 0,
    limit: int = 50,
) -> list[ParcelPhenologicalStage]:
    result = await db.execute(
        select(ParcelPhenologicalStage)
        .options(selectinload(ParcelPhenologicalStage.template))
        .join(ParcelPhenologicalStage.template)
        .where(ParcelPhenologicalStage.parcel_id == parcel_id)
        .order_by(PhenologicalStageTemplate.stage_order)
        .offset(skip)
        .limit(limit)
    )
    return list(result.scalars().all())


async def create_template(
    db: AsyncSession, template: PhenologicalStageTemplate
) -> PhenologicalStageTemplate:
    db.add(template)
    await db.commit()
    await db.refresh(template)
    return template


async def create_instance(
    db: AsyncSession, instance: ParcelPhenologicalStage
) -> ParcelPhenologicalStage:
    db.add(instance)
    await db.commit()
    await db.refresh(instance)
    await db.refresh(instance, attribute_names=["template"])
    return instance


async def update_template(
    db: AsyncSession, template: PhenologicalStageTemplate
) -> PhenologicalStageTemplate:
    await db.commit()
    await db.refresh(template)
    return template


async def update_instance(
    db: AsyncSession, instance: ParcelPhenologicalStage
) -> ParcelPhenologicalStage:
    await db.commit()
    await db.refresh(instance)
    await db.refresh(instance, attribute_names=["template"])
    return instance


async def delete_template(
    db: AsyncSession, template: PhenologicalStageTemplate
) -> None:
    await db.delete(template)
    await db.commit()


async def delete_instance(
    db: AsyncSession, instance: ParcelPhenologicalStage
) -> None:
    await db.delete(instance)
    await db.commit()
