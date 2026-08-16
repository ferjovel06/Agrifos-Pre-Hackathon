import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.core.auth import get_current_user, require_role
from app.models import User, Crop
from app.schemas.crop import CropCreate, CropUpdate, CropRead
from app.repositories import crop as crop_repo

router = APIRouter(prefix="/crops", tags=["crops"])


async def _get_crop_or_404(crop_id: uuid.UUID, db: AsyncSession) -> Crop:
    crop = await crop_repo.get_crop(db, crop_id)
    if not crop:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Crop not found.")
    return crop


@router.post("", response_model=CropRead, status_code=status.HTTP_201_CREATED)
async def create_crop(
    payload: CropCreate,
    _admin: User = Depends(require_role("admin")),
    db: AsyncSession = Depends(get_db),
):
    crop = Crop(**payload.model_dump())
    try:
        return await crop_repo.create_crop(db, crop)
    except IntegrityError:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="A crop with this name already exists.",
        )


@router.get("", response_model=list[CropRead])
async def list_crops(
    skip: int = 0,
    limit: int = 50,
    _user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await crop_repo.list_crops(db, skip, limit)


@router.get("/{crop_id}", response_model=CropRead)
async def get_crop(
    crop_id: uuid.UUID,
    _user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await _get_crop_or_404(crop_id, db)


@router.patch("/{crop_id}", response_model=CropRead)
async def update_crop(
    crop_id: uuid.UUID,
    payload: CropUpdate,
    _admin: User = Depends(require_role("admin")),
    db: AsyncSession = Depends(get_db),
):
    crop = await _get_crop_or_404(crop_id, db)

    update_data = payload.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(crop, field, value)

    try:
        return await crop_repo.update_crop(db, crop)
    except IntegrityError:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="A crop with this name already exists.",
        )


@router.delete("/{crop_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_crop(
    crop_id: uuid.UUID,
    _admin: User = Depends(require_role("admin")),
    db: AsyncSession = Depends(get_db),
):
    crop = await _get_crop_or_404(crop_id, db)
    try:
        await crop_repo.delete_crop(db, crop)
    except IntegrityError:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Cannot delete a crop that is still referenced by parcels or varieties.",
        )