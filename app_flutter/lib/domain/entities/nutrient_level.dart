import 'package:flutter/material.dart';

/// Qualitative interpretation of a soil nutrient value, used only to pick a
/// display color — the numeric value itself is always what's shown.
enum NutrientLevel { low, adequate, high }

/// Generic soil-test reference ranges (mg/kg) for N, P and K.
///
/// TODO(agrifos): these are provisional, crop-agnostic thresholds so the
/// "Última Lectura Global" card can color-code values today. Once the
/// fertilization/diagnostic engine (see `OptimalRequirement` in
/// `fertilization_engine.py`) is wired up, replace this with per-crop /
/// per-soil-type thresholds from the backend instead of a static table.
class NpkThresholds {
  const NpkThresholds._();

  static NutrientLevel nitrogen(double mgPerKg) {
    if (mgPerKg < 20) return NutrientLevel.low;
    if (mgPerKg <= 40) return NutrientLevel.adequate;
    return NutrientLevel.high;
  }

  static NutrientLevel phosphorus(double mgPerKg) {
    if (mgPerKg < 15) return NutrientLevel.low;
    if (mgPerKg <= 30) return NutrientLevel.adequate;
    return NutrientLevel.high;
  }

  static NutrientLevel potassium(double mgPerKg) {
    if (mgPerKg < 100) return NutrientLevel.low;
    if (mgPerKg <= 200) return NutrientLevel.adequate;
    return NutrientLevel.high;
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
}