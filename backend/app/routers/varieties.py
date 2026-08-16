import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.core.auth import get_current_user, require_role
from app.models import User, Variety
from app.schemas.variety import VarietyCreate, VarietyUpdate, VarietyRead
from app.repositories import variety as variety_repo
from app.repositories import crop as crop_repo

router = APIRouter(prefix="/varieties", tags=["varieties"])


async def _get_variety_or_404(variety_id: uuid.UUID, db: AsyncSession) -> Variety:
    variety = await variety_repo.get_variety(db, variety_id)
    if not variety:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Variety not found.")
    return variety


async def _validate_crop_exists(crop_id: uuid.UUID, db: AsyncSession) -> None:
    crop = await crop_repo.get_crop(db, crop_id)
    if not crop:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Crop not found.")


@router.post("", response_model=VarietyRead, status_code=status.HTTP_201_CREATED)
async def create_variety(
    payload: VarietyCreate,
    _admin: User = Depends(require_role("admin")),
    db: AsyncSession = Depends(get_db),
):
    await _validate_crop_exists(payload.crop_id, db)
    variety = Variety(**payload.model_dump())
    return await variety_repo.create_variety(db, variety)


@router.get("", response_model=list[VarietyRead])
async def list_varieties(
    crop_id: uuid.UUID | None = None,
    skip: int = 0,
    limit: int = 50,
    _user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await variety_repo.list_varieties(db, crop_id, skip, limit)


@router.get("/{variety_id}", response_model=VarietyRead)
async def get_variety(
    variety_id: uuid.UUID,
    _user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await _get_variety_or_404(variety_id, db)


@router.patch("/{variety_id}", response_model=VarietyRead)
async def update_variety(
    variety_id: uuid.UUID,
    payload: VarietyUpdate,
    _admin: User = Depends(require_role("admin")),
    db: AsyncSession = Depends(get_db),
):
    variety = await _get_variety_or_404(variety_id, db)

    update_data = payload.model_dump(exclude_unset=True)
    if "crop_id" in update_data:
        await _validate_crop_exists(update_data["crop_id"], db)

    for field, value in update_data.items():
        setattr(variety, field, value)
    return await variety_repo.update_variety(db, variety)


@router.delete("/{variety_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_variety(
    variety_id: uuid.UUID,
    _admin: User = Depends(require_role("admin")),
    db: AsyncSession = Depends(get_db),
):
    variety = await _get_variety_or_404(variety_id, db)
    await variety_repo.delete_variety(db, variety)