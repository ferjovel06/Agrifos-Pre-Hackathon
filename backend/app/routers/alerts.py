import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import (
    get_current_user,
    has_global_read_access,
    require_write_access,
)
from app.db.session import get_db
from app.integrations.weather_provider import (
    WeatherProviderRateLimited,
    WeatherProviderTimeout,
    WeatherProviderUnavailable,
)
from app.models import Farm, User
from app.repositories import alert as alert_repo
from app.repositories import farm as farm_repo
from app.schemas.alert import AlertEvaluationRead, AlertRead
from app.services.climate_alert_service import evaluate_climate_alerts
from app.services.weather_service import InvalidWeatherDataError, WeatherService


router = APIRouter(prefix="/alerts", tags=["alerts"])


def get_weather_service() -> WeatherService:
    return WeatherService()


async def _get_owned_farm(
    farm_id: uuid.UUID,
    db: AsyncSession,
    current_user: User,
) -> Farm:
    farm = await farm_repo.get_farm(db, farm_id)
    if not farm:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Farm not found.",
        )
    if (
        farm.user_id != current_user.id
        and not has_global_read_access(current_user)
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions.",
        )
    return farm


@router.post(
    "/farms/{farm_id}/evaluate",
    response_model=AlertEvaluationRead,
)
async def evaluate_farm_alerts(
    farm_id: uuid.UUID,
    days: int = Query(default=7, ge=2, le=16),
    current_user: User = Depends(require_write_access),
    db: AsyncSession = Depends(get_db),
    weather_service: WeatherService = Depends(get_weather_service),
):
    farm = await _get_owned_farm(farm_id, db, current_user)
    try:
        forecast = await weather_service.forecast(farm, days)
    except WeatherProviderRateLimited as error:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="El servicio climático alcanzó su límite temporal. Intenta en unos minutos.",
        ) from error
    except WeatherProviderTimeout as error:
        raise HTTPException(
            status_code=status.HTTP_504_GATEWAY_TIMEOUT,
            detail="El servicio meteorológico tardó demasiado en responder.",
        ) from error
    except (WeatherProviderUnavailable, InvalidWeatherDataError) as error:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="No se pudieron evaluar las alertas climáticas.",
        ) from error

    candidates = evaluate_climate_alerts(farm, forecast)
    alerts = await alert_repo.sync_weather_alerts(db, farm.id, candidates)
    return AlertEvaluationRead(
        farm_id=farm.id,
        evaluated_days=days,
        active_alerts=alerts,
    )


@router.get("/farms/{farm_id}", response_model=list[AlertRead])
async def list_farm_alerts(
    farm_id: uuid.UUID,
    active_only: bool = Query(default=True),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    farm = await _get_owned_farm(farm_id, db, current_user)
    return await alert_repo.list_farm_alerts(db, farm.id, active_only)
