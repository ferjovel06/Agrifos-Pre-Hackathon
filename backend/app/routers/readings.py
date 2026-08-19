import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import get_current_user
from app.db.session import get_db
from app.models import Parcel, Reading, User
from app.repositories import parcel as parcel_repo
from app.repositories import reading as reading_repo
from app.schemas.reading import ReadingCreate, ReadingRead

router = APIRouter(prefix="/readings", tags=["readings"])


async def _get_authorized_parcel(
    db: AsyncSession, parcel_id: uuid.UUID, user: User
) -> Parcel:
    """Verify that the parcel exists and that the user has access to it."""
    parcel = await parcel_repo.get_parcel(db, parcel_id)
    if not parcel:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Parcel not found."
        )
    if user.role != "admin" and parcel.farm.user_id != user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Not enough permissions."
        )
    return parcel


@router.post("", response_model=ReadingRead, status_code=status.HTTP_201_CREATED)
async def create_reading(
    payload: ReadingCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Receives and stores a sensor reading (NPK, EC, pH, temperature, humidity)."""
    await _get_authorized_parcel(db, payload.parcel_id, current_user)

    reading = Reading(**payload.model_dump(exclude_none=True))
    return await reading_repo.create_reading(db, reading)


@router.get("", response_model=list[ReadingRead])
async def list_readings(
    parcel_id: uuid.UUID = Query(..., description="Parcel to query"),
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _get_authorized_parcel(db, parcel_id, current_user)
    return await reading_repo.list_readings_by_parcel(db, parcel_id, skip, limit)


@router.get("/{reading_id}", response_model=ReadingRead)
async def get_reading(
    reading_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    reading = await reading_repo.get_reading(db, reading_id)
    if not reading:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Reading not found."
        )
    await _get_authorized_parcel(db, reading.parcel_id, current_user)
    return reading