import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.core.auth import (
    get_current_user,
    has_global_read_access,
    require_write_access,
)
from app.models import User, Farm
from app.schemas.farm import FarmCreate, FarmUpdate, FarmRead
from app.repositories import farm as farm_repo

router = APIRouter(prefix="/farms", tags=["farms"])


async def _get_owned_farm(
    farm_id: uuid.UUID,
    db: AsyncSession,
    current_user: User,
) -> Farm:
    farm = await farm_repo.get_farm(db, farm_id)
    if not farm:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Farm not found.")
    if (
        farm.user_id != current_user.id
        and not has_global_read_access(current_user)
    ):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not enough permissions.")
    return farm


@router.post("", response_model=FarmRead, status_code=status.HTTP_201_CREATED)
async def create_farm(
    payload: FarmCreate,
    current_user: User = Depends(require_write_access),
    db: AsyncSession = Depends(get_db),
):
    farm = Farm(user_id=current_user.id, **payload.model_dump())
    return await farm_repo.create_farm(db, farm)


@router.get("", response_model=list[FarmRead])
async def list_farms(
    skip: int = 0,
    limit: int = 50,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if has_global_read_access(current_user):
        return await farm_repo.list_all_farms(db, skip, limit)
    return await farm_repo.list_farms_by_user(db, current_user.id, skip, limit)


@router.get("/{farm_id}", response_model=FarmRead)
async def get_farm(
    farm_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await _get_owned_farm(farm_id, db, current_user)


@router.patch("/{farm_id}", response_model=FarmRead)
async def update_farm(
    farm_id: uuid.UUID,
    payload: FarmUpdate,
    current_user: User = Depends(require_write_access),
    db: AsyncSession = Depends(get_db),
):
    farm = await _get_owned_farm(farm_id, db, current_user)

    update_data = payload.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(farm, field, value)
    return await farm_repo.update_farm(db, farm)


@router.delete("/{farm_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_farm(
    farm_id: uuid.UUID,
    current_user: User = Depends(require_write_access),
    db: AsyncSession = Depends(get_db),
):
    farm = await _get_owned_farm(farm_id, db, current_user)
    await farm_repo.delete_farm(db, farm)
