class FertilizerProductDose {
  const FertilizerProductDose({
    required this.product,
    required this.guaranteedAnalysis,
    required this.kgPerHectare,
    required this.kgPerManzana,
    required this.gramsPerPlant,
    required this.nutrientContributions,
  });

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

class FertilizerScenario {
  const FertilizerScenario({required this.name, required this.products});

  final String name;
  final List<FertilizerProductDose> products;

  factory FertilizerScenario.fromJson(Map<String, dynamic> json) {
    return FertilizerScenario(
      name: json['name'] as String,
      products: (json['products'] as List<dynamic>)
          .map(
            (item) =>
                FertilizerProductDose.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  FertilizerProductDose? sourceFor(String nutrient) {
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
}

class FertilizationRecommendation {
  const FertilizationRecommendation({
    required this.status,
    required this.scenarios,
    required this.warnings,
  });

  final String status;
  final List<FertilizerScenario> scenarios;
  final List<String> warnings;

  FertilizerScenario? get conventionalScenario =>
      scenarios.isEmpty ? null : scenarios.first;

  factory FertilizationRecommendation.fromJson(Map<String, dynamic> json) {
    return FertilizationRecommendation(
      status: json['recommendation_status'] as String,
      scenarios: (json['fertilizer_scenarios'] as List<dynamic>)
          .map(
            (item) => FertilizerScenario.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      warnings: (json['warnings'] as List<dynamic>).cast<String>(),
    );
  }
}
