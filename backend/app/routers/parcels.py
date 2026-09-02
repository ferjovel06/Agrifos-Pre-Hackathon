import uuid
from datetime import date, datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.core.auth import (
    get_current_user,
    has_global_read_access,
    require_write_access,
)
from app.models import Parcel, ParcelPhenologicalStage, User
from app.schemas.parcel import (
    ParcelConfigurationUpdate,
    ParcelCreate,
    ParcelRead,
    ParcelUpdate,
)
from app.repositories import parcel as parcel_repo
from app.repositories import farm as farm_repo
from app.repositories import phenology as stage_repo
from app.repositories import variety as variety_repo

router = APIRouter(prefix="/parcels", tags=["parcels"])


async def _get_owned_farm_or_403(farm_id: uuid.UUID, db: AsyncSession, current_user: User):
    farm = await farm_repo.get_farm(db, farm_id)
    if not farm:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Farm not found.")
    if (
        farm.user_id != current_user.id
        and not has_global_read_access(current_user)
    ):
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
    current_user: User = Depends(require_write_access),
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

    if has_global_read_access(current_user):
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
    current_user: User = Depends(require_write_access),
    db: AsyncSession = Depends(get_db),
):
    parcel = await _get_owned_parcel(parcel_id, db, current_user)

    update_data = payload.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(parcel, field, value)
    return await parcel_repo.update_parcel(db, parcel)


@router.patch("/{parcel_id}/configuration", response_model=ParcelRead)
async def update_parcel_configuration(
    parcel_id: uuid.UUID,
    payload: ParcelConfigurationUpdate,
    current_user: User = Depends(require_write_access),
    db: AsyncSession = Depends(get_db),
):
    parcel = await _get_owned_parcel(parcel_id, db, current_user)
    target_crop_id = payload.crop_id or parcel.crop_id
    target_variety_id = (
        payload.variety_id
        if "variety_id" in payload.model_fields_set
        else parcel.variety_id
    )

    template = await stage_repo.get_template(
        db, payload.phenological_stage_template_id
    )
    if not template:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Phenological stage template not found.",
        )
    if template.crop_id != target_crop_id:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="This stage belongs to a different crop than the parcel.",
        )

    if target_variety_id is not None:
        variety = await variety_repo.get_variety(db, target_variety_id)
        if not variety:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Variety not found.",
            )
        if variety.crop_id != target_crop_id:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="This variety belongs to a different crop than the parcel.",
            )

    instances = await stage_repo.list_instances(db, parcel.id)
    current_instance = max(
        instances,
        key=lambda instance: instance.selected_at,
        default=None,
    )

    try:
        update_data = payload.model_dump(
            exclude={"phenological_stage_template_id"},
            exclude_unset=True,
        )
        for field, value in update_data.items():
            setattr(parcel, field, value)

        if (
            current_instance is None
            or current_instance.template_id
            != payload.phenological_stage_template_id
        ):
            selected_instance = next(
                (
                    instance
                    for instance in instances
                    if instance.template_id
                    == payload.phenological_stage_template_id
                ),
                None,
            )
            selected_at = datetime.now(timezone.utc)
            if selected_instance is None:
                db.add(
                    ParcelPhenologicalStage(
                        parcel_id=parcel.id,
                        template_id=payload.phenological_stage_template_id,
                        actual_date=date.today(),
                        selected_at=selected_at,
                    )
                )
            else:
                selected_instance.actual_date = date.today()
                selected_instance.selected_at = selected_at

        await db.commit()
    except Exception:
        await db.rollback()
        raise
    await db.refresh(parcel)
    return parcel


@router.delete("/{parcel_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_parcel(
    parcel_id: uuid.UUID,
    current_user: User = Depends(require_write_access),
    db: AsyncSession = Depends(get_db),
):
    parcel = await _get_owned_parcel(parcel_id, db, current_user)
    await parcel_repo.delete_parcel(db, parcel)
