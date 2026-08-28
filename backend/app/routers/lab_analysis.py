import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import ValidationError
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import (
    get_current_user,
    has_global_read_access,
    require_write_access,
)
from app.db.session import get_db
from app.models import LabAnalysis, Parcel, User
from app.repositories import lab_analysis as lab_repo
from app.repositories import parcel as parcel_repo
from app.schemas.lab_analysis import (
    LabAnalysisCreate,
    LabAnalysisRead,
    LabAnalysisUpdate,
    LabAnalysisValues,
)


router = APIRouter(prefix="/lab-analyses", tags=["laboratory analyses"])


async def _get_authorized_parcel(
    db: AsyncSession,
    parcel_id: uuid.UUID,
    user: User,
) -> Parcel:
    parcel = await parcel_repo.get_parcel(db, parcel_id)
    if not parcel:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Parcel not found.",
        )
    if not has_global_read_access(user) and parcel.farm.user_id != user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions.",
        )
    return parcel


async def _get_authorized_analysis(
    db: AsyncSession,
    analysis_id: uuid.UUID,
    user: User,
) -> LabAnalysis:
    analysis = await lab_repo.get_lab_analysis(db, analysis_id)
    if not analysis:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Laboratory analysis not found.",
        )
    await _get_authorized_parcel(db, analysis.parcel_id, user)
    return analysis


@router.post(
    "",
    response_model=LabAnalysisRead,
    status_code=status.HTTP_201_CREATED,
)
async def create_lab_analysis(
    payload: LabAnalysisCreate,
    current_user: User = Depends(require_write_access),
    db: AsyncSession = Depends(get_db),
):
    await _get_authorized_parcel(db, payload.parcel_id, current_user)
    analysis = LabAnalysis(**payload.model_dump())
    try:
        return await lab_repo.create_lab_analysis(db, analysis)
    except IntegrityError as error:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="The sample code is already registered for this parcel.",
        ) from error


@router.get("", response_model=list[LabAnalysisRead])
async def list_lab_analyses(
    parcel_id: uuid.UUID = Query(..., description="Parcel to query"),
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=100, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _get_authorized_parcel(db, parcel_id, current_user)
    return await lab_repo.list_lab_analyses_by_parcel(
        db,
        parcel_id,
        skip,
        limit,
    )


@router.get("/{analysis_id}", response_model=LabAnalysisRead)
async def get_lab_analysis(
    analysis_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await _get_authorized_analysis(db, analysis_id, current_user)


@router.patch("/{analysis_id}", response_model=LabAnalysisRead)
async def update_lab_analysis(
    analysis_id: uuid.UUID,
    payload: LabAnalysisUpdate,
    current_user: User = Depends(require_write_access),
    db: AsyncSession = Depends(get_db),
):
    analysis = await _get_authorized_analysis(db, analysis_id, current_user)
    update_data = payload.model_dump(exclude_unset=True)
    merged_values = {
        field: update_data.get(field, getattr(analysis, field))
        for field in LabAnalysisValues.model_fields
    }
    try:
        LabAnalysisValues.model_validate(merged_values)
    except ValidationError as error:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail=str(error),
        ) from error
    for field, value in update_data.items():
        setattr(analysis, field, value)

    try:
        return await lab_repo.update_lab_analysis(db, analysis)
    except IntegrityError as error:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="The sample code is already registered for this parcel.",
        ) from error


@router.delete("/{analysis_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_lab_analysis(
    analysis_id: uuid.UUID,
    current_user: User = Depends(require_write_access),
    db: AsyncSession = Depends(get_db),
):
    analysis = await _get_authorized_analysis(db, analysis_id, current_user)
    await lab_repo.delete_lab_analysis(db, analysis)
