"""seed the documented coffee agronomic reference dataset

Revision ID: c42d9e18a6f1
Revises: b31f6a92c7d4
Create Date: 2026-08-30
"""

from typing import Sequence, Union
import uuid

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import insert as pg_insert


revision: str = "c42d9e18a6f1"
down_revision: Union[str, None] = "b31f6a92c7d4"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


REFERENCE_KEY = "coffee-nicaragua"
REFERENCE_VERSION = "1.0.0"
REFERENCE_ID = uuid.uuid5(uuid.NAMESPACE_URL, "agrifos:reference:coffee-nicaragua:1.0.0")
CROP_ID = uuid.uuid5(uuid.NAMESPACE_URL, "agrifos:crop:coffee")
SOIL_TYPE_ID = uuid.uuid5(uuid.NAMESPACE_URL, "agrifos:soil-type:regional-reference")


def _id(entity: str) -> uuid.UUID:
    return uuid.uuid5(uuid.NAMESPACE_URL, f"agrifos:{REFERENCE_KEY}:{REFERENCE_VERSION}:{entity}")


def _insert(table: sa.TableClause, rows: list[dict]) -> None:
    if rows:
        op.get_bind().execute(pg_insert(table).values(rows).on_conflict_do_nothing())


def upgrade() -> None:
    bind = op.get_bind()

    crops = sa.table(
        "crops",
        sa.column("id", sa.UUID()),
        sa.column("name", sa.String()),
    )
    crop_id = bind.execute(
        sa.select(crops.c.id)
        .where(sa.func.lower(crops.c.name).in_(("café", "cafe", "coffee", "coffea arabica")))
        .limit(1)
    ).scalar_one_or_none()
    if crop_id is None:
        _insert(crops, [{"id": CROP_ID, "name": "Café"}])
        crop_id = CROP_ID

    reference_sets = sa.table(
        "agronomic_reference_sets",
        sa.column("id", sa.UUID()),
        sa.column("key", sa.String()),
        sa.column("version", sa.String()),
        sa.column("source", sa.String()),
        sa.column("description", sa.Text()),
        sa.column("is_active", sa.Boolean()),
    )
    bind.execute(
        reference_sets.update()
        .where(reference_sets.c.key == REFERENCE_KEY)
        .values(is_active=False)
    )
    _insert(
        reference_sets,
        [
            {
                "id": REFERENCE_ID,
                "key": REFERENCE_KEY,
                "version": REFERENCE_VERSION,
                "source": (
                    "coffee_phenology_and_fertilization_engine.pdf; "
                    "coffee_soil_laboratory_parameters.pdf"
                ),
                "description": (
                    "Initial transferred reference dataset for coffee in Nicaragua; "
                    "values require local field calibration."
                ),
                "is_active": True,
            }
        ],
    )
    bind.execute(
        reference_sets.update()
        .where(reference_sets.c.id == REFERENCE_ID)
        .values(is_active=True)
    )

    _seed_soil_ranges(crop_id)
    _seed_products()
    _seed_parameters(crop_id)
    _seed_schedules(crop_id)
    _seed_existing_factor_tables(crop_id)


def _seed_soil_ranges(crop_id: uuid.UUID) -> None:
    table = sa.table(
        "soil_reference_ranges",
        sa.column("id", sa.UUID()),
        sa.column("reference_set_id", sa.UUID()),
        sa.column("crop_id", sa.UUID()),
        sa.column("parameter", sa.String()),
        sa.column("label_es", sa.String()),
        sa.column("unit", sa.String()),
        sa.column("method", sa.Text()),
        sa.column("confidence", sa.String()),
        sa.column("deficient_below", sa.Float()),
        sa.column("optimal_min", sa.Float()),
        sa.column("optimal_max", sa.Float()),
        sa.column("critical_above", sa.Float()),
        sa.column("high_is_generally_favorable", sa.Boolean()),
        sa.column("notes", sa.Text()),
    )
    values = [
        ("ph", "pH", "SU", "Potentiometric; preserve the soil-to-water ratio", "High", 5.0, 5.0, 5.5, 6.0, False, "Values above 5.5 require review; review especially above 6.0."),
        ("ec", "Conductividad eléctrica", "dS/m", "Saturated paste or documented soil-to-water ratio", "Medium", 0.10, 0.10, 0.80, 1.10, False, "Low EC is not a nutrient deficiency; values above 0.80 require monitoring."),
        ("calcium", "Calcio intercambiable", "mg/kg", "Ammonium acetate", "High", 301, 301, 601, None, True, "A high value does not imply toxicity by itself."),
        ("magnesium", "Magnesio intercambiable", "mg/kg", "Ammonium acetate", "High", 73, 73, 109, None, True, "Review the Ca:Mg ratio when high."),
        ("sodium", "Sodio intercambiable", "mg/kg", "Ammonium acetate", "Medium", None, 0, 100, 1000, False, "Use as a sodicity indicator; low values are favorable."),
        ("potassium", "Potasio intercambiable", "mg/kg", "Ammonium acetate", "High", 78, 78, 156, None, False, "Confirm the laboratory method when high."),
        ("zinc", "Zinc", "mg/kg", "DTPA or modified Olsen", "Medium", 1.5, 1.5, 3.0, None, False, "General reference; confirm the extraction method."),
        ("iron", "Hierro", "mg/kg", "DTPA or modified Olsen", "Medium", 25, 25, 50, None, False, "General reference dependent on pH, texture, and method."),
        ("manganese", "Manganeso", "mg/kg", "DTPA or modified Olsen", "Medium", 5, 5, 20, None, False, "General reference dependent on pH, texture, and method."),
        ("copper", "Cobre", "mg/kg", "DTPA or modified Olsen", "Medium", 1.0, 1.0, 3.0, None, False, "General reference; confirm the extraction method."),
        ("nickel", "Níquel", "mg/kg", "DTPA", "Low", None, 0, 1, None, False, "Environmental alert only; no established coffee deficiency threshold."),
        ("nitrate_n", "Nitrato-N", "mg/kg", "Cadmium reduction or documented colorimetric method", "Low", 10, 10, 30, None, False, "Immediate-availability indicator; not equivalent to total nitrogen."),
        ("phosphate_p", "Fosfato-P", "mg/kg", "Document whether elemental P, phosphate, Olsen, or Bray", "Medium-low", 10, 10, 20, None, False, "Method-dependent operational reference."),
        ("sulfate_s", "Sulfato-S", "mg/kg", "Document the laboratory extraction method", "Medium-low", 6, 6, 12, None, False, "Do not compare methods without validation."),
        ("boron", "Boro", "mg/kg", "Hot water", "Medium", 0.2, 0.2, 0.5, None, False, "Requires regional calibration."),
        ("organic_matter", "Materia orgánica", "%", "Combustion, Walkley-Black, or documented method", "High", 8, 8, 16, None, False, "Values above 16% are not automatically better."),
        ("clay", "Arcilla", "%", "Texture by hydrometer or documented method", "Medium", 20, 20, 40, None, False, "Orientative; review drainage and compaction above 40%."),
        ("silt", "Limo", "%", "Texture by hydrometer or documented method", "Medium", 20, 20, 50, None, False, "Orientative; review erosion and compaction above 50%."),
        ("sand", "Arena", "%", "Texture by hydrometer or documented method", "Medium", 30, 30, 60, None, False, "Orientative; high values imply lower water retention."),
        ("nitrogen_total", "Nitrógeno total", "mg/kg", "Kjeldahl or documented total-N method", "High", 3400, 3400, 5800, None, False, "Interpret high values together with organic matter."),
        ("cic", "CIC / CEC", "cmolc/kg", "Sum of bases or ammonium acetate at pH 7", "High", 15, 15, 25, None, True, "High CEC generally favors nutrient retention."),
        ("esp", "Porcentaje de sodio intercambiable (ESP)", "%", "Calculated as exchangeable Na divided by CEC times 100", "Medium", None, 0, 5, 15, False, "Values from 5% to 15% require monitoring; 15% or more is critical."),
        ("base_saturation_total", "Saturación de bases total", "%", "Calculated as total base cations divided by CEC times 100", "High", 20, 30, None, 80, True, "The 20% to 30% interval is undefined; review imbalances above 80%."),
        ("ca_saturation", "Saturación de calcio", "%", "Calculated as exchangeable Ca divided by CEC times 100", "Medium", 55, 55, 70, None, False, "Review competition with Mg and K above 70%."),
        ("mg_saturation", "Saturación de magnesio", "%", "Calculated as exchangeable Mg divided by CEC times 100", "Medium", 10, 10, 20, None, False, "Review cation competition above 20%."),
        ("k_saturation", "Saturación de potasio", "%", "Calculated as exchangeable K divided by CEC times 100", "Medium", 2, 2, 5, None, False, "Review balance with Ca and Mg above 5%."),
        ("na_saturation", "Saturación de sodio", "%", "Calculated as exchangeable Na divided by CEC times 100", "Medium", None, 0, 5, 15, False, "Values at or above 5% require monitoring; 15% or more is critical."),
    ]
    rows = [
        {
            "id": _id(f"soil-range:{parameter}"),
            "reference_set_id": REFERENCE_ID,
            "crop_id": crop_id,
            "parameter": parameter,
            "label_es": label,
            "unit": unit,
            "method": method,
            "confidence": confidence,
            "deficient_below": deficient,
            "optimal_min": minimum,
            "optimal_max": maximum,
            "critical_above": critical,
            "high_is_generally_favorable": favorable,
            "notes": notes,
        }
        for parameter, label, unit, method, confidence, deficient, minimum, maximum, critical, favorable, notes in values
    ]
    _insert(table, rows)


def _seed_products() -> None:
    products = sa.table(
        "fertilizer_products",
        sa.column("id", sa.UUID()),
        sa.column("reference_set_id", sa.UUID()),
        sa.column("key", sa.String()),
        sa.column("name", sa.String()),
        sa.column("is_low_chloride", sa.Boolean()),
        sa.column("is_active", sa.Boolean()),
    )
    nutrients = sa.table(
        "fertilizer_product_nutrients",
        sa.column("id", sa.UUID()),
        sa.column("product_id", sa.UUID()),
        sa.column("nutrient", sa.String()),
        sa.column("fraction", sa.Float()),
    )
    catalog = {
        "urea": ("Urea", False, {"N": 0.46}),
        "dap": ("DAP", False, {"N": 0.18, "P2O5": 0.46}),
        "map": ("MAP", True, {"N": 0.11, "P2O5": 0.52}),
        "tsp": ("TSP", True, {"P2O5": 0.46, "Ca": 0.12}),
        "kcl": ("KCl", False, {"K2O": 0.60, "Cl": 0.47}),
        "potassium_sulfate": ("Sulfato de potasio", True, {"K2O": 0.50, "S": 0.18}),
        "mgo": ("MgO", True, {"MgO": 1.0}),
    }
    product_rows = []
    nutrient_rows = []
    for key, (name, low_chloride, composition) in catalog.items():
        product_id = _id(f"product:{key}")
        product_rows.append(
            {
                "id": product_id,
                "reference_set_id": REFERENCE_ID,
                "key": key,
                "name": name,
                "is_low_chloride": low_chloride,
                "is_active": True,
            }
        )
        nutrient_rows.extend(
            {
                "id": _id(f"product:{key}:nutrient:{nutrient}"),
                "product_id": product_id,
                "nutrient": nutrient,
                "fraction": fraction,
            }
            for nutrient, fraction in composition.items()
        )
    _insert(products, product_rows)
    _insert(nutrients, nutrient_rows)


def _seed_parameters(crop_id: uuid.UUID) -> None:
    table = sa.table(
        "agronomic_parameters",
        sa.column("id", sa.UUID()),
        sa.column("reference_set_id", sa.UUID()),
        sa.column("crop_id", sa.UUID()),
        sa.column("key", sa.String()),
        sa.column("value", sa.Float()),
        sa.column("unit", sa.String()),
        sa.column("notes", sa.Text()),
    )
    parameters = {
        "maintenance_factor": (0.25, "ratio", "Central documented scenario."),
        "nitrogen_efficiency": (0.50, "ratio", "Central value of the documented 0.40-0.60 range."),
        "phosphorus_efficiency": (0.30, "ratio", "Upper value of the documented 0.15-0.30 range."),
        "potassium_efficiency": (0.65, "ratio", "Midpoint of the documented 0.60-0.70 range."),
        "max_n_per_application": (40, "kg/ha", "Maximum nitrogen per application event."),
        "kg_per_qq_gold": (46, "kg/qq", "Operational conversion used by the engine."),
        "cherry_to_green_factor": (5.0, "ratio", "Cherry coffee to green coffee conversion."),
        "hectares_per_manzana": (0.7042, "ha/manzana", "Nicaraguan operational conversion."),
        "soil_credit_deficient": (0.0, "ratio", "Documented response category credit."),
        "soil_credit_probable_response": (0.25, "ratio", "Documented response category credit."),
        "soil_credit_adequate": (1.0, "ratio", "Documented response category credit."),
        "soil_credit_high": (1.10, "ratio", "High status results in zero external dose."),
        "ec_low_chloride_threshold": (0.80, "dS/m", "Monitoring threshold from the soil implementation table."),
        "ec_block_threshold": (1.10, "dS/m", "Salinity-risk threshold from the soil implementation table."),
        "young_urea_g_plant": (114, "g/plant", "Accumulated reference through month 18."),
        "young_dap_g_plant": (33, "g/plant", "Accumulated reference through month 18."),
        "young_kcl_g_plant": (25, "g/plant", "Accumulated reference through month 18."),
        "young_mgo_g_plant": (5, "g/plant", "Accumulated reference through month 18."),
    }
    _insert(
        table,
        [
            {
                "id": _id(f"parameter:{key}"),
                "reference_set_id": REFERENCE_ID,
                "crop_id": crop_id,
                "key": key,
                "value": value,
                "unit": unit,
                "notes": notes,
            }
            for key, (value, unit, notes) in parameters.items()
        ],
    )


def _seed_schedules(crop_id: uuid.UUID) -> None:
    table = sa.table(
        "application_schedule_rules",
        sa.column("id", sa.UUID()),
        sa.column("reference_set_id", sa.UUID()),
        sa.column("crop_id", sa.UUID()),
        sa.column("life_stage", sa.String()),
        sa.column("sequence", sa.Integer()),
        sa.column("moment", sa.String()),
        sa.column("month_after_planting", sa.Integer()),
        sa.column("fraction", sa.Float()),
    )
    production = [
        (1, "Prefloración / inicio de lluvias", None, 0.25),
        (2, "Cuajado y expansión inicial", None, 0.30),
        (3, "Llenado", None, 0.30),
        (4, "Postcosecha / recuperación", None, 0.15),
    ]
    young = [(index, f"Mes {month} de levante", month, 0.20) for index, month in enumerate((2, 6, 10, 14, 18), start=1)]
    rows = []
    for life_stage, schedules in (("production", production), ("young_crop", young)):
        rows.extend(
            {
                "id": _id(f"schedule:{life_stage}:{sequence}"),
                "reference_set_id": REFERENCE_ID,
                "crop_id": crop_id,
                "life_stage": life_stage,
                "sequence": sequence,
                "moment": moment,
                "month_after_planting": month,
                "fraction": fraction,
            }
            for sequence, moment, month, fraction in schedules
        )
    _insert(table, rows)


def _seed_existing_factor_tables(crop_id: uuid.UUID) -> None:
    extraction = sa.table(
        "extraction_indices",
        sa.column("id", sa.UUID()),
        sa.column("reference_set_id", sa.UUID()),
        sa.column("crop_id", sa.UUID()),
        sa.column("nutrient", sa.String()),
        sa.column("ie_value", sa.Float()),
    )
    _insert(
        extraction,
        [
            {"id": _id(f"extraction:{nutrient}"), "reference_set_id": REFERENCE_ID, "crop_id": crop_id, "nutrient": nutrient, "ie_value": value}
            for nutrient, value in (("N", 30.9), ("P2O5", 2.3 * 2.291), ("K2O", 36.9 * 1.205))
        ],
    )

    soil_types = sa.table(
        "soil_types",
        sa.column("id", sa.UUID()),
        sa.column("name", sa.String()),
        sa.column("description", sa.String()),
    )
    _insert(
        soil_types,
        [{"id": SOIL_TYPE_ID, "name": "Regional reference", "description": "Transferred coffee reference pending local soil-series calibration."}],
    )
    efficiencies = sa.table(
        "efficiency_factors",
        sa.column("id", sa.UUID()),
        sa.column("reference_set_id", sa.UUID()),
        sa.column("soil_type_id", sa.UUID()),
        sa.column("nutrient", sa.String()),
        sa.column("ef_min", sa.Float()),
        sa.column("ef_max", sa.Float()),
    )
    _insert(
        efficiencies,
        [
            {"id": _id(f"efficiency:{nutrient}"), "reference_set_id": REFERENCE_ID, "soil_type_id": SOIL_TYPE_ID, "nutrient": nutrient, "ef_min": minimum, "ef_max": maximum}
            for nutrient, minimum, maximum in (("N", 0.40, 0.60), ("P2O5", 0.15, 0.30), ("K2O", 0.60, 0.70))
        ],
    )

    varieties = sa.table(
        "varieties",
        sa.column("id", sa.UUID()),
        sa.column("crop_id", sa.UUID()),
        sa.column("name", sa.String()),
    )
    variety_factors = sa.table(
        "variety_factors",
        sa.column("id", sa.UUID()),
        sa.column("reference_set_id", sa.UUID()),
        sa.column("variety_id", sa.UUID()),
        sa.column("nutrient", sa.String()),
        sa.column("fv_factor", sa.Float()),
    )
    for name in ("Caturra", "Borbón", "Catuaí"):
        variety_id = op.get_bind().execute(
            sa.select(varieties.c.id)
            .where(varieties.c.crop_id == crop_id)
            .where(sa.func.lower(varieties.c.name) == name.lower())
            .limit(1)
        ).scalar_one_or_none()
        if variety_id is None:
            variety_id = _id(f"variety:{name.lower()}")
            _insert(varieties, [{"id": variety_id, "crop_id": crop_id, "name": name}])
        _insert(
            variety_factors,
            [
                {"id": _id(f"variety-factor:{name.lower()}:{nutrient}"), "reference_set_id": REFERENCE_ID, "variety_id": variety_id, "nutrient": nutrient, "fv_factor": 1.0}
                for nutrient in ("N", "P2O5", "K2O")
            ],
        )


def downgrade() -> None:
    # Seed rows use deterministic identifiers, allowing a precise downgrade.
    for table_name, entity_ids in (
        ("variety_factors", [_id(f"variety-factor:{name.lower()}:{nutrient}") for name in ("Caturra", "Borbón", "Catuaí") for nutrient in ("N", "P2O5", "K2O")]),
        ("efficiency_factors", [_id(f"efficiency:{nutrient}") for nutrient in ("N", "P2O5", "K2O")]),
        ("extraction_indices", [_id(f"extraction:{nutrient}") for nutrient in ("N", "P2O5", "K2O")]),
    ):
        table = sa.table(table_name, sa.column("id", sa.UUID()))
        op.get_bind().execute(table.delete().where(table.c.id.in_(entity_ids)))
    reference_sets = sa.table(
        "agronomic_reference_sets", sa.column("id", sa.UUID())
    )
    op.get_bind().execute(
        reference_sets.delete().where(reference_sets.c.id == REFERENCE_ID)
    )
