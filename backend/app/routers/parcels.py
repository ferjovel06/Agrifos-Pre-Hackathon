import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.core.auth import get_current_user
from app.models import User, Parcel
from app.schemas.parcel import ParcelCreate, ParcelUpdate, ParcelRead
from app.repositories import parcel as parcel_repo
from app.repositories import farm as farm_repo

router = APIRouter(prefix="/parcels", tags=["parcels"])


async def _get_owned_farm_or_403(farm_id: uuid.UUID, db: AsyncSession, current_user: User):
    farm = await farm_repo.get_farm(db, farm_id)
    if not farm:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Farm not found.")
    if farm.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not enough permissions.")
    return farm


async def _get_owned_parcel(
    parcel_id: uuid.UUID,
    db: AsyncSession,
    current_user: User,
) -> Parcel:
    parcel = await parcel_repo.get_parcel(db, parcel_id)
    if not parcel:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Parcel not found.")
    # verifica que la finca dueña de la parcela pertenezca al usuario (o sea admin)
    await _get_owned_farm_or_403(parcel.farm_id, db, current_user)
    return parcel


@router.post("", response_model=ParcelRead, status_code=status.HTTP_201_CREATED)
async def create_parcel(
    payload: ParcelCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _get_owned_farm_or_403(payload.farm_id, db, current_user)
    parcel = Parcel(**payload.model_dump())
    return await parcel_repo.create_parcel(db, parcel)


@router.get("", response_model=list[ParcelRead])
async def list_parcels(
    farm_id: uuid.UUID | None = None,
    skip: int = 0,
    limit: int = 50,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if farm_id is not None:
        await _get_owned_farm_or_403(farm_id, db, current_user)
        return await parcel_repo.list_parcels_by_farm(db, farm_id, skip, limit)

    if current_user.role == "admin":
        return await parcel_repo.list_all_parcels(db, skip, limit)
    return await parcel_repo.list_parcels_by_user(db, current_user.id, skip, limit)


@router.get("/{parcel_id}", response_model=ParcelRead)
async def get_parcel(
    parcel_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await _get_owned_parcel(parcel_id, db, current_user)


@router.patch("/{parcel_id}", response_model=ParcelRead)
async def update_parcel(
    parcel_id: uuid.UUID,
    payload: ParcelUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    parcel = await _get_owned_parcel(parcel_id, db, current_user)

    update_data = payload.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(parcel, field, value)
    return await parcel_repo.update_parcel(db, parcel)


@router.delete("/{parcel_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_parcel(
    parcel_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    parcel = await _get_owned_parcel(parcel_id, db, current_user)
    await parcel_repo.delete_parcel(db, parcel)