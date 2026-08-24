import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/domain/entities/nutrient_level.dart';

void main() {
  group('NpkThresholds — Nitrógeno', () {
    test('5 mg/kg -> low', () {
      expect(NpkThresholds.nitrogen(5), NutrientLevel.low);
    });
    test('20 mg/kg -> adequate', () {
      expect(NpkThresholds.nitrogen(20), NutrientLevel.adequate);
    });
    test('40 mg/kg -> high', () {
      expect(NpkThresholds.nitrogen(40), NutrientLevel.high);
    });
  });

  group('NpkThresholds — Fósforo', () {
    test('5 mg/kg -> low', () {
      expect(NpkThresholds.phosphorus(5), NutrientLevel.low);
    });
    test('15 mg/kg -> adequate', () {
      expect(NpkThresholds.phosphorus(15), NutrientLevel.adequate);
    });
    test('25 mg/kg -> high', () {
      expect(NpkThresholds.phosphorus(25), NutrientLevel.high);
    });
  });

  group('NpkThresholds — Potasio', () {
    test('50 mg/kg -> low', () {
      expect(NpkThresholds.potassium(50), NutrientLevel.low);
    });
    test('100 mg/kg -> adequate', () {
      expect(NpkThresholds.potassium(100), NutrientLevel.adequate);
    });
    test('200 mg/kg -> high', () {
      expect(NpkThresholds.potassium(200), NutrientLevel.high);
    });
  });

  group('NpkThresholds.colorFor', () {
    test('cada nivel mapea a un color distinto', () {
      expect(NpkThresholds.colorFor(NutrientLevel.low),
          const Color(0xFFD64545));
      expect(NpkThresholds.colorFor(NutrientLevel.adequate),
          const Color(0xFF2563EB));
      expect(NpkThresholds.colorFor(NutrientLevel.high),
          const Color(0xFFE08A2C));
    });
  });
}