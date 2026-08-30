import math
import uuid

from app.models import LabAnalysis
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
    SoilAssessmentInput,
    SoilSource,
    YieldUnit,
)
from app.services.agronomic_config import (
    AgronomicEngineConfig,
    FertilizerProductConfig,
)


ENGINE_VERSION = "coffee-fertilization-1.0.0"
RECOMMENDATION_STATUS = "decision_support"

class FertilizationInputError(ValueError):
    pass


def _status_from_reference(
    value: float,
    *,
    deficient_below: float | None,
    optimal_min: float | None,
    optimal_max: float | None,
    critical_above: float | None,
) -> NutrientStatus:
    if deficient_below is not None and value < deficient_below:
        return NutrientStatus.DEFICIENT
    if critical_above is not None and value >= critical_above:
        return NutrientStatus.HIGH
    if optimal_max is not None and value > optimal_max:
        return NutrientStatus.HIGH
    if optimal_min is not None and value < optimal_min:
        return NutrientStatus.PROBABLE_RESPONSE
    return NutrientStatus.ADEQUATE


def soil_assessment_from_lab_analysis(
    analysis: LabAnalysis,
    config: AgronomicEngineConfig,
) -> SoilAssessmentInput:
    """Classify a stored laboratory analysis with the active reference set."""
    if not analysis.phosphorus_method or not analysis.potassium_method:
        raise FertilizationInputError(
            "The laboratory analysis requires phosphorus and potassium methods."
        )

    def classify(parameter: str, value: float) -> NutrientStatus:
        reference = config.soil_ranges[parameter]
        return _status_from_reference(
            value,
            deficient_below=reference.deficient_below,
            optimal_min=reference.optimal_min,
            optimal_max=reference.optimal_max,
            critical_above=reference.critical_above,
        )

    return SoilAssessmentInput(
        source=SoilSource.LABORATORY,
        nitrogen=classify("nitrogen_total", analysis.nitrogen),
        phosphorus=classify("phosphate_p", analysis.phosphorus),
        potassium=classify("potassium", analysis.potassium),
        phosphorus_method=analysis.phosphorus_method,
        potassium_method=analysis.potassium_method,
        ph=analysis.ph,
        ec_ds_m=analysis.ec,
    )


def _round(value: float) -> float:
    return round(value, 2)


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


def _target_green_kg_ha(
    request: FertilizationRecommendationRequest,
    config: AgronomicEngineConfig,
) -> float:
    if request.yield_unit == YieldUnit.KG_GREEN_HA:
        return request.target_yield
    if request.yield_unit == YieldUnit.QQ_GOLD_HA:
        return request.target_yield * config.parameters["kg_per_qq_gold"]
    return (
        request.target_yield
        * config.parameters["kg_per_qq_gold"]
        / config.parameters["cherry_to_green_factor"]
    )


def _nutrient_requirements(
    request: FertilizationRecommendationRequest,
    target_green_kg_ha: float,
    config: AgronomicEngineConfig,
    variety_id: uuid.UUID,
) -> list[NutrientRequirementRead]:
    statuses = {
        "N": request.soil.nitrogen,
        "P2O5": request.soil.phosphorus,
        "K2O": request.soil.potassium,
    }
    efficiencies = {
        "N": config.parameters["nitrogen_efficiency"],
        "P2O5": config.parameters["phosphorus_efficiency"],
        "K2O": config.parameters["potassium_efficiency"],
    }
    soil_credits = {
        NutrientStatus.DEFICIENT: config.parameters["soil_credit_deficient"],
        NutrientStatus.PROBABLE_RESPONSE: config.parameters[
            "soil_credit_probable_response"
        ],
        NutrientStatus.ADEQUATE: config.parameters["soil_credit_adequate"],
        NutrientStatus.HIGH: config.parameters["soil_credit_high"],
    }
    variety_factors = config.variety_factors.get(variety_id)
    if variety_factors is None:
        raise FertilizationInputError(
            "The selected variety has no factors in the active reference dataset."
        )

    requirements: list[NutrientRequirementRead] = []
    for nutrient, coefficient in config.extraction_indices.items():
        exported = target_green_kg_ha / 1000 * coefficient
        demand = (
            exported
            * (1 + config.parameters["maintenance_factor"])
            * variety_factors[nutrient]
        )
        status = statuses[nutrient]
        credit = exported * soil_credits[status]
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
    product: FertilizerProductConfig,
    kg_ha: float,
    hectares_per_manzana: float,
    plants_per_hectare: int,
) -> ProductDoseRead:
    contributions = {
        nutrient: _round(kg_ha * fraction)
        for nutrient, fraction in product.nutrients.items()
    }
    return ProductDoseRead(
        product=product.name,
        guaranteed_analysis_pct={
            nutrient: _round(fraction * 100)
            for nutrient, fraction in product.nutrients.items()
        },
        kg_ha=_round(kg_ha),
        kg_manzana=_round(kg_ha * hectares_per_manzana),
        g_plant=_round(kg_ha * 1000 / plants_per_hectare),
        nutrient_contributions_kg_ha=contributions,
    )


def _select_products(
    requirements: dict[str, float],
    *,
    config: AgronomicEngineConfig,
    low_chloride: bool,
    hectares_per_manzana: float,
    plants_per_hectare: int,
) -> list[ProductDoseRead]:
    remaining_n = requirements["N"]
    products: list[ProductDoseRead] = []

    phosphorus_required = requirements["P2O5"]
    if phosphorus_required > 0:
        preferred = config.products["map" if low_chloride else "dap"]
        preferred_p = preferred.nutrients["P2O5"]
        preferred_n = preferred.nutrients.get("N", 0)
        preferred_dose = phosphorus_required / preferred_p
        if preferred_dose * preferred_n > remaining_n:
            preferred = config.products["tsp"]
            preferred_p = preferred.nutrients["P2O5"]
            preferred_n = preferred.nutrients.get("N", 0)
            preferred_dose = phosphorus_required / preferred_p
        products.append(
            _dose_read(
                preferred,
                preferred_dose,
                hectares_per_manzana,
                plants_per_hectare,
            )
        )
        remaining_n = max(0.0, remaining_n - preferred_dose * preferred_n)

    potassium_required = requirements["K2O"]
    if potassium_required > 0:
        potassium_product = config.products[
            "potassium_sulfate" if low_chloride else "kcl"
        ]
        products.append(
            _dose_read(
                potassium_product,
                potassium_required / potassium_product.nutrients["K2O"],
                hectares_per_manzana,
                plants_per_hectare,
            )
        )

    if remaining_n > 0:
        urea = config.products["urea"]
        products.append(
            _dose_read(
                urea,
                remaining_n / urea.nutrients["N"],
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
            if nutrient in supplied:
                supplied[nutrient] += amount
    return all(supplied[nutrient] + 0.02 >= required for nutrient, required in requirements.items())


def _application_schedule(
    products: list[ProductDoseRead],
    total_n_kg_ha: float,
    config: AgronomicEngineConfig,
) -> list[ApplicationRead]:
    if not products:
        return []

    fractions: list[tuple[str, float]] = []
    for rule in config.schedules["production"]:
        moment = rule.moment
        moment_fraction = rule.fraction
        moment_n = total_n_kg_ha * moment_fraction
        split_count = max(
            1,
            math.ceil(moment_n / config.parameters["max_n_per_application"]),
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
                guaranteed_analysis_pct=product.guaranteed_analysis_pct,
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
    config: AgronomicEngineConfig,
    plants_per_hectare: int,
) -> FertilizerScenarioRead:
    products = _select_products(
        requirements,
        config=config,
        low_chloride=low_chloride,
        hectares_per_manzana=config.parameters["hectares_per_manzana"],
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
            config,
        ),
    )


def _young_crop_scenario(
    request: FertilizationRecommendationRequest,
    config: AgronomicEngineConfig,
    plants_per_hectare: int,
) -> tuple[FertilizerScenarioRead, list[NutrientRequirementRead]]:
    """Build the document's accumulated fallback plan for young coffee.

    The reference amounts are totals per plant distributed across months
    2, 6, 10, 14 and 18. They are deliberately kept separate from the
    production-by-yield calculation.
    """
    statuses = {
        "N": request.soil.nitrogen,
        "P2O5": request.soil.phosphorus,
        "K2O": request.soil.potassium,
        "MgO": NutrientStatus.PROBABLE_RESPONSE,
    }
    grams_per_plant = {
        "urea": config.parameters["young_urea_g_plant"],
        "dap": config.parameters["young_dap_g_plant"],
        "kcl": config.parameters["young_kcl_g_plant"],
        "mgo": config.parameters["young_mgo_g_plant"],
    }

    if statuses["N"] == NutrientStatus.HIGH:
        grams_per_plant.pop("urea")
        if "dap" in grams_per_plant:
            grams_per_plant["tsp"] = 15 / config.products["tsp"].nutrients["P2O5"]
            grams_per_plant.pop("dap")
    if statuses["P2O5"] == NutrientStatus.HIGH:
        grams_per_plant.pop("dap", None)
        grams_per_plant.pop("tsp", None)
        if statuses["N"] != NutrientStatus.HIGH:
            grams_per_plant["urea"] = 58 / config.products["urea"].nutrients["N"]
    if statuses["K2O"] == NutrientStatus.HIGH:
        grams_per_plant.pop("kcl", None)

    products = [
        _dose_read(
            config.products[product_key],
            grams * plants_per_hectare / 1000,
            config.parameters["hectares_per_manzana"],
            plants_per_hectare,
        )
        for product_key, grams in grams_per_plant.items()
    ]

    supplied = {"N": 0.0, "P2O5": 0.0, "K2O": 0.0, "MgO": 0.0}
    for product in products:
        for nutrient, amount in product.nutrient_contributions_kg_ha.items():
            if nutrient in supplied:
                supplied[nutrient] += amount

    requirements = [
        NutrientRequirementRead(
            nutrient=nutrient,
            unit="kg/ha",
            exported_kg_ha=0,
            total_demand_kg_ha=_round(amount),
            soil_credit_kg_ha=0,
            fertilizer_requirement_kg_ha=_round(amount),
            soil_status=statuses[nutrient],
        )
        for nutrient, amount in supplied.items()
    ]

    schedule = [
        ApplicationRead(
            application_number=index,
            moment=rule.moment,
            fraction=_round(rule.fraction),
            products=[
                ProductDoseRead(
                    product=product.product,
                    guaranteed_analysis_pct=product.guaranteed_analysis_pct,
                    kg_ha=_round(product.kg_ha * rule.fraction),
                    kg_manzana=_round(product.kg_manzana * rule.fraction),
                    g_plant=_round(product.g_plant * rule.fraction),
                    nutrient_contributions_kg_ha={
                        nutrient: _round(amount * rule.fraction)
                        for nutrient, amount in (
                            product.nutrient_contributions_kg_ha.items()
                        )
                    },
                )
                for product in products
            ],
        )
        for index, rule in enumerate(config.schedules["young_crop"], start=1)
    ]

    return (
        FertilizerScenarioRead(
            name="Plan de respaldo para levante",
            selection_method="young_crop_reference_v1",
            is_mathematically_valid=True,
            products=products,
            application_schedule=schedule,
        ),
        requirements,
    )


def calculate_fertilization_recommendation(
    request: FertilizationRecommendationRequest,
    *,
    config: AgronomicEngineConfig,
    crop_id: uuid.UUID,
    variety_id: uuid.UUID,
    crop_name: str,
    variety_name: str,
    plant_age_months: int,
    area_hectares: float,
    plants_per_hectare: int,
) -> FertilizationRecommendationRead:
    if request.soil is None:
        raise FertilizationInputError(
            "The request must be resolved to a soil assessment before calculation."
        )
    if config.crop_id != crop_id:
        raise FertilizationInputError(
            "The agronomic reference dataset does not belong to the parcel crop."
        )
    if not variety_name.strip():
        raise FertilizationInputError("A registered variety is required.")
    if variety_id not in config.variety_factors:
        raise FertilizationInputError(
            "The selected variety has no factors in the active reference dataset."
        )
    if area_hectares <= 0:
        raise FertilizationInputError("Parcel area must be greater than zero.")
    if plants_per_hectare <= 0:
        raise FertilizationInputError("Plants per hectare must be greater than zero.")
    life_stage = _life_stage(plant_age_months)
    if (
        request.soil.ec_ds_m is not None
        and request.soil.ec_ds_m >= config.parameters["ec_block_threshold"]
    ):
        raise FertilizationInputError(
            "Electrical conductivity is too high for an automatic fertilizer plan."
        )

    if plant_age_months < 25:
        young_scenario, nutrient_rows = _young_crop_scenario(
            request,
            config,
            plants_per_hectare,
        )
        limiting = [
            nutrient
            for nutrient, status in {
                "N": request.soil.nitrogen,
                "P": request.soil.phosphorus,
                "K": request.soil.potassium,
            }.items()
            if status
            in {NutrientStatus.DEFICIENT, NutrientStatus.PROBABLE_RESPONSE}
        ]
        return FertilizationRecommendationRead(
            parcel_id=request.parcel_id,
            crop=crop_name,
            variety=variety_name,
            plant_age_months=plant_age_months,
            life_stage=life_stage,
            fruit_stage=request.fruit_stage,
            target_green_kg_ha=0,
            engine_version=ENGINE_VERSION,
            recommendation_status="young_crop_reference",
            nutrient_requirements=nutrient_rows,
            fertilizer_scenarios=[young_scenario],
            limiting_nutrients=limiting,
            warnings=[
                "Plan general acumulado para levante; no es una receta universal.",
                "Revisar las aplicaciones ya realizadas antes de usar el plan.",
                "El plan se distribuye entre los meses 2, 6, 10, 14 y 18.",
            ],
            assumptions=[
                (
                    "Referencia de levante: "
                    f"{config.parameters['young_urea_g_plant']:g} g de urea, "
                    f"{config.parameters['young_dap_g_plant']:g} g de DAP, "
                    f"{config.parameters['young_kcl_g_plant']:g} g de KCl y "
                    f"{config.parameters['young_mgo_g_plant']:g} g de MgO "
                    "por planta acumulados."
                ),
                f"Densidad registrada: {plants_per_hectare} plantas/ha.",
                (
                    f"Referencia: {config.reference_key} v{config.reference_version}; "
                    f"fuente: {config.reference_source}."
                ),
            ],
        )

    target_green_kg_ha = _target_green_kg_ha(request, config)
    nutrient_rows = _nutrient_requirements(
        request,
        target_green_kg_ha,
        config,
        variety_id,
    )
    requirements = {
        row.nutrient: row.fertilizer_requirement_kg_ha for row in nutrient_rows
    }
    high_ec = (
        request.soil.ec_ds_m is not None
        and request.soil.ec_ds_m
        >= config.parameters["ec_low_chloride_threshold"]
    )

    base_scenario_name = "Bajo cloruro" if high_ec else "Económico"
    scenarios = [
        _build_scenario(
            base_scenario_name,
            requirements,
            low_chloride=high_ec,
            config=config,
            plants_per_hectare=plants_per_hectare,
        )
    ]
    if not high_ec and requirements["K2O"] > 0:
        scenarios.append(
            _build_scenario(
                "Bajo cloruro",
                requirements,
                low_chloride=True,
                config=config,
                plants_per_hectare=plants_per_hectare,
            )
        )

    warnings = [
        "Recomendación de apoyo a decisiones basada en parámetros regionales transferidos.",
        "La selección de productos es heurística hasta configurar precios y disponibilidad local.",
        "Verificar el grado garantizado de cada producto antes de aplicar el plan.",
        "Ajustar las fechas de aplicación a la lluvia, humedad y etapa observada en campo.",
    ]
    if request.soil.source == SoilSource.SENSOR:
        warnings.append(
            "Plan calculado con la clasificación de la lectura del sensor."
        )
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
        f"Factor de mantenimiento: {config.parameters['maintenance_factor']}.",
        f"Área registrada: {area_hectares} ha; densidad: {plants_per_hectare} plantas/ha.",
        "Factor varietal: 1.00, pendiente de calibración local.",
        (
            "Eficiencias N/P/K: "
            f"{config.parameters['nitrogen_efficiency']}/"
            f"{config.parameters['phosphorus_efficiency']}/"
            f"{config.parameters['potassium_efficiency']}."
        ),
        (
            f"Referencia: {config.reference_key} v{config.reference_version}; "
            f"fuente: {config.reference_source}."
        ),
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
