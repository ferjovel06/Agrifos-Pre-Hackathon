import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/domain/reference/soil_reference_ranges.dart';

void main() {
  group('classifySoilParameter — pH (deficient/optimal/high/critical)', () {
    test('por debajo de 5.0 es deficiente', () {
      expect(classifySoilParameter(SoilParameterId.ph, 4.9),
          SoilLevel.deficient);
    });
    test('5.0 (límite inferior) es óptimo', () {
      expect(classifySoilParameter(SoilParameterId.ph, 5.0), SoilLevel.optimal);
    });
    test('5.5 (límite superior) sigue siendo óptimo', () {
      expect(classifySoilParameter(SoilParameterId.ph, 5.5), SoilLevel.optimal);
    });
    test('5.6 es "high" (zona de alerta, aún no crítico)', () {
      expect(classifySoilParameter(SoilParameterId.ph, 5.6), SoilLevel.high);
    });
    test('6.0 (límite critical_above) ya es crítico', () {
      expect(classifySoilParameter(SoilParameterId.ph, 6.0), SoilLevel.critical);
    });
  });

  group('classifySoilParameter — Sodio (sin umbral de deficiencia)', () {
    test('valor bajo es óptimo, no deficiente', () {
      expect(classifySoilParameter(SoilParameterId.sodium, 0),
          SoilLevel.optimal);
    });
    test('150 mg/kg es "high" (zona de monitoreo)', () {
      expect(classifySoilParameter(SoilParameterId.sodium, 150), SoilLevel.high);
    });
    test('1000 mg/kg (límite critical_above) es crítico', () {
      expect(classifySoilParameter(SoilParameterId.sodium, 1000),
          SoilLevel.critical);
    });
  });

  group('classifySoilParameter — Saturación de bases total (zona gris 20–30%)', () {
    test('15% (bajo deficient_below) es deficiente', () {
      expect(
          classifySoilParameter(SoilParameterId.baseSaturationTotal, 15),
          SoilLevel.deficient);
    });
    test('25% (entre deficient_below y optimal_min, sin evidencia explícita) '
        'se clasifica igualmente como deficiente', () {
      expect(
          classifySoilParameter(SoilParameterId.baseSaturationTotal, 25),
          SoilLevel.deficient);
    });
    test('30% (optimal_min) es óptimo', () {
      expect(
          classifySoilParameter(SoilParameterId.baseSaturationTotal, 30),
          SoilLevel.optimal);
    });
    test('79% sigue óptimo (optimal_max abierto)', () {
      expect(
          classifySoilParameter(SoilParameterId.baseSaturationTotal, 79),
          SoilLevel.optimal);
    });
    test('80% (critical_above) es crítico', () {
      expect(
          classifySoilParameter(SoilParameterId.baseSaturationTotal, 80),
          SoilLevel.critical);
    });
  });

  group('classifySoilParameter — Nitrato-N (usado para el card de Nitrógeno)', () {
    test('5 mg/kg es deficiente', () {
      expect(classifySoilParameter(SoilParameterId.nitrateN, 5),
          SoilLevel.deficient);
    });
    test('20 mg/kg es óptimo', () {
      expect(classifySoilParameter(SoilParameterId.nitrateN, 20),
          SoilLevel.optimal);
    });
    test('40 mg/kg es "high"', () {
      expect(
          classifySoilParameter(SoilParameterId.nitrateN, 40), SoilLevel.high);
    });
  });
}