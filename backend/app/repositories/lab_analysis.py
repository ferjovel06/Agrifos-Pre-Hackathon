import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import LabAnalysis


async def create_lab_analysis(
    db: AsyncSession,
    analysis: LabAnalysis,
) -> LabAnalysis:
    db.add(analysis)
    await db.commit()
    await db.refresh(analysis)
    return analysis


async def get_lab_analysis(
    db: AsyncSession,
    analysis_id: uuid.UUID,
) -> LabAnalysis | None:
    result = await db.execute(
        select(LabAnalysis).where(LabAnalysis.id == analysis_id)
    )
    return result.scalar_one_or_none()


async def list_lab_analyses_by_parcel(
    db: AsyncSession,
    parcel_id: uuid.UUID,
    skip: int = 0,
    limit: int = 100,
) -> list[LabAnalysis]:
    result = await db.execute(
        select(LabAnalysis)
        .where(LabAnalysis.parcel_id == parcel_id)
        .order_by(LabAnalysis.sampled_at.desc().nullslast(), LabAnalysis.recorded_at.desc())
        .offset(skip)
        .limit(limit)
    )
    return list(result.scalars().all())


async def update_lab_analysis(
    db: AsyncSession,
    analysis: LabAnalysis,
) -> LabAnalysis:
    await db.commit()
    await db.refresh(analysis)
    return analysis


async def delete_lab_analysis(db: AsyncSession, analysis: LabAnalysis) -> None:
    await db.delete(analysis)
    await db.commit()
