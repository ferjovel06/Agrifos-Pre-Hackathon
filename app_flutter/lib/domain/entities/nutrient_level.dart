import 'package:flutter/material.dart';

import '../reference/soil_reference_ranges.dart';

/// Qualitative interpretation of a soil nutrient value, used only to pick a
/// display color — the numeric value itself is always what's shown.
enum NutrientLevel { low, adequate, high }

class NpkThresholds {
  const NpkThresholds._();

  static NutrientLevel nitrogen(double mgPerKg) => _toNutrientLevel(
    classifySoilParameter(SoilParameterId.nitrateN, mgPerKg),
  );

  static NutrientLevel phosphorus(double mgPerKg) => _toNutrientLevel(
    classifySoilParameter(SoilParameterId.phosphateP, mgPerKg),
  );

  static NutrientLevel potassium(double mgPerKg) => _toNutrientLevel(
    classifySoilParameter(SoilParameterId.potassium, mgPerKg),
  );

  static NutrientLevel _toNutrientLevel(SoilLevel level) {
    switch (level) {
      case SoilLevel.deficient:
        return NutrientLevel.low;
      case SoilLevel.optimal:
        return NutrientLevel.adequate;
      case SoilLevel.high:
      case SoilLevel.critical:
        return NutrientLevel.high;
    }
  }

  static Color colorFor(NutrientLevel level) {
    switch (level) {
      case NutrientLevel.low:
        return const Color(0xFFD64545);
      case NutrientLevel.adequate:
        return const Color(0xFF2563EB);
      case NutrientLevel.high:
        return const Color(0xFFE08A2C);
    }
  }

  static String messageFor(NutrientLevel level) {
    switch (level) {
      case NutrientLevel.low:
        return 'Nivel bajo';
      case NutrientLevel.adequate:
        return 'Rango óptimo';
      case NutrientLevel.high:
        return 'Nivel alto';
    }
  }
}
