import uuid

from app.services.agronomic_config import (
    AgronomicEngineConfig,
    ApplicationScheduleConfig,
    EfficiencyRangeConfig,
    FertilizerProductConfig,
    SoilRangeConfig,
    freeze_mapping,
)


CROP_ID = uuid.UUID("152b6e5d-b6e4-421c-8c52-f462a672b989")
VARIETY_ID = uuid.UUID("49232aed-2411-4a82-b13a-54d81f8a6624")


def make_engine_config() -> AgronomicEngineConfig:
    soil_values = {
        "nitrate_n": ("Nitrógeno", "mg/kg", 10, 10, 30, None),
        "nitrogen_total": ("Nitrógeno total", "mg/kg", 3400, 3400, 5800, None),
        "phosphate_p": ("Fósforo", "mg/kg", 10, 10, 20, None),
        "potassium": ("Potasio", "mg/kg", 78, 78, 156, None),
        "ec": ("Conductividad eléctrica", "dS/m", 0.1, 0.1, 0.8, 1.1),
        "ph": ("pH", "SU", 5.0, 5.0, 5.5, 6.0),
    }
    soil_ranges = freeze_mapping(
        {
            key: SoilRangeConfig(
                parameter=key,
                label_es=label,
                unit=unit,
                method="Documented test method",
                confidence="High",
                deficient_below=deficient,
                optimal_min=minimum,
                optimal_max=maximum,
                critical_above=critical,
                high_is_generally_favorable=False,
                notes="Test fixture",
            )
            for key, (label, unit, deficient, minimum, maximum, critical) in soil_values.items()
        }
    )
    product_values = {
        "urea": ("Urea", {"N": 0.46}),
        "dap": ("DAP", {"N": 0.18, "P2O5": 0.46}),
        "map": ("MAP", {"N": 0.11, "P2O5": 0.52}),
        "tsp": ("TSP", {"P2O5": 0.46, "Ca": 0.12}),
        "kcl": ("KCl", {"K2O": 0.60, "Cl": 0.47}),
        "potassium_sulfate": (
            "Sulfato de potasio",
            {"K2O": 0.50, "S": 0.18},
        ),
        "mgo": ("MgO", {"MgO": 1.0}),
    }
    products = freeze_mapping(
        {
            key: FertilizerProductConfig(
                key=key,
                name=name,
                is_low_chloride=key in {"map", "tsp", "potassium_sulfate", "mgo"},
                nutrients=freeze_mapping(nutrients),
            )
            for key, (name, nutrients) in product_values.items()
        }
    )
    parameters = freeze_mapping(
        {
            "maintenance_factor": 0.25,
            "nitrogen_efficiency": 0.50,
            "phosphorus_efficiency": 0.30,
            "potassium_efficiency": 0.65,
            "max_n_per_application": 40,
            "kg_per_qq_gold": 46,
            "cherry_to_green_factor": 5.0,
            "hectares_per_manzana": 0.7042,
            "soil_credit_deficient": 0.0,
            "soil_credit_probable_response": 0.25,
            "soil_credit_adequate": 1.0,
            "soil_credit_high": 1.10,
            "ec_low_chloride_threshold": 0.80,
            "ec_block_threshold": 1.10,
            "young_urea_g_plant": 114,
            "young_dap_g_plant": 33,
            "young_kcl_g_plant": 25,
            "young_mgo_g_plant": 5,
        }
    )
    production = tuple(
        ApplicationScheduleConfig(index, moment, None, fraction)
        for index, (moment, fraction) in enumerate(
            (
                ("Prefloración / inicio de lluvias", 0.25),
                ("Cuajado y expansión inicial", 0.30),
                ("Llenado", 0.30),
                ("Postcosecha / recuperación", 0.15),
            ),
            start=1,
        )
    )
    young_crop = tuple(
        ApplicationScheduleConfig(index, f"Mes {month} de levante", month, 0.20)
        for index, month in enumerate((2, 6, 10, 14, 18), start=1)
    )
    return AgronomicEngineConfig(
        reference_set_id=uuid.uuid4(),
        reference_key="coffee-nicaragua",
        reference_version="1.0.0",
        reference_source="test sources",
        crop_id=CROP_ID,
        soil_ranges=soil_ranges,
        products=products,
        parameters=parameters,
        parameter_units=freeze_mapping({key: None for key in parameters}),
        schedules=freeze_mapping(
            {"production": production, "young_crop": young_crop}
        ),
        extraction_indices=freeze_mapping(
            {"N": 30.9, "P2O5": 2.3 * 2.291, "K2O": 36.9 * 1.205}
        ),
        efficiency_ranges=freeze_mapping(
            {
                nutrient: EfficiencyRangeConfig(
                    "Regional reference", nutrient, minimum, maximum
                )
                for nutrient, minimum, maximum in (
                    ("N", 0.40, 0.60),
                    ("P2O5", 0.15, 0.30),
                    ("K2O", 0.60, 0.70),
                )
            }
        ),
        variety_factors=freeze_mapping(
            {
                VARIETY_ID: freeze_mapping(
                    {"N": 1.0, "P2O5": 1.0, "K2O": 1.0}
                )
            }
        ),
    )
