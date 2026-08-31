import uuid
from dataclasses import dataclass
from types import MappingProxyType
from typing import Mapping, Sequence


REQUIRED_SOIL_PARAMETERS = frozenset(
    {
        "ph",
        "ec",
        "calcium",
        "magnesium",
        "sodium",
        "potassium",
        "zinc",
        "iron",
        "manganese",
        "copper",
        "nickel",
        "nitrate_n",
        "phosphate_p",
        "sulfate_s",
        "boron",
        "organic_matter",
        "clay",
        "silt",
        "sand",
        "nitrogen_total",
        "cic",
        "esp",
        "base_saturation_total",
        "ca_saturation",
        "mg_saturation",
        "k_saturation",
        "na_saturation",
    }
)

REQUIRED_PRODUCTS = frozenset(
    {"urea", "dap", "map", "tsp", "kcl", "potassium_sulfate", "mgo"}
)

REQUIRED_PARAMETERS = frozenset(
    {
        "maintenance_factor",
        "nitrogen_efficiency",
        "phosphorus_efficiency",
        "potassium_efficiency",
        "max_n_per_application",
        "kg_per_qq_gold",
        "cherry_to_green_factor",
        "hectares_per_manzana",
        "soil_credit_deficient",
        "soil_credit_probable_response",
        "soil_credit_adequate",
        "soil_credit_high",
        "ec_low_chloride_threshold",
        "ec_block_threshold",
        "young_urea_g_plant",
        "young_dap_g_plant",
        "young_kcl_g_plant",
        "young_mgo_g_plant",
    }
)

REQUIRED_EXTRACTION_INDICES = frozenset({"N", "P2O5", "K2O"})
REQUIRED_EFFICIENCY_RANGES = frozenset({"N", "P2O5", "K2O"})
REQUIRED_SCHEDULE_LENGTHS = MappingProxyType({"production": 4, "young_crop": 5})


class IncompleteAgronomicConfigError(ValueError):
    def __init__(self, missing: Sequence[str]):
        self.missing = tuple(sorted(missing))
        super().__init__(
            "The active agronomic reference dataset is incomplete: "
            + ", ".join(self.missing)
        )


@dataclass(frozen=True)
class SoilRangeConfig:
    parameter: str
    label_es: str
    unit: str
    method: str
    confidence: str
    deficient_below: float | None
    optimal_min: float | None
    optimal_max: float | None
    critical_above: float | None
    high_is_generally_favorable: bool
    notes: str


@dataclass(frozen=True)
class FertilizerProductConfig:
    id: uuid.UUID
    key: str
    name: str
    is_low_chloride: bool
    nutrients: Mapping[str, float]


@dataclass(frozen=True)
class ApplicationScheduleConfig:
    sequence: int
    moment: str
    month_after_planting: int | None
    fraction: float


@dataclass(frozen=True)
class EfficiencyRangeConfig:
    soil_type: str
    nutrient: str
    minimum: float
    maximum: float


@dataclass(frozen=True)
class AgronomicEngineConfig:
    reference_set_id: uuid.UUID
    reference_key: str
    reference_version: str
    reference_source: str
    crop_id: uuid.UUID
    soil_ranges: Mapping[str, SoilRangeConfig]
    products: Mapping[str, FertilizerProductConfig]
    parameters: Mapping[str, float]
    parameter_units: Mapping[str, str | None]
    schedules: Mapping[str, tuple[ApplicationScheduleConfig, ...]]
    extraction_indices: Mapping[str, float]
    efficiency_ranges: Mapping[str, EfficiencyRangeConfig]
    variety_factors: Mapping[uuid.UUID, Mapping[str, float]]


def freeze_mapping(values: dict) -> Mapping:
    return MappingProxyType(values)


def validate_engine_config(config: AgronomicEngineConfig) -> None:
    missing: list[str] = []
    missing.extend(
        f"soil_range:{key}"
        for key in sorted(REQUIRED_SOIL_PARAMETERS - config.soil_ranges.keys())
    )
    missing.extend(
        f"product:{key}" for key in sorted(REQUIRED_PRODUCTS - config.products.keys())
    )
    missing.extend(
        f"parameter:{key}"
        for key in sorted(REQUIRED_PARAMETERS - config.parameters.keys())
    )
    missing.extend(
        f"extraction_index:{key}"
        for key in sorted(
            REQUIRED_EXTRACTION_INDICES - config.extraction_indices.keys()
        )
    )
    missing.extend(
        f"efficiency_range:{key}"
        for key in sorted(
            REQUIRED_EFFICIENCY_RANGES - config.efficiency_ranges.keys()
        )
    )
    for life_stage, expected_length in REQUIRED_SCHEDULE_LENGTHS.items():
        actual_length = len(config.schedules.get(life_stage, ()))
        if actual_length != expected_length:
            missing.append(
                f"schedule:{life_stage}:expected_{expected_length}:found_{actual_length}"
            )
    for key, product in config.products.items():
        if not product.nutrients:
            missing.append(f"product_composition:{key}")
    if missing:
        raise IncompleteAgronomicConfigError(missing)
