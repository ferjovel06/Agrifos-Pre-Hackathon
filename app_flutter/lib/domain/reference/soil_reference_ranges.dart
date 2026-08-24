/// Soil-analysis reference ranges for coffee.
library;

/// Identifier for each soil parameter.
enum SoilParameterId {
  ph,
  ec,
  calcium,
  magnesium,
  sodium,
  potassium,
  zinc,
  iron,
  manganese,
  copper,
  nickel,
  nitrateN,
  phosphateP,
  sulfateS,
  boron,
  organicMatter,
  clay,
  silt,
  sand,
  nitrogenTotal,
  cic,
  esp,
  baseSaturationTotal,
  caSaturation,
  mgSaturation,
  kSaturation,
  naSaturation,
}

enum SoilLevel {
  deficient,
  optimal,

  /// High / needs monitoring.
  high,

  /// Critical (toxicity, salinity, sodicity, major imbalance).
  critical,
}

class SoilParameterRange {
  const SoilParameterRange({
    required this.id,
    required this.labelEs,
    required this.unit,
    required this.method,
    required this.confidence,
    required this.deficientBelow,
    required this.optimalMin,
    required this.optimalMax,
    required this.criticalAbove,
    required this.highIsGenerallyFavorable,
    required this.notes,
  });

  final SoilParameterId id;

  /// User-facing label, shown in the UI.
  final String labelEs;
  final String unit;
  final String method;

  /// "High" | "Medium" | "Medium-low" | "Low"
  final String confidence;

  /// value < this -> [SoilLevel.deficient]; null = deficiency doesn't apply.
  final double? deficientBelow;
  final double? optimalMin;

  /// null = open-ended upper bound of the optimal range.
  final double? optimalMax;

  /// Second, stronger threshold -> [SoilLevel.critical].
  final double? criticalAbove;

  /// If true, a "high" value doesn't imply a problem (e.g. Ca, Mg, CEC).
  final bool highIsGenerallyFavorable;

  final String notes;
}

const Map<SoilParameterId, SoilParameterRange> soilReferenceRanges = {
  SoilParameterId.ph: SoilParameterRange(
    id: SoilParameterId.ph,
    labelEs: 'pH',
    unit: 'SU',
    method: 'Potentiometric, lab-specific soil:water ratio',
    confidence: 'High',
    deficientBelow: 5.0,
    optimalMin: 5.0,
    optimalMax: 5.5,
    criticalAbove: 6.0,
    highIsGenerallyFavorable: false,
    notes:
    'Adequate range for coffee per Cenicafé. <5.0 indicates acidity; '
        '>5.5 is interpreted as alkalinity and triggers an alert; review '
        'more closely above 6.0.',
  ),
  SoilParameterId.ec: SoilParameterRange(
    id: SoilParameterId.ec,
    labelEs: 'Conductividad eléctrica',
    unit: 'dS/m',
    method: 'Saturated paste extract or lab-specific soil:water ratio',
    confidence: 'Medium',
    deficientBelow: 0.10,
    optimalMin: 0.10,
    optimalMax: 0.80,
    criticalAbove: 1.10,
    highIsGenerallyFavorable: false,
    notes:
    'No single validated optimum for coffee; Cenicafé reports negative '
        'effects above 1.1 dS/m. 0.80–1.10 is a monitoring zone; >1.10 '
        'triggers a salinity-risk alert. 1 dS/m equals 1,000 µmhos/cm.',
  ),
  SoilParameterId.calcium: SoilParameterRange(
    id: SoilParameterId.calcium,
    labelEs: 'Calcio intercambiable',
    unit: 'mg/kg',
    method:
    'Ammonium acetate (exchangeable cation); 1 meq/100 g = 1 cmolc/kg',
    confidence: 'High',
    deficientBelow: 301,
    optimalMin: 301,
    optimalMax: 601,
    criticalAbove: null,
    highIsGenerallyFavorable: true,
    notes: 'High values are generally preferable; does not imply toxicity by itself.',
  ),
  SoilParameterId.magnesium: SoilParameterRange(
    id: SoilParameterId.magnesium,
    labelEs: 'Magnesio intercambiable',
    unit: 'mg/kg',
    method:
    'Ammonium acetate (exchangeable cation); 1 meq/100 g = 1 cmolc/kg',
    confidence: 'High',
    deficientBelow: 73,
    optimalMin: 73,
    optimalMax: 109,
    criticalAbove: null,
    highIsGenerallyFavorable: true,
    notes: 'High value: review the Ca:Mg ratio before treating it as a problem.',
  ),
  SoilParameterId.sodium: SoilParameterRange(
    id: SoilParameterId.sodium,
    labelEs: 'Sodio intercambiable',
    unit: 'mg/kg',
    method: 'Ammonium acetate (exchangeable cation)',
    confidence: 'Medium',
    deficientBelow: null,
    optimalMin: 0,
    optimalMax: 100,
    criticalAbove: 1000,
    highIsGenerallyFavorable: false,
    notes:
    'No deficiency threshold applies: a low value is favorable. '
        "Cenicafé does not propose a sufficiency level for coffee; used as "
        'a sodicity indicator, not a nutrient to maximize. >100 mg/kg '
        'requires monitoring; >1,000 mg/kg is a strong alert.',
  ),
  SoilParameterId.potassium: SoilParameterRange(
    id: SoilParameterId.potassium,
    labelEs: 'Potasio intercambiable',
    unit: 'mg/kg',
    method:
    'Ammonium acetate (exchangeable cation); 1 meq/100 g = 1 cmolc/kg',
    confidence: 'High',
    deficientBelow: 78,
    optimalMin: 78,
    optimalMax: 156,
    criticalAbove: null,
    highIsGenerallyFavorable: false,
    notes: 'High value: confirm lab method before adjusting the dose.',
  ),
  SoilParameterId.zinc: SoilParameterRange(
    id: SoilParameterId.zinc,
    labelEs: 'Zinc',
    unit: 'mg/kg',
    method: 'DTPA or modified Olsen',
    confidence: 'Medium',
    deficientBelow: 1.5,
    optimalMin: 1.5,
    optimalMax: 3.0,
    criticalAbove: null,
    highIsGenerallyFavorable: false,
    notes: 'General reference, not a soil-specific critical level; confirm DTPA method.',
  ),
  SoilParameterId.iron: SoilParameterRange(
    id: SoilParameterId.iron,
    labelEs: 'Hierro',
    unit: 'mg/kg',
    method: 'DTPA or modified Olsen',
    confidence: 'Medium',
    deficientBelow: 25,
    optimalMin: 25,
    optimalMax: 50,
    criticalAbove: null,
    highIsGenerallyFavorable: false,
    notes: 'General reference; depends on pH, texture and method.',
  ),
  SoilParameterId.manganese: SoilParameterRange(
    id: SoilParameterId.manganese,
    labelEs: 'Manganeso',
    unit: 'mg/kg',
    method: 'DTPA or modified Olsen',
    confidence: 'Medium',
    deficientBelow: 5,
    optimalMin: 5,
    optimalMax: 20,
    criticalAbove: null,
    highIsGenerallyFavorable: false,
    notes: 'General reference; depends on pH, texture and method.',
  ),
  SoilParameterId.copper: SoilParameterRange(
    id: SoilParameterId.copper,
    labelEs: 'Cobre',
    unit: 'mg/kg',
    method: 'DTPA or modified Olsen',
    confidence: 'Medium',
    deficientBelow: 1.0,
    optimalMin: 1.0,
    optimalMax: 3.0,
    criticalAbove: null,
    highIsGenerallyFavorable: false,
    notes: 'General reference, not a soil-specific critical level; confirm DTPA method.',
  ),
  SoilParameterId.nickel: SoilParameterRange(
    id: SoilParameterId.nickel,
    labelEs: 'Níquel',
    unit: 'mg/kg',
    method: 'DTPA',
    confidence: 'Low',
    deficientBelow: null,
    optimalMin: 0,
    optimalMax: 1,
    criticalAbove: null,
    highIsGenerallyFavorable: false,
    notes:
    'No established critical deficiency for coffee; use as an '
        'environmental/contamination alert, not as a nutrient. >1 mg/kg: '
        'confirm contamination or method.',
  ),
  SoilParameterId.nitrateN: SoilParameterRange(
    id: SoilParameterId.nitrateN,
    labelEs: 'Nitrato-N',
    unit: 'mg/kg',
    method:
    'Cadmium reduction or other colorimetric method (operational monitoring)',
    confidence: 'Low',
    deficientBelow: 10,
    optimalMin: 10,
    optimalMax: 30,
    criticalAbove: null,
    highIsGenerallyFavorable: false,
    notes:
    'Immediate-availability indicator; does NOT equal total nitrogen '
        'and fluctuates with moisture, rainfall, mineralization and '
        'recent fertilization.',
  ),
  SoilParameterId.phosphateP: SoilParameterRange(
    id: SoilParameterId.phosphateP,
    labelEs: 'Fosfato-P',
    unit: 'mg/kg',
    method:
    'Varies by lab — identify whether it is elemental P, PO4, or '
        'Olsen/Bray available P',
    confidence: 'Medium-low',
    deficientBelow: 10,
    optimalMin: 10,
    optimalMax: 20,
    criticalAbove: null,
    highIsGenerallyFavorable: false,
    notes:
    'During establishment the operational target rises to ~30 mg/kg. '
        "Method-dependent; don't automatically interpret as Olsen/Bray "
        'phosphorus.',
  ),
  SoilParameterId.sulfateS: SoilParameterRange(
    id: SoilParameterId.sulfateS,
    labelEs: 'Sulfato-S',
    unit: 'mg/kg',
    method:
    "Varies by lab; don't compare directly with hot-water extractable S",
    confidence: 'Medium-low',
    deficientBelow: 6,
    optimalMin: 6,
    optimalMax: 12,
    criticalAbove: null,
    highIsGenerallyFavorable: false,
    notes: "Same numeric range as Cenicafé's available S, but the method may differ.",
  ),
  SoilParameterId.boron: SoilParameterRange(
    id: SoilParameterId.boron,
    labelEs: 'Boro',
    unit: 'mg/kg',
    method: 'Hot water',
    confidence: 'Medium',
    deficientBelow: 0.2,
    optimalMin: 0.2,
    optimalMax: 0.5,
    criticalAbove: null,
    highIsGenerallyFavorable: false,
    notes: 'Requires regional calibration; confirm before correcting an apparent excess.',
  ),
  SoilParameterId.organicMatter: SoilParameterRange(
    id: SoilParameterId.organicMatter,
    labelEs: 'Materia orgánica',
    unit: '%',
    method: 'Combustion / Walkley-Black or another lab method',
    confidence: 'High',
    deficientBelow: 8,
    optimalMin: 8,
    optimalMax: 16,
    criticalAbove: null,
    highIsGenerallyFavorable: false,
    notes: "<8% indicates low organic matter; >16% doesn't automatically mean better.",
  ),
  SoilParameterId.clay: SoilParameterRange(
    id: SoilParameterId.clay,
    labelEs: 'Arcilla',
    unit: '%',
    method: 'Texture (e.g. Bouyoucos / hydrometer)',
    confidence: 'Medium',
    deficientBelow: 20,
    optimalMin: 20,
    optimalMax: 40,
    criticalAbove: null,
    highIsGenerallyFavorable: false,
    notes:
    'Orientative; complement with the textural class. Clay, silt and '
        'sand must add up to 100%. >40% requires monitoring drainage and '
        'compaction.',
  ),
  SoilParameterId.silt: SoilParameterRange(
    id: SoilParameterId.silt,
    labelEs: 'Limo',
    unit: '%',
    method: 'Texture (e.g. Bouyoucos / hydrometer)',
    confidence: 'Medium',
    deficientBelow: 20,
    optimalMin: 20,
    optimalMax: 50,
    criticalAbove: null,
    highIsGenerallyFavorable: false,
    notes:
    'Orientative; complement with the textural class. >50% requires '
        'monitoring erosion and compaction.',
  ),
  SoilParameterId.sand: SoilParameterRange(
    id: SoilParameterId.sand,
    labelEs: 'Arena',
    unit: '%',
    method: 'Texture (e.g. Bouyoucos / hydrometer)',
    confidence: 'Medium',
    deficientBelow: 30,
    optimalMin: 30,
    optimalMax: 60,
    criticalAbove: null,
    highIsGenerallyFavorable: false,
    notes:
    'Implies slow drainage below 30%; implies low water retention '
        'above 60%. Orientative; complement with the textural class.',
  ),
  SoilParameterId.nitrogenTotal: SoilParameterRange(
    id: SoilParameterId.nitrogenTotal,
    labelEs: 'Nitrógeno total',
    unit: 'mg/kg',
    method: 'Kjeldahl (converted from % total N: 0.34–0.58%)',
    confidence: 'High',
    deficientBelow: 3400,
    optimalMin: 3400,
    optimalMax: 5800,
    criticalAbove: null,
    highIsGenerallyFavorable: false,
    notes:
    'Medium level for production; a high value should be interpreted '
        'alongside organic matter.',
  ),
  SoilParameterId.cic: SoilParameterRange(
    id: SoilParameterId.cic,
    labelEs: 'CIC / CEC',
    unit: 'cmolc/kg',
    method: 'Sum of bases or ammonium acetate pH 7; 1 meq/100 g = 1 cmolc/kg',
    confidence: 'High',
    deficientBelow: 15,
    optimalMin: 15,
    optimalMax: 25,
    criticalAbove: null,
    highIsGenerallyFavorable: true,
    notes: 'A high CEC favors nutrient retention; >25 is not considered excess.',
  ),
  SoilParameterId.esp: SoilParameterRange(
    id: SoilParameterId.esp,
    labelEs: 'Porcentaje de sodio intercambiable (ESP)',
    unit: '%',
    method: 'Calculated: (exchangeable Na / CEC) × 100',
    confidence: 'Medium',
    deficientBelow: null,
    optimalMin: 0,
    optimalMax: 5,
    criticalAbove: 15,
    highIsGenerallyFavorable: false,
    notes:
    'No deficiency applies: a low value is favorable. 5–15% requires '
        'monitoring; ≥15% indicates probable sodicity and triggers an '
        'alert. General operational criterion, not variety-specific.',
  ),
  SoilParameterId.baseSaturationTotal: SoilParameterRange(
    id: SoilParameterId.baseSaturationTotal,
    labelEs: 'Saturación de bases total',
    unit: '%',
    method: 'Calculated: sum of base cations / CEC × 100',
    confidence: 'High',
    deficientBelow: 20,
    optimalMin: 30,
    optimalMax: null,
    criticalAbove: 80,
    highIsGenerallyFavorable: true,
    notes:
    'The source document does not define an explicit range between '
        '20% and 30%; treat that band as an undefined intermediate zone '
        'rather than auto-classifying it. There is no universal surplus; '
        'pay particular attention to values >80% and possible cation '
        'imbalances.',
  ),
  SoilParameterId.caSaturation: SoilParameterRange(
    id: SoilParameterId.caSaturation,
    labelEs: 'Saturación de calcio',
    unit: '%',
    method: 'Calculated: exchangeable Ca / CEC × 100',
    confidence: 'Medium',
    deficientBelow: 55,
    optimalMin: 55,
    optimalMax: 70,
    criticalAbove: null,
    highIsGenerallyFavorable: false,
    notes: 'Above 70%: review cation competition with Mg and K.',
  ),
  SoilParameterId.mgSaturation: SoilParameterRange(
    id: SoilParameterId.mgSaturation,
    labelEs: 'Saturación de magnesio',
    unit: '%',
    method: 'Calculated: exchangeable Mg / CEC × 100',
    confidence: 'Medium',
    deficientBelow: 10,
    optimalMin: 10,
    optimalMax: 20,
    criticalAbove: null,
    highIsGenerallyFavorable: false,
    notes: 'Above 20%: review cation competition.',
  ),
  SoilParameterId.kSaturation: SoilParameterRange(
    id: SoilParameterId.kSaturation,
    labelEs: 'Saturación de potasio',
    unit: '%',
    method: 'Calculated: exchangeable K / CEC × 100',
    confidence: 'Medium',
    deficientBelow: 2,
    optimalMin: 2,
    optimalMax: 5,
    criticalAbove: null,
    highIsGenerallyFavorable: false,
    notes: 'Above 5%: review balance with Ca and Mg.',
  ),
  SoilParameterId.naSaturation: SoilParameterRange(
    id: SoilParameterId.naSaturation,
    labelEs: 'Saturación de sodio',
    unit: '%',
    method: 'Calculated: exchangeable Na / CEC × 100',
    confidence: 'Medium',
    deficientBelow: null,
    optimalMin: 0,
    optimalMax: 5,
    criticalAbove: 15,
    highIsGenerallyFavorable: false,
    notes:
    'No deficiency applies: a low value is favorable. ≥5% requires '
        'monitoring; ≥15% is considered critical.',
  ),
};

/// Classifies a measured value into one of the 4 states recommended by the
/// source document (deficient / optimal / high / critical) per
/// [soilReferenceRanges].
SoilLevel classifySoilParameter(SoilParameterId id, double value) {
  final r = soilReferenceRanges[id]!;

  if (r.deficientBelow != null && value < r.deficientBelow!) {
    return SoilLevel.deficient;
  }

  if (r.criticalAbove != null && value >= r.criticalAbove!) {
    return SoilLevel.critical;
  }

  if (r.optimalMax != null && value > r.optimalMax!) {
    return SoilLevel.high;
  }

  if (r.optimalMin != null && value < r.optimalMin!) {
    // Zone between `deficientBelow` and `optimalMin` without explicit
    // evidence in the source document (e.g. total base saturation 20–30%).
    return SoilLevel.deficient;
  }

  return SoilLevel.optimal;
}