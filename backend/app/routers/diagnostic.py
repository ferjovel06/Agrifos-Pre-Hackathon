import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import get_current_user, has_global_read_access
from app.db.session import get_db
from app.models import User
from app.repositories import parcel as parcel_repo
from app.repositories import reading as reading_repo
from app.repositories.agronomic_reference import (
    AgronomicReferenceNotFoundError,
    get_active_engine_config,
)
from app.schemas.diagnostic import SensorDiagnosticRead
from app.services.diagnostic_service import (
    InvalidDiagnosticReadingError,
    diagnose_sensor_reading,
)
from app.services.agronomic_config import IncompleteAgronomicConfigError


router = APIRouter(prefix="/diagnostics", tags=["diagnostics"])


@router.get("/readings/{reading_id}", response_model=SensorDiagnosticRead)
async def diagnose_reading(
    reading_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    reading = await reading_repo.get_reading(db, reading_id)
    if not reading:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reading not found.",
        )

    parcel = await parcel_repo.get_parcel(db, reading.parcel_id)
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

    try:
        config = await get_active_engine_config(db, parcel.crop_id)
        return diagnose_sensor_reading(reading, parcel.crop.name, config)
    except InvalidDiagnosticReadingError as error:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(error),
        ) from error
    except (AgronomicReferenceNotFoundError, IncompleteAgronomicConfigError) as error:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(error),
        ) from error
