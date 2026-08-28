import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.core.auth import (
    get_current_user,
    has_global_read_access,
    require_role,
    require_write_access,
)
from app.models import User, PhenologicalStage
from app.schemas.phenology import (
    StageTemplateCreate,
    StageTemplateUpdate,
    StageTemplateRead,
    StageInstanceCreate,
    StageInstanceUpdate,
    StageInstanceRead,
)
from app.repositories import phenology as stage_repo
from app.repositories import crop as crop_repo
from app.repositories import parcel as parcel_repo
from app.repositories import farm as farm_repo

router = APIRouter(prefix="/phenological-stages", tags=["phenological-stages"])


# ---------- helpers ----------

async def _get_owned_parcel_or_403(parcel_id: uuid.UUID, db: AsyncSession, current_user: User):
    parcel = await parcel_repo.get_parcel(db, parcel_id)
    if not parcel:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Parcel not found.")
    farm = await farm_repo.get_farm(db, parcel.farm_id)
    if not farm or (
        farm.user_id != current_user.id
        and not has_global_read_access(current_user)
    ):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not enough permissions.")
    return parcel


async def _get_template_or_404(template_id: uuid.UUID, db: AsyncSession) -> PhenologicalStage:
    stage = await stage_repo.get_stage(db, template_id)
    if not stage or stage.parcel_id is not None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Template not found.")
    return stage


async def _get_owned_instance_or_403(
    instance_id: uuid.UUID, db: AsyncSession, current_user: User
) -> PhenologicalStage:
    stage = await stage_repo.get_stage(db, instance_id)
    if not stage or stage.parcel_id is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Stage instance not found.")
    await _get_owned_parcel_or_403(stage.parcel_id, db, current_user)
    return stage


# ---------- templates (crop catalog, write access restricted to admins) ----------

@router.post("/templates", response_model=StageTemplateRead, status_code=status.HTTP_201_CREATED)
async def create_template(
    payload: StageTemplateCreate,
    _admin: User = Depends(require_role("admin")),
    db: AsyncSession = Depends(get_db),
):
    crop = await crop_repo.get_crop(db, payload.crop_id)
    if not crop:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Crop not found.")

    stage = PhenologicalStage(parcel_id=None, template_id=None, **payload.model_dump())
    return await stage_repo.create_stage(db, stage)


@router.get("/templates", response_model=list[StageTemplateRead])
async def list_templates(
    crop_id: uuid.UUID | None = None,
    skip: int = 0,
    limit: int = 50,
    _user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await stage_repo.list_templates(db, crop_id, skip, limit)


@router.get("/templates/{template_id}", response_model=StageTemplateRead)
async def get_template(
    template_id: uuid.UUID,
    _user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await _get_template_or_404(template_id, db)


@router.patch("/templates/{template_id}", response_model=StageTemplateRead)
async def update_template(
    template_id: uuid.UUID,
    payload: StageTemplateUpdate,
    _admin: User = Depends(require_role("admin")),
    db: AsyncSession = Depends(get_db),
):
    template = await _get_template_or_404(template_id, db)
    update_data = payload.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(template, field, value)
    return await stage_repo.update_stage(db, template)


@router.delete("/templates/{template_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_template(
    template_id: uuid.UUID,
    _admin: User = Depends(require_role("admin")),
    db: AsyncSession = Depends(get_db),
):
    template = await _get_template_or_404(template_id, db)
    await stage_repo.delete_stage(db, template)



# ---------- instances (real stage of a parcel, owner or admin) ----------

@router.post("/instances", response_model=StageInstanceRead, status_code=status.HTTP_201_CREATED)
async def create_instance(
    payload: StageInstanceCreate,
    current_user: User = Depends(require_write_access),
    db: AsyncSession = Depends(get_db),
):
    parcel = await _get_owned_parcel_or_403(payload.parcel_id, db, current_user)
    template = await _get_template_or_404(payload.template_id, db)

    if template.crop_id != parcel.crop_id:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="This template belongs to a different crop than the parcel.",
        )

    instance = PhenologicalStage(
        parcel_id=parcel.id,
        template_id=template.id,
        crop_id=None,
        name=template.name,
        stage_order=template.stage_order,
        duration_days=template.duration_days,
        estimated_date=payload.estimated_date,
        actual_date=payload.actual_date,
    )
    return await stage_repo.create_stage(db, instance)


@router.get("/instances", response_model=list[StageInstanceRead])
async def list_instances(
    parcel_id: uuid.UUID,
    skip: int = 0,
    limit: int = 50,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _get_owned_parcel_or_403(parcel_id, db, current_user)
    return await stage_repo.list_instances(db, parcel_id, skip, limit)


@router.get("/instances/{instance_id}", response_model=StageInstanceRead)
async def get_instance(
    instance_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await _get_owned_instance_or_403(instance_id, db, current_user)


@router.patch("/instances/{instance_id}", response_model=StageInstanceRead)
async def update_instance(
    instance_id: uuid.UUID,
    payload: StageInstanceUpdate,
    current_user: User = Depends(require_write_access),
    db: AsyncSession = Depends(get_db),
):
    instance = await _get_owned_instance_or_403(instance_id, db, current_user)
    update_data = payload.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(instance, field, value)
    return await stage_repo.update_stage(db, instance)


@router.delete("/instances/{instance_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_instance(
    instance_id: uuid.UUID,
    current_user: User = Depends(require_write_access),
    db: AsyncSession = Depends(get_db),
):
    instance = await _get_owned_instance_or_403(instance_id, db, current_user)
    await stage_repo.delete_stage(db, instance)
