from datetime import date

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import has_global_read_access, require_write_access
from app.db.session import get_db
from app.models import User
from app.repositories import parcel as parcel_repo
from app.schemas.fertilization import (
    FertilizationRecommendationRead,
    FertilizationRecommendationRequest,
)
from app.services.fertilization_service import (
    FertilizationInputError,
    calculate_fertilization_recommendation,
)


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
        return calculate_fertilization_recommendation(
            payload,
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
