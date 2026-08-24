"""
Soil-analysis reference ranges for coffee (Coffea arabica).
"""

from dataclasses import dataclass
from enum import Enum


class SoilParameterId(str, Enum):
    PH = "ph"
    EC = "ec"
    CALCIUM = "calcium"
    MAGNESIUM = "magnesium"
    SODIUM = "sodium"
    POTASSIUM = "potassium"
    ZINC = "zinc"
    IRON = "iron"
    MANGANESE = "manganese"
    COPPER = "copper"
    NICKEL = "nickel"
    NITRATE_N = "nitrate_n"
    PHOSPHATE_P = "phosphate_p"
    SULFATE_S = "sulfate_s"
    BORON = "boron"
    ORGANIC_MATTER = "organic_matter"
    CLAY = "clay"
    SILT = "silt"
    SAND = "sand"
    NITROGEN_TOTAL = "nitrogen_total"
    CIC = "cic"
    ESP = "esp"
    BASE_SATURATION_TOTAL = "base_saturation_total"
    CA_SATURATION = "ca_saturation"
    MG_SATURATION = "mg_saturation"
    K_SATURATION = "k_saturation"
    NA_SATURATION = "na_saturation"


class SoilLevel(str, Enum):

    DEFICIENT = "deficient"
    OPTIMAL = "optimal"
    HIGH = "high"  # high / needs monitoring
    CRITICAL = "critical"  # toxicity, salinity, sodicity, major imbalance


@dataclass(frozen=True)
class SoilParameterRange:
    id: SoilParameterId
    label_es: str  # user-facing label, shown in the UI 
    unit: str
    method: str
    confidence: str  # "High" | "Medium" | "Medium-low" | "Low"
    deficient_below: float | None  # value < this -> DEFICIENT; None = deficiency doesn't apply
    optimal_min: float | None
    optimal_max: float | None  # None = open-ended upper bound of the optimal range
    critical_above: float | None  # second, stronger threshold -> CRITICAL
    high_is_generally_favorable: bool  # True: a "high" value doesn't imply a problem
    notes: str


SOIL_REFERENCE_RANGES: dict[SoilParameterId, SoilParameterRange] = {
    SoilParameterId.PH: SoilParameterRange(
        id=SoilParameterId.PH,
        label_es="pH",
        unit="SU",
        method="Potentiometric, lab-specific soil:water ratio",
        confidence="High",
        deficient_below=5.0,
        optimal_min=5.0,
        optimal_max=5.5,
        critical_above=6.0,
        high_is_generally_favorable=False,
        notes=(
            "Adequate range for coffee per Cenicafé. <5.0 indicates acidity; "
            ">5.5 is interpreted as alkalinity and triggers an alert; review more "
            "closely above 6.0."
        ),
    ),
    SoilParameterId.EC: SoilParameterRange(
        id=SoilParameterId.EC,
        label_es="Conductividad eléctrica",
        unit="dS/m",
        method="Saturated paste extract or lab-specific soil:water ratio",
        confidence="Medium",
        deficient_below=0.10,
        optimal_min=0.10,
        optimal_max=0.80,
        critical_above=1.10,
        high_is_generally_favorable=False,
        notes=(
            "No single validated optimum for coffee; Cenicafé reports negative "
            "effects above 1.1 dS/m. 0.80–1.10 is a monitoring zone; >1.10 "
            "triggers a salinity-risk alert. 1 dS/m equals 1,000 µmhos/cm."
        ),
    ),
    SoilParameterId.CALCIUM: SoilParameterRange(
        id=SoilParameterId.CALCIUM,
        label_es="Calcio intercambiable",
        unit="mg/kg",
        method="Ammonium acetate (exchangeable cation); 1 meq/100 g = 1 cmolc/kg",
        confidence="High",
        deficient_below=301,
        optimal_min=301,
        optimal_max=601,
        critical_above=None,
        high_is_generally_favorable=True,
        notes="High values are generally preferable; does not imply toxicity by itself.",
    ),
    SoilParameterId.MAGNESIUM: SoilParameterRange(
        id=SoilParameterId.MAGNESIUM,
        label_es="Magnesio intercambiable",
        unit="mg/kg",
        method="Ammonium acetate (exchangeable cation); 1 meq/100 g = 1 cmolc/kg",
        confidence="High",
        deficient_below=73,
        optimal_min=73,
        optimal_max=109,
        critical_above=None,
        high_is_generally_favorable=True,
        notes="High value: review the Ca:Mg ratio before treating it as a problem.",
    ),
    SoilParameterId.SODIUM: SoilParameterRange(
        id=SoilParameterId.SODIUM,
        label_es="Sodio intercambiable",
        unit="mg/kg",
        method="Ammonium acetate (exchangeable cation)",
        confidence="Medium",
        deficient_below=None,
        optimal_min=0,
        optimal_max=100,
        critical_above=1000,
        high_is_generally_favorable=False,
        notes=(
            "No deficiency threshold applies: a low value is favorable. Cenicafé "
            "does not propose a sufficiency level for coffee; used as a sodicity "
            "indicator, not a nutrient to maximize. >100 mg/kg requires "
            "monitoring; >1,000 mg/kg is a strong alert."
        ),
    ),
    SoilParameterId.POTASSIUM: SoilParameterRange(
        id=SoilParameterId.POTASSIUM,
        label_es="Potasio intercambiable",
        unit="mg/kg",
        method="Ammonium acetate (exchangeable cation); 1 meq/100 g = 1 cmolc/kg",
        confidence="High",
        deficient_below=78,
        optimal_min=78,
        optimal_max=156,
        critical_above=None,
        high_is_generally_favorable=False,
        notes="High value: confirm lab method before adjusting the dose.",
    ),
    SoilParameterId.ZINC: SoilParameterRange(
        id=SoilParameterId.ZINC,
        label_es="Zinc",
        unit="mg/kg",
        method="DTPA or modified Olsen",
        confidence="Medium",
        deficient_below=1.5,
        optimal_min=1.5,
        optimal_max=3.0,
        critical_above=None,
        high_is_generally_favorable=False,
        notes="General reference, not a soil-specific critical level; confirm DTPA method.",
    ),
    SoilParameterId.IRON: SoilParameterRange(
        id=SoilParameterId.IRON,
        label_es="Hierro",
        unit="mg/kg",
        method="DTPA or modified Olsen",
        confidence="Medium",
        deficient_below=25,
        optimal_min=25,
        optimal_max=50,
        critical_above=None,
        high_is_generally_favorable=False,
        notes="General reference; depends on pH, texture and method.",
    ),
    SoilParameterId.MANGANESE: SoilParameterRange(
        id=SoilParameterId.MANGANESE,
        label_es="Manganeso",
        unit="mg/kg",
        method="DTPA or modified Olsen",
        confidence="Medium",
        deficient_below=5,
        optimal_min=5,
        optimal_max=20,
        critical_above=None,
        high_is_generally_favorable=False,
        notes="General reference; depends on pH, texture and method.",
    ),
    SoilParameterId.COPPER: SoilParameterRange(
        id=SoilParameterId.COPPER,
        label_es="Cobre",
        unit="mg/kg",
        method="DTPA or modified Olsen",
        confidence="Medium",
        deficient_below=1.0,
        optimal_min=1.0,
        optimal_max=3.0,
        critical_above=None,
        high_is_generally_favorable=False,
        notes="General reference, not a soil-specific critical level; confirm DTPA method.",
    ),
    SoilParameterId.NICKEL: SoilParameterRange(
        id=SoilParameterId.NICKEL,
        label_es="Níquel",
        unit="mg/kg",
        method="DTPA",
        confidence="Low",
        deficient_below=None,
        optimal_min=0,
        optimal_max=1,
        critical_above=None,
        high_is_generally_favorable=False,
        notes=(
            "No established critical deficiency for coffee; use as an "
            "environmental/contamination alert, not as a nutrient. >1 mg/kg: "
            "confirm contamination or method."
        ),
    ),
    SoilParameterId.NITRATE_N: SoilParameterRange(
        id=SoilParameterId.NITRATE_N,
        label_es="Nitrato-N",
        unit="mg/kg",
        method="Cadmium reduction or other colorimetric method (operational monitoring)",
        confidence="Low",
        deficient_below=10,
        optimal_min=10,
        optimal_max=30,
        critical_above=None,
        high_is_generally_favorable=False,
        notes=(
            "Immediate-availability indicator; does NOT equal total nitrogen and "
            "fluctuates with moisture, rainfall, mineralization and recent "
            "fertilization."
        ),
    ),
    SoilParameterId.PHOSPHATE_P: SoilParameterRange(
        id=SoilParameterId.PHOSPHATE_P,
        label_es="Fosfato-P",
        unit="mg/kg",
        method=(
            "Varies by lab — identify whether it is elemental P, PO4, or "
            "Olsen/Bray available P"
        ),
        confidence="Medium-low",
        deficient_below=10,
        optimal_min=10,
        optimal_max=20,
        critical_above=None,
        high_is_generally_favorable=False,
        notes=(
            "During establishment the operational target rises to ~30 mg/kg. "
            "Method-dependent; don't automatically interpret as Olsen/Bray "
            "phosphorus."
        ),
    ),
    SoilParameterId.SULFATE_S: SoilParameterRange(
        id=SoilParameterId.SULFATE_S,
        label_es="Sulfato-S",
        unit="mg/kg",
        method="Varies by lab; don't compare directly with hot-water extractable S",
        confidence="Medium-low",
        deficient_below=6,
        optimal_min=6,
        optimal_max=12,
        critical_above=None,
        high_is_generally_favorable=False,
        notes="Same numeric range as Cenicafé's available S, but the method may differ.",
    ),
    SoilParameterId.BORON: SoilParameterRange(
        id=SoilParameterId.BORON,
        label_es="Boro",
        unit="mg/kg",
        method="Hot water",
        confidence="Medium",
        deficient_below=0.2,
        optimal_min=0.2,
        optimal_max=0.5,
        critical_above=None,
        high_is_generally_favorable=False,
        notes="Requires regional calibration; confirm before correcting an apparent excess.",
    ),
    SoilParameterId.ORGANIC_MATTER: SoilParameterRange(
        id=SoilParameterId.ORGANIC_MATTER,
        label_es="Materia orgánica",
        unit="%",
        method="Combustion / Walkley-Black or another lab method",
        confidence="High",
        deficient_below=8,
        optimal_min=8,
        optimal_max=16,
        critical_above=None,
        high_is_generally_favorable=False,
        notes="<8% indicates low organic matter; >16% doesn't automatically mean better.",
    ),
    SoilParameterId.CLAY: SoilParameterRange(
        id=SoilParameterId.CLAY,
        label_es="Arcilla",
        unit="%",
        method="Texture (e.g. Bouyoucos / hydrometer)",
        confidence="Medium",
        deficient_below=20,
        optimal_min=20,
        optimal_max=40,
        critical_above=None,
        high_is_generally_favorable=False,
        notes=(
            "Orientative; complement with the textural class. Clay, silt and sand "
            "must add up to 100%. >40% requires monitoring drainage and "
            "compaction."
        ),
    ),
    SoilParameterId.SILT: SoilParameterRange(
        id=SoilParameterId.SILT,
        label_es="Limo",
        unit="%",
        method="Texture (e.g. Bouyoucos / hydrometer)",
        confidence="Medium",
        deficient_below=20,
        optimal_min=20,
        optimal_max=50,
        critical_above=None,
        high_is_generally_favorable=False,
        notes=(
            "Orientative; complement with the textural class. >50% requires "
            "monitoring erosion and compaction."
        ),
    ),
    SoilParameterId.SAND: SoilParameterRange(
        id=SoilParameterId.SAND,
        label_es="Arena",
        unit="%",
        method="Texture (e.g. Bouyoucos / hydrometer)",
        confidence="Medium",
        deficient_below=30,
        optimal_min=30,
        optimal_max=60,
        critical_above=None,
        high_is_generally_favorable=False,
        notes=(
            "<30% implies slow drainage; >60% implies low water retention. "
            "Orientative; complement with the textural class."
        ),
    ),
    SoilParameterId.NITROGEN_TOTAL: SoilParameterRange(
        id=SoilParameterId.NITROGEN_TOTAL,
        label_es="Nitrógeno total",
        unit="mg/kg",
        method="Kjeldahl (converted from % total N: 0.34–0.58%)",
        confidence="High",
        deficient_below=3400,
        optimal_min=3400,
        optimal_max=5800,
        critical_above=None,
        high_is_generally_favorable=False,
        notes="Medium level for production; a high value should be interpreted alongside organic matter.",
    ),
    SoilParameterId.CIC: SoilParameterRange(
        id=SoilParameterId.CIC,
        label_es="CIC / CEC",
        unit="cmolc/kg",
        method="Sum of bases or ammonium acetate pH 7; 1 meq/100 g = 1 cmolc/kg",
        confidence="High",
        deficient_below=15,
        optimal_min=15,
        optimal_max=25,
        critical_above=None,
        high_is_generally_favorable=True,
        notes="A high CEC favors nutrient retention; >25 is not considered excess.",
    ),
    SoilParameterId.ESP: SoilParameterRange(
        id=SoilParameterId.ESP,
        label_es="Porcentaje de sodio intercambiable (ESP)",
        unit="%",
        method="Calculated: (exchangeable Na / CEC) × 100",
        confidence="Medium",
        deficient_below=None,
        optimal_min=0,
        optimal_max=5,
        critical_above=15,
        high_is_generally_favorable=False,
        notes=(
            "No deficiency applies: a low value is favorable. 5–15% requires "
            "monitoring; ≥15% indicates probable sodicity and triggers an alert. "
            "General operational criterion, not variety-specific."
        ),
    ),
    SoilParameterId.BASE_SATURATION_TOTAL: SoilParameterRange(
        id=SoilParameterId.BASE_SATURATION_TOTAL,
        label_es="Saturación de bases total",
        unit="%",
        method="Calculated: sum of base cations / CEC × 100",
        confidence="High",
        deficient_below=20,
        optimal_min=30,
        optimal_max=None,
        critical_above=80,
        high_is_generally_favorable=True,
        notes=(
            "The source document does not define an explicit range between 20% "
            "and 30%; treat that band as an undefined intermediate zone rather "
            "than auto-classifying it. There is no universal surplus; pay "
            "particular attention to values >80% and possible cation "
            "imbalances."
        ),
    ),
    SoilParameterId.CA_SATURATION: SoilParameterRange(
        id=SoilParameterId.CA_SATURATION,
        label_es="Saturación de calcio",
        unit="%",
        method="Calculated: exchangeable Ca / CEC × 100",
        confidence="Medium",
        deficient_below=55,
        optimal_min=55,
        optimal_max=70,
        critical_above=None,
        high_is_generally_favorable=False,
        notes="Above 70%: review cation competition with Mg and K.",
    ),
    SoilParameterId.MG_SATURATION: SoilParameterRange(
        id=SoilParameterId.MG_SATURATION,
        label_es="Saturación de magnesio",
        unit="%",
        method="Calculated: exchangeable Mg / CEC × 100",
        confidence="Medium",
        deficient_below=10,
        optimal_min=10,
        optimal_max=20,
        critical_above=None,
        high_is_generally_favorable=False,
        notes="Above 20%: review cation competition.",
    ),
    SoilParameterId.K_SATURATION: SoilParameterRange(
        id=SoilParameterId.K_SATURATION,
        label_es="Saturación de potasio",
        unit="%",
        method="Calculated: exchangeable K / CEC × 100",
        confidence="Medium",
        deficient_below=2,
        optimal_min=2,
        optimal_max=5,
        critical_above=None,
        high_is_generally_favorable=False,
        notes="Above 5%: review balance with Ca and Mg.",
    ),
    SoilParameterId.NA_SATURATION: SoilParameterRange(
        id=SoilParameterId.NA_SATURATION,
        label_es="Saturación de sodio",
        unit="%",
        method="Calculated: exchangeable Na / CEC × 100",
        confidence="Medium",
        deficient_below=None,
        optimal_min=0,
        optimal_max=5,
        critical_above=15,
        high_is_generally_favorable=False,
        notes=(
            "No deficiency applies: a low value is favorable. ≥5% requires "
            "monitoring; ≥15% is considered critical."
        ),
    ),
}

LAB_ANALYSIS_FIELD_MAP: dict[str, SoilParameterId] = {
    "ph": SoilParameterId.PH,
    "organic_matter_pct": SoilParameterId.ORGANIC_MATTER,
    "cic": SoilParameterId.CIC,
    "clay_pct": SoilParameterId.CLAY,
    "silt_pct": SoilParameterId.SILT,
    "sand_pct": SoilParameterId.SAND,
    "nitrogen": SoilParameterId.NITROGEN_TOTAL,
    "phosphorus": SoilParameterId.PHOSPHATE_P,
    "potassium": SoilParameterId.POTASSIUM,
    "calcium": SoilParameterId.CALCIUM,
    "magnesium": SoilParameterId.MAGNESIUM,
    "sulfur": SoilParameterId.SULFATE_S,
}

READING_FIELD_MAP: dict[str, SoilParameterId] = {
    "nitrogen": SoilParameterId.NITRATE_N,
    "phosphorus": SoilParameterId.PHOSPHATE_P,
    "potassium": SoilParameterId.POTASSIUM,
    "ec": SoilParameterId.EC,
    "ph": SoilParameterId.PH,
}


def classify(parameter_id: SoilParameterId, value: float) -> SoilLevel:
    r = SOIL_REFERENCE_RANGES[parameter_id]

    if r.deficient_below is not None and value < r.deficient_below:
        return SoilLevel.DEFICIENT

    if r.critical_above is not None and value >= r.critical_above:
        return SoilLevel.CRITICAL

    if r.optimal_max is not None and value > r.optimal_max:
        return SoilLevel.HIGH

    if r.optimal_min is not None and value < r.optimal_min:
        return SoilLevel.DEFICIENT

    return SoilLevel.OPTIMAL