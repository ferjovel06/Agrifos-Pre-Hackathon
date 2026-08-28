import logging
import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import get_current_user, has_global_read_access
from app.db.session import get_db
from app.integrations.weather_provider import (
    WeatherProviderRateLimited,
    WeatherProviderTimeout,
    WeatherProviderUnavailable,
)
from app.models import Farm, User
from app.repositories import farm as farm_repo
from app.schemas.weather import WeatherForecastRead
from app.services.weather_service import InvalidWeatherDataError, WeatherService


router = APIRouter(prefix="/weather", tags=["weather"])
logger = logging.getLogger(__name__)


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


@router.get("/farms/{farm_id}/forecast", response_model=WeatherForecastRead)
async def get_farm_forecast(
    farm_id: uuid.UUID,
    days: int = Query(default=7, ge=1, le=16),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    service: WeatherService = Depends(get_weather_service),
):
    farm = await _get_owned_farm(farm_id, db, current_user)
    try:
        return await service.forecast(farm, days)
    except WeatherProviderRateLimited as error:
        logger.warning(
            "Weather provider rate limit reached for farm %s: %s",
            farm_id,
            error,
        )
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="El servicio climático alcanzó su límite temporal. Intenta en unos minutos.",
        ) from error
    except WeatherProviderTimeout as error:
        logger.warning(
            "Weather provider timed out for farm %s: %s", farm_id, error
        )
        raise HTTPException(
            status_code=status.HTTP_504_GATEWAY_TIMEOUT,
            detail="El servicio meteorológico tardó demasiado en responder.",
        ) from error
    except (WeatherProviderUnavailable, InvalidWeatherDataError) as error:
        logger.warning(
            "Weather forecast failed for farm %s: %s", farm_id, error
        )
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="El pronóstico no está disponible temporalmente.",
        ) from error
