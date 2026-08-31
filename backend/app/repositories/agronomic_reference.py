import asyncio
import uuid
import weakref
from collections import OrderedDict, defaultdict
from collections.abc import Sequence
from dataclasses import dataclass
from time import monotonic

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models import (
    AgronomicParameter,
    AgronomicReferenceSet,
    ApplicationScheduleRule,
    EfficiencyFactor,
    ExtractionIndex,
    FertilizerProduct,
    SoilReferenceRange,
    Variety,
    VarietyFactor,
)
from app.services.agronomic_config import (
    AgronomicEngineConfig,
    ApplicationScheduleConfig,
    EfficiencyRangeConfig,
    FertilizerProductConfig,
    SoilRangeConfig,
    freeze_mapping,
    validate_engine_config,
)


DEFAULT_REFERENCE_KEY = "coffee-nicaragua"
ENGINE_CONFIG_CACHE_TTL_SECONDS = 300.0
ENGINE_CONFIG_CACHE_MAX_ENTRIES = 32


@dataclass(frozen=True)
class _CachedEngineConfig:
    config: AgronomicEngineConfig
    expires_at: float


_engine_config_cache: OrderedDict[
    tuple[uuid.UUID, str], _CachedEngineConfig
] = OrderedDict()
_cache_locks: weakref.WeakKeyDictionary[
    asyncio.AbstractEventLoop, asyncio.Lock
] = weakref.WeakKeyDictionary()


class AgronomicReferenceNotFoundError(LookupError):
    pass


async def get_active_engine_config(
    db: AsyncSession,
    crop_id: uuid.UUID,
    *,
    reference_key: str = DEFAULT_REFERENCE_KEY,
) -> AgronomicEngineConfig:
    cache_key = (crop_id, reference_key)
    cached = _get_cached_engine_config(cache_key)
    if cached is not None:
        return cached

    async with _get_cache_lock():
        cached = _get_cached_engine_config(cache_key)
        if cached is not None:
            return cached

        config = await _load_active_engine_config(
            db,
            crop_id,
            reference_key=reference_key,
        )
        _store_engine_config(cache_key, config)
        return config


def clear_engine_config_cache(
    *,
    crop_id: uuid.UUID | None = None,
    reference_key: str | None = None,
) -> None:
    """Invalidate cached reference data after an administrative update."""
    if crop_id is None and reference_key is None:
        _engine_config_cache.clear()
        return

    matching_keys = [
        key
        for key in _engine_config_cache
        if (crop_id is None or key[0] == crop_id)
        and (reference_key is None or key[1] == reference_key)
    ]
    for key in matching_keys:
        _engine_config_cache.pop(key, None)


def _get_cache_lock() -> asyncio.Lock:
    loop = asyncio.get_running_loop()
    lock = _cache_locks.get(loop)
    if lock is None:
        lock = asyncio.Lock()
        _cache_locks[loop] = lock
    return lock


def _get_cached_engine_config(
    cache_key: tuple[uuid.UUID, str],
) -> AgronomicEngineConfig | None:
    entry = _engine_config_cache.get(cache_key)
    if entry is None:
        return None
    if entry.expires_at <= monotonic():
        _engine_config_cache.pop(cache_key, None)
        return None
    _engine_config_cache.move_to_end(cache_key)
    return entry.config


def _store_engine_config(
    cache_key: tuple[uuid.UUID, str],
    config: AgronomicEngineConfig,
) -> None:
    now = monotonic()
    expired_keys = [
        key for key, entry in _engine_config_cache.items() if entry.expires_at <= now
    ]
    for key in expired_keys:
        _engine_config_cache.pop(key, None)

    _engine_config_cache[cache_key] = _CachedEngineConfig(
        config=config,
        expires_at=now + ENGINE_CONFIG_CACHE_TTL_SECONDS,
    )
    _engine_config_cache.move_to_end(cache_key)
    while len(_engine_config_cache) > ENGINE_CONFIG_CACHE_MAX_ENTRIES:
        _engine_config_cache.popitem(last=False)


async def _load_active_engine_config(
    db: AsyncSession,
    crop_id: uuid.UUID,
    *,
    reference_key: str,
) -> AgronomicEngineConfig:
    result = await db.execute(
        select(AgronomicReferenceSet).where(
            AgronomicReferenceSet.key == reference_key,
            AgronomicReferenceSet.is_active.is_(True),
        )
    )
    reference_set = result.scalar_one_or_none()
    if reference_set is None:
        raise AgronomicReferenceNotFoundError(
            f"No active agronomic reference dataset exists for '{reference_key}'."
        )

    reference_set_id = reference_set.id
    soil_ranges = list(
        (
            await db.execute(
                select(SoilReferenceRange).where(
                    SoilReferenceRange.reference_set_id == reference_set_id,
                    SoilReferenceRange.crop_id == crop_id,
                )
            )
        )
        .scalars()
        .all()
    )
    products = list(
        (
            await db.execute(
                select(FertilizerProduct)
                .options(selectinload(FertilizerProduct.nutrients))
                .where(
                    FertilizerProduct.reference_set_id == reference_set_id,
                    FertilizerProduct.is_active.is_(True),
                )
            )
        )
        .scalars()
        .all()
    )
    parameters = list(
        (
            await db.execute(
                select(AgronomicParameter).where(
                    AgronomicParameter.reference_set_id == reference_set_id,
                    AgronomicParameter.crop_id == crop_id,
                )
            )
        )
        .scalars()
        .all()
    )
    schedules = list(
        (
            await db.execute(
                select(ApplicationScheduleRule)
                .where(
                    ApplicationScheduleRule.reference_set_id == reference_set_id,
                    ApplicationScheduleRule.crop_id == crop_id,
                )
                .order_by(
                    ApplicationScheduleRule.life_stage,
                    ApplicationScheduleRule.sequence,
                )
            )
        )
        .scalars()
        .all()
    )
    extraction_indices = list(
        (
            await db.execute(
                select(ExtractionIndex).where(
                    ExtractionIndex.reference_set_id == reference_set_id,
                    ExtractionIndex.crop_id == crop_id,
                )
            )
        )
        .scalars()
        .all()
    )
    efficiency_factors = list(
        (
            await db.execute(
                select(EfficiencyFactor)
                .options(selectinload(EfficiencyFactor.soil_type))
                .where(EfficiencyFactor.reference_set_id == reference_set_id)
            )
        )
        .scalars()
        .all()
    )
    variety_factors = list(
        (
            await db.execute(
                select(VarietyFactor)
                .where(VarietyFactor.reference_set_id == reference_set_id)
                .join(VarietyFactor.variety)
                .where(Variety.crop_id == crop_id)
            )
        )
        .scalars()
        .all()
    )

    return build_engine_config(
        reference_set=reference_set,
        crop_id=crop_id,
        soil_ranges=soil_ranges,
        products=products,
        parameters=parameters,
        schedules=schedules,
        extraction_indices=extraction_indices,
        efficiency_factors=efficiency_factors,
        variety_factors=variety_factors,
    )


def build_engine_config(
    *,
    reference_set: AgronomicReferenceSet,
    crop_id: uuid.UUID,
    soil_ranges: Sequence[SoilReferenceRange],
    products: Sequence[FertilizerProduct],
    parameters: Sequence[AgronomicParameter],
    schedules: Sequence[ApplicationScheduleRule],
    extraction_indices: Sequence[ExtractionIndex],
    efficiency_factors: Sequence[EfficiencyFactor],
    variety_factors: Sequence[VarietyFactor],
) -> AgronomicEngineConfig:
    schedule_map: dict[str, list[ApplicationScheduleConfig]] = defaultdict(list)
    for rule in schedules:
        schedule_map[rule.life_stage].append(
            ApplicationScheduleConfig(
                sequence=rule.sequence,
                moment=rule.moment,
                month_after_planting=rule.month_after_planting,
                fraction=rule.fraction,
            )
        )

    variety_map: dict[uuid.UUID, dict[str, float]] = defaultdict(dict)
    for factor in variety_factors:
        variety_map[factor.variety_id][factor.nutrient] = factor.fv_factor

    config = AgronomicEngineConfig(
        reference_set_id=reference_set.id,
        reference_key=reference_set.key,
        reference_version=reference_set.version,
        reference_source=reference_set.source,
        crop_id=crop_id,
        soil_ranges=freeze_mapping(
            {
                row.parameter: SoilRangeConfig(
                    parameter=row.parameter,
                    label_es=row.label_es,
                    unit=row.unit,
                    method=row.method,
                    confidence=row.confidence,
                    deficient_below=row.deficient_below,
                    optimal_min=row.optimal_min,
                    optimal_max=row.optimal_max,
                    critical_above=row.critical_above,
                    high_is_generally_favorable=row.high_is_generally_favorable,
                    notes=row.notes,
                )
                for row in soil_ranges
            }
        ),
        products=freeze_mapping(
            {
                product.key: FertilizerProductConfig(
                    id=product.id,
                    key=product.key,
                    name=product.name,
                    is_low_chloride=product.is_low_chloride,
                    nutrients=freeze_mapping(
                        {
                            nutrient.nutrient: nutrient.fraction
                            for nutrient in product.nutrients
                        }
                    ),
                )
                for product in products
            }
        ),
        parameters=freeze_mapping({row.key: row.value for row in parameters}),
        parameter_units=freeze_mapping({row.key: row.unit for row in parameters}),
        schedules=freeze_mapping(
            {
                life_stage: tuple(sorted(rules, key=lambda rule: rule.sequence))
                for life_stage, rules in schedule_map.items()
            }
        ),
        extraction_indices=freeze_mapping(
            {row.nutrient: row.ie_value for row in extraction_indices}
        ),
        efficiency_ranges=freeze_mapping(
            {
                row.nutrient: EfficiencyRangeConfig(
                    soil_type=row.soil_type.name,
                    nutrient=row.nutrient,
                    minimum=row.ef_min,
                    maximum=row.ef_max,
                )
                for row in efficiency_factors
            }
        ),
        variety_factors=freeze_mapping(
            {
                variety_id: freeze_mapping(factors)
                for variety_id, factors in variety_map.items()
            }
        ),
    )
    validate_engine_config(config)
    return config
