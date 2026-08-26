import 'package:app_flutter/domain/entities/sensor_diagnostic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a backend sensor diagnosis', () {
    final diagnosis = SensorDiagnostic.fromJson({
      'reading_id': 'reading-1',
      'crop': 'Café',
      'engine_version': 'sensor-diagnostic-1.0.0',
      'overall_confidence': 'low',
      'parameters': [
        {
          'parameter': 'ph',
          'label': 'pH',
          'value': 5.2,
          'unit': 'SU',
          'level': 'optimal',
          'message': 'Rango adecuado',
          'reference': {},
        },
      ],
      'warnings': ['Diagnóstico preliminar.'],
    });

    expect(diagnosis.readingId, 'reading-1');
    expect(diagnosis.confidenceLabel, 'confianza baja');
    expect(diagnosis.displayLabel, 'Diagnóstico preliminar');
    expect(diagnosis.parameter('ph')?.level, SoilDiagnosticLevel.optimal);
    expect(diagnosis.parameter('ph')?.message, 'Rango adecuado');
    expect(diagnosis.parameter('potassium'), isNull);
  });
}
