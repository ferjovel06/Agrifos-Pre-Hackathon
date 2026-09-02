class NutrientRequirement {
  const NutrientRequirement({
    required this.nutrient,
    required this.unit,
    required this.exportedKgHa,
    required this.totalDemandKgHa,
    required this.soilCreditKgHa,
    required this.fertilizerRequirementKgHa,
    required this.soilStatus,
  });

  final String nutrient;
  final String unit;
  final double exportedKgHa;
  final double totalDemandKgHa;
  final double soilCreditKgHa;
  final double fertilizerRequirementKgHa;
  final String soilStatus;

  factory NutrientRequirement.fromJson(Map<String, dynamic> json) {
    return NutrientRequirement(
      nutrient: json['nutrient'] as String,
      unit: json['unit'] as String,
      exportedKgHa: (json['exported_kg_ha'] as num).toDouble(),
      totalDemandKgHa: (json['total_demand_kg_ha'] as num).toDouble(),
      soilCreditKgHa: (json['soil_credit_kg_ha'] as num).toDouble(),
      fertilizerRequirementKgHa: (json['fertilizer_requirement_kg_ha'] as num)
          .toDouble(),
      soilStatus: json['soil_status'] as String,
    );
  }
}

class FertilizerProductDose {
  const FertilizerProductDose({
    this.productKey = '',
    required this.product,
    required this.guaranteedAnalysis,
    required this.kgPerHectare,
    required this.kgPerManzana,
    required this.gramsPerPlant,
    required this.nutrientContributions,
  });

  final String productKey;
  final String product;
  final Map<String, double> guaranteedAnalysis;
  final double kgPerHectare;
  final double kgPerManzana;
  final double gramsPerPlant;
  final Map<String, double> nutrientContributions;

  factory FertilizerProductDose.fromJson(Map<String, dynamic> json) {
    final contributions = json['nutrient_contributions_kg_ha'] as Map;
    final analysis = json['guaranteed_analysis_pct'] as Map;
    return FertilizerProductDose(
      productKey: json['product_key'] as String? ?? '',
      product: json['product'] as String,
      guaranteedAnalysis: analysis.map(
        (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
      ),
      kgPerHectare: (json['kg_ha'] as num).toDouble(),
      kgPerManzana: (json['kg_manzana'] as num).toDouble(),
      gramsPerPlant: (json['g_plant'] as num).toDouble(),
      nutrientContributions: contributions.map(
        (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
      ),
    );
  }

  String get displayName {
    final n = guaranteedAnalysis['N'] ?? 0;
    final p = guaranteedAnalysis['P2O5'] ?? 0;
    final k = guaranteedAnalysis['K2O'] ?? 0;
    final grade = '${_grade(n)}-${_grade(p)}-${_grade(k)}';
    return '$product ($grade)';
  }

  static String _grade(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}

class FertilizerApplication {
  const FertilizerApplication({
    required this.number,
    required this.moment,
    this.monthAfterPlanting,
    required this.fraction,
    required this.products,
  });

  final int number;
  final String moment;
  final int? monthAfterPlanting;
  final double fraction;
  final List<FertilizerProductDose> products;

  factory FertilizerApplication.fromJson(Map<String, dynamic> json) {
    return FertilizerApplication(
      number: json['application_number'] as int,
      moment: json['moment'] as String,
      monthAfterPlanting: json['month_after_planting'] as int?,
      fraction: (json['fraction'] as num).toDouble(),
      products: _productList(json['products']),
    );
  }

  FertilizerProductDose? sourceFor(String nutrient) =>
      _sourceFor(products, nutrient);
}

class FertilizerScenario {
  const FertilizerScenario({
    required this.name,
    this.selectionMethod = '',
    this.isMathematicallyValid = true,
    required this.products,
    this.applicationSchedule = const [],
  });

  final String name;
  final String selectionMethod;
  final bool isMathematicallyValid;
  final List<FertilizerProductDose> products;
  final List<FertilizerApplication> applicationSchedule;

  factory FertilizerScenario.fromJson(Map<String, dynamic> json) {
    return FertilizerScenario(
      name: json['name'] as String,
      selectionMethod: json['selection_method'] as String? ?? '',
      isMathematicallyValid: json['is_mathematically_valid'] as bool? ?? true,
      products: _productList(json['products']),
      applicationSchedule:
          (json['application_schedule'] as List<dynamic>? ?? const [])
              .map(
                (item) => FertilizerApplication.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList(growable: false),
    );
  }

  FertilizerProductDose? sourceFor(String nutrient) {
    return _sourceFor(products, nutrient);
  }

  FertilizerApplication? nextApplicationForAge(int ageMonths) {
    for (final application in applicationSchedule) {
      final scheduledMonth = application.monthAfterPlanting;
      if (scheduledMonth != null && scheduledMonth >= ageMonths) {
        return application;
      }
    }
    return null;
  }
}

class FertilizationRecommendation {
  const FertilizationRecommendation({
    this.planId,
    this.sourceType,
    this.sourceRecordedAt,
    this.parcelId = '',
    this.crop = '',
    this.variety = '',
    this.plantAgeMonths = 0,
    this.lifeStage = '',
    this.fruitStage = '',
    this.targetGreenKgHa = 0,
    this.engineVersion = '',
    required this.status,
    this.nutrientRequirements = const [],
    required this.scenarios,
    this.limitingNutrients = const [],
    required this.warnings,
    this.assumptions = const [],
  });

  final String? planId;
  final String? sourceType;
  final DateTime? sourceRecordedAt;
  final String parcelId;
  final String crop;
  final String variety;
  final int plantAgeMonths;
  final String lifeStage;
  final String fruitStage;
  final double targetGreenKgHa;
  final String engineVersion;
  final String status;
  final List<NutrientRequirement> nutrientRequirements;
  final List<FertilizerScenario> scenarios;
  final List<String> limitingNutrients;
  final List<String> warnings;
  final List<String> assumptions;

  FertilizerScenario? get conventionalScenario =>
      scenarios.isEmpty ? null : scenarios.first;

  bool get usesYoungCropSchedule => status == 'young_crop_reference';

  FertilizerApplication? get nextYoungCropApplication => usesYoungCropSchedule
      ? conventionalScenario?.nextApplicationForAge(plantAgeMonths)
      : null;

  FertilizerScenario? get diagnosticSummaryScenario =>
      usesYoungCropSchedule ? null : conventionalScenario;

  factory FertilizationRecommendation.fromJson(Map<String, dynamic> json) {
    return FertilizationRecommendation(
      planId: json['plan_id'] as String?,
      sourceType: json['source_type'] as String?,
      sourceRecordedAt: json['source_recorded_at'] == null
          ? null
          : DateTime.parse(json['source_recorded_at'] as String).toLocal(),
      parcelId: json['parcel_id'] as String,
      crop: json['crop'] as String,
      variety: json['variety'] as String,
      plantAgeMonths: json['plant_age_months'] as int,
      lifeStage: json['life_stage'] as String,
      fruitStage: json['fruit_stage'] as String,
      targetGreenKgHa: (json['target_green_kg_ha'] as num).toDouble(),
      engineVersion: json['engine_version'] as String,
      status: json['recommendation_status'] as String,
      nutrientRequirements: (json['nutrient_requirements'] as List<dynamic>)
          .map(
            (item) =>
                NutrientRequirement.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      scenarios: (json['fertilizer_scenarios'] as List<dynamic>)
          .map(
            (item) => FertilizerScenario.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      limitingNutrients: (json['limiting_nutrients'] as List<dynamic>)
          .cast<String>(),
      warnings: (json['warnings'] as List<dynamic>).cast<String>(),
      assumptions: (json['assumptions'] as List<dynamic>).cast<String>(),
    );
  }
}

List<FertilizerProductDose> _productList(dynamic value) {
  return (value as List<dynamic>? ?? const [])
      .map(
        (item) => FertilizerProductDose.fromJson(item as Map<String, dynamic>),
      )
      .toList(growable: false);
}

FertilizerProductDose? _sourceFor(
  List<FertilizerProductDose> products,
  String nutrient,
) {
  FertilizerProductDose? result;
  var largestContribution = 0.0;
  for (final product in products) {
    final contribution = product.nutrientContributions[nutrient] ?? 0;
    if (contribution > largestContribution) {
      result = product;
      largestContribution = contribution;
    }
  }
  return result;
}
