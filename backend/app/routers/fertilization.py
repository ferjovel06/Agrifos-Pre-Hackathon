from datetime import date

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import has_global_read_access, require_write_access
from app.db.session import get_db
from app.models import User
from app.repositories import lab_analysis as lab_analysis_repo
from app.repositories import parcel as parcel_repo
from app.repositories.agronomic_reference import (
    AgronomicReferenceNotFoundError,
    get_active_engine_config,
)
from app.schemas.fertilization import (
    FertilizationRecommendationRead,
    FertilizationRecommendationRequest,
)
from app.services.fertilization_service import (
    FertilizationInputError,
    calculate_fertilization_recommendation,
    soil_assessment_from_lab_analysis,
)
from app.services.agronomic_config import IncompleteAgronomicConfigError


router = APIRouter(prefix="/fertilization", tags=["fertilization"])


def _age_in_months(planting_date: date, today: date) -> int:
    months = (
        (today.year - planting_date.year) * 12
        + today.month
        - planting_date.month
    )
    if today.day < planting_date.day:
        months -= 1
    return max(0, months)


@router.post("/recommendations", response_model=FertilizationRecommendationRead)
async def create_recommendation(
    payload: FertilizationRecommendationRequest,
    current_user: User = Depends(require_write_access),
    db: AsyncSession = Depends(get_db),
):
    parcel = await parcel_repo.get_parcel(db, payload.parcel_id)
    if not parcel:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Parcel not found.",
        )
    if (
        not has_global_read_access(current_user)
        and parcel.farm.user_id != current_user.id
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions.",
        )
    if parcel.variety is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="The parcel must have a registered variety.",
        )
    if parcel.plants_per_hectare is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="The parcel must have plants_per_hectare configured.",
        )

    try:
        config = await get_active_engine_config(db, parcel.crop_id)
        resolved_payload = payload
        if payload.lab_analysis_id is not None:
            analysis = await lab_analysis_repo.get_lab_analysis(
                db,
                payload.lab_analysis_id,
            )
            if analysis is None:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Laboratory analysis not found.",
                )
            if analysis.parcel_id != parcel.id:
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail="The laboratory analysis does not belong to the parcel.",
                )
            resolved_payload = payload.model_copy(
                update={
                    "soil": soil_assessment_from_lab_analysis(analysis, config),
                    "lab_analysis_id": None,
                }
            )
        return calculate_fertilization_recommendation(
            resolved_payload,
            config=config,
            crop_id=parcel.crop_id,
            variety_id=parcel.variety.id,
            crop_name=parcel.crop.name,
            variety_name=parcel.variety.name,
            plant_age_months=_age_in_months(parcel.planting_date, date.today()),
            area_hectares=parcel.area_hectares,
            plants_per_hectare=parcel.plants_per_hectare,
        )
    except FertilizationInputError as error:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(error),
        ) from error
    except (AgronomicReferenceNotFoundError, IncompleteAgronomicConfigError) as error:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(error),
        ) from error
