import 'package:app_flutter/domain/entities/reading.dart';
import 'package:app_flutter/domain/entities/sensor_diagnostic.dart';
import 'package:app_flutter/presentation/home/widgets/last_reading_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cases = [
    (ph: 4.9, message: 'Acidez: requiere atención', color: Color(0xFFD64545)),
    (ph: 5.2, message: 'Rango óptimo', color: Color(0xFF2563EB)),
    (ph: 5.6, message: 'Alcalinidad', color: Color(0xFFE08A2C)),
    (ph: 6.0, message: 'Nivel crítico', color: Color(0xFFB91C1C)),
  ];

  for (final testCase in cases) {
    testWidgets('pH ${testCase.ph} uses its threshold color and message', (
      tester,
    ) async {
      final reading = Reading(
        id: 'reading',
        parcelId: 'parcel',
        nitrogen: 20,
        phosphorus: 15,
        potassium: 100,
        ec: 0.5,
        ph: testCase.ph,
        temperature: 24,
        humidity: 65,
        recordedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LastReadingCard(
                reading: reading,
                isLoading: false,
                isSensorConnected: false,
              ),
            ),
          ),
        ),
      );

      final value = tester.widget<Text>(
        find.text(testCase.ph.toStringAsFixed(1)),
      );
      expect(value.style?.color, testCase.color);
      expect(
        find.text(testCase.message),
        testCase.ph == 5.2 ? findsNWidgets(4) : findsOneWidget,
      );
      expect(find.text('Lectura informativa'), findsOneWidget);
    });
  }

  testWidgets('uses the server diagnosis for a stored reading', (tester) async {
    final reading = Reading(
      id: 'reading',
      parcelId: 'parcel',
      nitrogen: 20,
      phosphorus: 15,
      potassium: 100,
      ec: 0.5,
      ph: 5.2,
      temperature: 24,
      humidity: 65,
      recordedAt: DateTime.now(),
      diagnosis: const SensorDiagnostic(
        readingId: 'reading',
        crop: 'Café',
        engineVersion: 'sensor-diagnostic-1.0.0',
        overallConfidence: 'low',
        parameters: [
          DiagnosticParameter(
            parameter: 'nitrogen',
            label: 'Nitrógeno',
            value: 20,
            unit: 'mg/kg',
            level: SoilDiagnosticLevel.critical,
            message: 'Nivel crítico del servidor',
          ),
        ],
        warnings: ['Nitrógeno bajo.', 'Fósforo bajo.'],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LastReadingCard(
              reading: reading,
              isLoading: false,
              isSensorConnected: false,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Diagnóstico preliminar'), findsOneWidget);
    expect(find.text('Nivel crítico del servidor'), findsOneWidget);
    expect(find.text('• Nitrógeno bajo.'), findsOneWidget);
    expect(find.text('• Fósforo bajo.'), findsOneWidget);
    final nitrogenValue = tester.widget<Text>(find.text('20 mg/kg'));
    expect(nitrogenValue.style?.color, const Color(0xFFB91C1C));
  });
}
