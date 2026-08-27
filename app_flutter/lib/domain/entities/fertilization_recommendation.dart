class FertilizerProductDose {
  const FertilizerProductDose({
    required this.product,
    required this.kgPerHectare,
    required this.kgPerManzana,
    required this.gramsPerPlant,
    required this.nutrientContributions,
  });

  final String product;
  final double kgPerHectare;
  final double kgPerManzana;
  final double gramsPerPlant;
  final Map<String, double> nutrientContributions;

  factory FertilizerProductDose.fromJson(Map<String, dynamic> json) {
    final contributions = json['nutrient_contributions_kg_ha'] as Map;
    return FertilizerProductDose(
      product: json['product'] as String,
      kgPerHectare: (json['kg_ha'] as num).toDouble(),
      kgPerManzana: (json['kg_manzana'] as num).toDouble(),
      gramsPerPlant: (json['g_plant'] as num).toDouble(),
      nutrientContributions: contributions.map(
        (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
      ),
    );
  }

  String get displayName {
    switch (product.toLowerCase()) {
      case 'urea':
        return 'Urea (46-0-0)';
      case 'dap':
        return 'DAP (18-46-0)';
      case 'kcl':
        return 'KCl (0-0-60)';
      case 'sulfato de potasio':
        return 'Sulfato de potasio (0-0-50)';
      default:
        return product;
    }
  }
}

class FertilizerScenario {
  const FertilizerScenario({
    required this.name,
    required this.products,
  });

  final String name;
  final List<FertilizerProductDose> products;

  factory FertilizerScenario.fromJson(Map<String, dynamic> json) {
    return FertilizerScenario(
      name: json['name'] as String,
      products: (json['products'] as List<dynamic>)
          .map(
            (item) => FertilizerProductDose.fromJson(
              item as Map<String, dynamic>,
            ),
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
            (item) => FertilizerScenario.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
      warnings: (json['warnings'] as List<dynamic>).cast<String>(),
    );
  }
}
