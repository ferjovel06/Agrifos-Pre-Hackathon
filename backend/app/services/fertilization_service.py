import math
import unicodedata
from dataclasses import dataclass

from app.schemas.fertilization import (
    ApplicationRead,
    FertilizationRecommendationRead,
    FertilizationRecommendationRequest,
    FertilizerScenarioRead,
    FruitStage,
    LifeStage,
    NutrientRequirementRead,
    NutrientStatus,
    ProductDoseRead,
    SoilSource,
    YieldUnit,
)


ENGINE_VERSION = "coffee-fertilization-1.0.0"
RECOMMENDATION_STATUS = "decision_support"

_SUPPORTED_COFFEE_NAMES = {
    "cafe",
    "cafe arabica",
    "coffea arabica",
    "coffee",
}

_EXTRACTION_PER_1000_KG_GREEN = {
    "N": 30.9,
    "P2O5": 2.3 * 2.291,
    "K2O": 36.9 * 1.205,
}

_SOIL_CREDIT_RATIOS = {
    NutrientStatus.DEFICIENT: 0.0,
    NutrientStatus.PROBABLE_RESPONSE: 0.25,
    NutrientStatus.ADEQUATE: 1.0,
    NutrientStatus.HIGH: 1.10,
}

_APPLICATION_MOMENTS = (
    ("Prefloración / inicio de lluvias", 0.25),
    ("Cuajado y expansión inicial", 0.30),
    ("Llenado", 0.30),
    ("Postcosecha / recuperación", 0.15),
)


class FertilizationInputError(ValueError):
    pass


@dataclass(frozen=True)
class _Product:
    name: str
    n: float = 0
    p2o5: float = 0
    k2o: float = 0


_PRODUCTS = {
    "urea": _Product("Urea", n=0.46),
    "dap": _Product("DAP", n=0.18, p2o5=0.46),
    "map": _Product("MAP", n=0.11, p2o5=0.52),
    "tsp": _Product("TSP", p2o5=0.46),
    "kcl": _Product("KCl", k2o=0.60),
    "potassium_sulfate": _Product("Sulfato de potasio", k2o=0.50),
}


def _round(value: float) -> float:
    return round(value, 2)


def _normalize_name(value: str) -> str:
    normalized = unicodedata.normalize("NFKD", value.strip().lower())
    return "".join(char for char in normalized if not unicodedata.combining(char))


def _life_stage(age_months: int) -> LifeStage:
    if age_months <= 8:
        return LifeStage.NURSERY
    if age_months <= 12:
        return LifeStage.ESTABLISHMENT
    if age_months <= 24:
        return LifeStage.VEGETATIVE_GROWTH
    if age_months <= 48:
        return LifeStage.INITIAL_PRODUCTION
    return LifeStage.STABLE_PRODUCTION


def _target_green_kg_ha(request: FertilizationRecommendationRequest) -> float:
    parameters = request.parameters
    if request.yield_unit == YieldUnit.KG_GREEN_HA:
        return request.target_yield
    if request.yield_unit == YieldUnit.QQ_GOLD_HA:
        return request.target_yield * parameters.kg_per_qq_gold
    return (
        request.target_yield
        * parameters.kg_per_qq_gold
        / parameters.cherry_to_green_factor
    )


def _nutrient_requirements(
    request: FertilizationRecommendationRequest,
    target_green_kg_ha: float,
) -> list[NutrientRequirementRead]:
    statuses = {
        "N": request.soil.nitrogen,
        "P2O5": request.soil.phosphorus,
        "K2O": request.soil.potassium,
    }
    efficiencies = {
        "N": request.parameters.nitrogen_efficiency,
        "P2O5": request.parameters.phosphorus_efficiency,
        "K2O": request.parameters.potassium_efficiency,
    }

    requirements: list[NutrientRequirementRead] = []
    for nutrient, coefficient in _EXTRACTION_PER_1000_KG_GREEN.items():
        exported = target_green_kg_ha / 1000 * coefficient
        demand = exported * (1 + request.parameters.maintenance_factor)
        status = statuses[nutrient]
        credit = exported * _SOIL_CREDIT_RATIOS[status]
        required = max(0.0, demand - credit) / efficiencies[nutrient]
        if status == NutrientStatus.HIGH:
            required = 0.0

        requirements.append(
            NutrientRequirementRead(
                nutrient=nutrient,
                unit="kg/ha",
                exported_kg_ha=_round(exported),
                total_demand_kg_ha=_round(demand),
                soil_credit_kg_ha=_round(credit),
                fertilizer_requirement_kg_ha=_round(required),
                soil_status=status,
            )
        )
    return requirements


def _dose_read(
    product: _Product,
    kg_ha: float,
    hectares_per_manzana: float,
    plants_per_hectare: int,
) -> ProductDoseRead:
    contributions = {
        nutrient: _round(kg_ha * fraction)
        for nutrient, fraction in {
            "N": product.n,
            "P2O5": product.p2o5,
            "K2O": product.k2o,
        }.items()
        if fraction > 0
    }
    return ProductDoseRead(
        product=product.name,
        kg_ha=_round(kg_ha),
        kg_manzana=_round(kg_ha * hectares_per_manzana),
        g_plant=_round(kg_ha * 1000 / plants_per_hectare),
        nutrient_contributions_kg_ha=contributions,
    )


def _select_products(
    requirements: dict[str, float],
    *,
    low_chloride: bool,
    hectares_per_manzana: float,
    plants_per_hectare: int,
) -> list[ProductDoseRead]:
    remaining_n = requirements["N"]
    products: list[ProductDoseRead] = []

    phosphorus_required = requirements["P2O5"]
    if phosphorus_required > 0:
        preferred = _PRODUCTS["map" if low_chloride else "dap"]
        preferred_dose = phosphorus_required / preferred.p2o5
        if preferred_dose * preferred.n > remaining_n:
            preferred = _PRODUCTS["tsp"]
            preferred_dose = phosphorus_required / preferred.p2o5
        products.append(
            _dose_read(
                preferred,
                preferred_dose,
                hectares_per_manzana,
                plants_per_hectare,
            )
        )
        remaining_n = max(0.0, remaining_n - preferred_dose * preferred.n)

    potassium_required = requirements["K2O"]
    if potassium_required > 0:
        potassium_product = _PRODUCTS[
            "potassium_sulfate" if low_chloride else "kcl"
        ]
        products.append(
            _dose_read(
                potassium_product,
                potassium_required / potassium_product.k2o,
                hectares_per_manzana,
                plants_per_hectare,
            )
        )

    if remaining_n > 0:
        urea = _PRODUCTS["urea"]
        products.append(
            _dose_read(
                urea,
                remaining_n / urea.n,
                hectares_per_manzana,
                plants_per_hectare,
            )
        )

    return products


def _scenario_is_valid(
    products: list[ProductDoseRead], requirements: dict[str, float]
) -> bool:
    supplied = {"N": 0.0, "P2O5": 0.0, "K2O": 0.0}
    for product in products:
        for nutrient, amount in product.nutrient_contributions_kg_ha.items():
            supplied[nutrient] += amount
    return all(supplied[nutrient] + 0.02 >= required for nutrient, required in requirements.items())


def _application_schedule(
    products: list[ProductDoseRead],
    total_n_kg_ha: float,
    request: FertilizationRecommendationRequest,
    plants_per_hectare: int,
) -> list[ApplicationRead]:
    if not products:
        return []

    fractions: list[tuple[str, float]] = []
    for moment, moment_fraction in _APPLICATION_MOMENTS:
        moment_n = total_n_kg_ha * moment_fraction
        split_count = max(
            1,
            math.ceil(
                moment_n / request.parameters.max_n_kg_ha_per_application
            ),
        )
        for split_index in range(split_count):
            label = moment
            if split_count > 1:
                label = f"{moment} ({split_index + 1}/{split_count})"
            fractions.append((label, moment_fraction / split_count))

    schedule: list[ApplicationRead] = []
    for index, (moment, fraction) in enumerate(fractions):
        application_products = [
            ProductDoseRead(
                product=product.product,
                kg_ha=_round(product.kg_ha * fraction),
                kg_manzana=_round(product.kg_manzana * fraction),
                g_plant=_round(product.g_plant * fraction),
                nutrient_contributions_kg_ha={
                    nutrient: _round(amount * fraction)
                    for nutrient, amount in product.nutrient_contributions_kg_ha.items()
                },
            )
            for product in products
        ]
        schedule.append(
            ApplicationRead(
                application_number=index + 1,
                moment=moment,
                fraction=_round(fraction),
                products=application_products,
            )
        )
    return schedule


def _build_scenario(
    name: str,
    requirements: dict[str, float],
    *,
    low_chloride: bool,
    request: FertilizationRecommendationRequest,
    plants_per_hectare: int,
) -> FertilizerScenarioRead:
    products = _select_products(
        requirements,
        low_chloride=low_chloride,
        hectares_per_manzana=request.parameters.hectares_per_manzana,
        plants_per_hectare=plants_per_hectare,
    )
    return FertilizerScenarioRead(
        name=name,
        selection_method="bounded_greedy_v1",
        is_mathematically_valid=_scenario_is_valid(products, requirements),
        products=products,
        application_schedule=_application_schedule(
            products,
            requirements["N"],
            request,
            plants_per_hectare,
        ),
    )


def calculate_fertilization_recommendation(
    request: FertilizationRecommendationRequest,
    *,
    crop_name: str,
    variety_name: str,
    plant_age_months: int,
    area_hectares: float,
    plants_per_hectare: int,
) -> FertilizationRecommendationRead:
    if _normalize_name(crop_name) not in _SUPPORTED_COFFEE_NAMES:
        raise FertilizationInputError(
            f"Fertilization is not configured for crop '{crop_name}'."
        )
    if not variety_name.strip():
        raise FertilizationInputError("A registered variety is required.")
    if area_hectares <= 0:
        raise FertilizationInputError("Parcel area must be greater than zero.")
    if plants_per_hectare <= 0:
        raise FertilizationInputError("Plants per hectare must be greater than zero.")
    if request.soil.source == SoilSource.SENSOR:
        raise FertilizationInputError(
            "A sensor-only diagnosis cannot generate a full fertilizer dose."
        )

    life_stage = _life_stage(plant_age_months)
    if plant_age_months < 25:
        raise FertilizationInputError(
            "The production-yield engine requires a crop age of at least 25 months."
        )
    if request.soil.ec_ds_m is not None and request.soil.ec_ds_m >= 1.1:
        raise FertilizationInputError(
            "Electrical conductivity is too high for an automatic fertilizer plan."
        )

    target_green_kg_ha = _target_green_kg_ha(request)
    nutrient_rows = _nutrient_requirements(request, target_green_kg_ha)
    requirements = {
        row.nutrient: row.fertilizer_requirement_kg_ha for row in nutrient_rows
    }
    high_ec = request.soil.ec_ds_m is not None and request.soil.ec_ds_m >= 0.8

    base_scenario_name = "Bajo cloruro" if high_ec else "Económico"
    scenarios = [
        _build_scenario(
            base_scenario_name,
            requirements,
            low_chloride=high_ec,
            request=request,
            plants_per_hectare=plants_per_hectare,
        )
    ]
    if not high_ec and requirements["K2O"] > 0:
        scenarios.append(
            _build_scenario(
                "Bajo cloruro",
                requirements,
                low_chloride=True,
                request=request,
                plants_per_hectare=plants_per_hectare,
            )
        )

    warnings = [
        "Recomendación de apoyo a decisiones basada en parámetros regionales transferidos.",
        "La selección de productos es heurística hasta configurar precios y disponibilidad local.",
        "Verificar el grado garantizado de cada producto antes de aplicar el plan.",
        "Ajustar las fechas de aplicación a la lluvia, humedad y etapa observada en campo.",
    ]
    if high_ec:
        warnings.append(
            "Conductividad eléctrica elevada; se excluyó KCl y se priorizó bajo cloruro."
        )
    if (
        request.soil.ph is not None
        and request.soil.ph < 5
        and not request.soil.acidity_reserve_available
    ):
        warnings.append(
            "pH ácido sin acidez de reserva; el plan no incluye recomendación de cal."
        )

    limiting = [
        nutrient
        for nutrient, status in {
            "N": request.soil.nitrogen,
            "P": request.soil.phosphorus,
            "K": request.soil.potassium,
        }.items()
        if status in {NutrientStatus.DEFICIENT, NutrientStatus.PROBABLE_RESPONSE}
    ]
    assumptions = [
        f"Rendimiento convertido a {_round(target_green_kg_ha)} kg de café verde/ha.",
        f"Factor de mantenimiento: {request.parameters.maintenance_factor}.",
        f"Área registrada: {area_hectares} ha; densidad: {plants_per_hectare} plantas/ha.",
        "Factor varietal: 1.00, pendiente de calibración local.",
        (
            "Eficiencias N/P/K: "
            f"{request.parameters.nitrogen_efficiency}/"
            f"{request.parameters.phosphorus_efficiency}/"
            f"{request.parameters.potassium_efficiency}."
        ),
        "Fuente de referencia: Informe_fenologia_y_motor_fertilizacion_cafe_APA7.",
    ]

    return FertilizationRecommendationRead(
        parcel_id=request.parcel_id,
        crop=crop_name,
        variety=variety_name,
        plant_age_months=plant_age_months,
        life_stage=life_stage,
        fruit_stage=request.fruit_stage,
        target_green_kg_ha=_round(target_green_kg_ha),
        engine_version=ENGINE_VERSION,
        recommendation_status=RECOMMENDATION_STATUS,
        nutrient_requirements=nutrient_rows,
        fertilizer_scenarios=scenarios,
        limiting_nutrients=limiting,
        warnings=warnings,
        assumptions=assumptions,
    )
