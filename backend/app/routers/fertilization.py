import uuid
from datetime import date

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import (
    get_current_user,
    has_global_read_access,
    require_write_access,
)
from app.db.session import get_db
from app.models import User
from app.repositories import fertilization_plan as fertilization_plan_repo
from app.repositories import lab_analysis as lab_analysis_repo
from app.repositories import parcel as parcel_repo
from app.repositories import reading as reading_repo
from app.repositories.agronomic_reference import (
    AgronomicReferenceNotFoundError,
    get_active_engine_config,
)
from app.schemas.fertilization import (
    FertilizationRecommendationRead,
    FertilizationRecommendationRequest,
)
from app.services.fertilization_service import (
    ENGINE_VERSION,
    FertilizationInputError,
    calculate_fertilization_recommendation,
    soil_assessment_from_lab_analysis,
)
from app.services.fertilization_fingerprint import (
    build_fertilization_input_fingerprint,
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


def _lab_analysis_fingerprint_data(analysis) -> dict:
    fields = (
        "ph",
        "ph_method",
        "ec",
        "ec_method",
        "organic_matter_pct",
        "cic",
        "clay_pct",
        "silt_pct",
        "sand_pct",
        "nitrogen",
        "phosphorus",
        "phosphorus_method",
        "potassium",
        "potassium_method",
        "calcium",
        "magnesium",
        "sulfur",
    )
    return {
        "id": analysis.id,
        **{field: getattr(analysis, field) for field in fields},
    }


@router.get(
    "/plans/latest",
    response_model=FertilizationRecommendationRead | None,
)
async def get_latest_plan(
    parcel_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    parcel = await parcel_repo.get_parcel(db, parcel_id)
    if parcel is None:
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
    plan = await fertilization_plan_repo.get_latest_fertilization_plan(
        db,
        parcel_id=parcel_id,
    )
    if plan is None:
        return None
    recommendation = FertilizationRecommendationRead.model_validate(
        plan.recommendation_snapshot
    )
    source_recorded_at = None
    if getattr(plan, "reading_id", None) is not None:
        reading = await reading_repo.get_reading(db, plan.reading_id)
        source_recorded_at = reading.recorded_at if reading is not None else None
    elif getattr(plan, "lab_analysis_id", None) is not None:
        analysis = await lab_analysis_repo.get_lab_analysis(db, plan.lab_analysis_id)
        if analysis is not None:
            source_recorded_at = analysis.sampled_at or analysis.recorded_at
    return recommendation.model_copy(
        update={
            "plan_id": plan.id,
            "source_type": getattr(plan, "method", None),
            "source_recorded_at": source_recorded_at,
        }
    )


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
        source_data = None
        source_recorded_at = None
        if payload.reading_id is not None:
            reading = await reading_repo.get_reading(db, payload.reading_id)
            if reading is None:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Sensor reading not found.",
                )
            if reading.parcel_id != parcel.id:
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail="The sensor reading does not belong to the parcel.",
                )
            source_data = {
                "id": reading.id,
                "nitrogen": reading.nitrogen,
                "phosphorus": reading.phosphorus,
                "potassium": reading.potassium,
                "ec": reading.ec,
                "ph": reading.ph,
                "temperature": reading.temperature,
                "humidity": reading.humidity,
            }
            source_recorded_at = reading.recorded_at
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
            source_data = _lab_analysis_fingerprint_data(analysis)
            source_recorded_at = analysis.sampled_at or analysis.recorded_at
        method = (
            "laboratory"
            if payload.lab_analysis_id is not None
            else payload.soil.source.value
        )
        plant_age_months = _age_in_months(parcel.planting_date, date.today())
        input_fingerprint = build_fertilization_input_fingerprint(
            {
                "engine_version": ENGINE_VERSION,
                "reference_set": {
                    "id": config.reference_set_id,
                    "key": config.reference_key,
                    "version": config.reference_version,
                },
                "parcel": {
                    "id": parcel.id,
                    "crop_id": parcel.crop_id,
                    "variety_id": parcel.variety.id,
                    "planting_date": parcel.planting_date,
                    "plant_age_months": plant_age_months,
                    "area_hectares": parcel.area_hectares,
                    "plants_per_hectare": parcel.plants_per_hectare,
                },
                "request": resolved_payload.model_dump(mode="json"),
                "source_data": source_data,
            }
        )
        existing_plan = (
            await fertilization_plan_repo.get_fertilization_plan_by_fingerprint(
                db,
                parcel_id=parcel.id,
                input_fingerprint=input_fingerprint,
            )
        )
        if existing_plan is not None:
            if existing_plan.recommendation_snapshot is None:
                raise RuntimeError(
                    "A fingerprinted fertilization plan has no recommendation snapshot."
                )
            cached = FertilizationRecommendationRead.model_validate(
                existing_plan.recommendation_snapshot
            )
            return cached.model_copy(
                update={
                    "plan_id": existing_plan.id,
                    "source_type": getattr(existing_plan, "method", method),
                    "source_recorded_at": source_recorded_at,
                }
            )
        recommendation = calculate_fertilization_recommendation(
            resolved_payload,
            config=config,
            crop_id=parcel.crop_id,
            variety_id=parcel.variety.id,
            crop_name=parcel.crop.name,
            variety_name=parcel.variety.name,
            plant_age_months=plant_age_months,
            area_hectares=parcel.area_hectares,
            plants_per_hectare=parcel.plants_per_hectare,
        )
        plan = await fertilization_plan_repo.create_fertilization_plan(
            db,
            recommendation=recommendation,
            config=config,
            method=method,
            input_fingerprint=input_fingerprint,
            reading_id=payload.reading_id,
            lab_analysis_id=payload.lab_analysis_id,
        )
        persisted = FertilizationRecommendationRead.model_validate(
            plan.recommendation_snapshot
        )
        return persisted.model_copy(
            update={
                "plan_id": plan.id,
                "source_type": method,
                "source_recorded_at": source_recorded_at,
            }
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
