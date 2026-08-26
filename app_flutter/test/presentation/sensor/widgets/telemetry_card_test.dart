import 'package:app_flutter/data/sensor/usb_sensor_service.dart';
import 'package:app_flutter/domain/entities/sensor_diagnostic.dart';
import 'package:app_flutter/presentation/sensor/sensor_provider.dart';
import 'package:app_flutter/presentation/sensor/widgets/telemetry_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows live telemetry and captures the current sample', (
    tester,
  ) async {
    var captured = false;
    final reading = SensorReading(
      nitrogen: 148,
      phosphorus: 62,
      potassium: 95,
      ec: 0.7,
      ph: 6.2,
      temperature: 24,
      humidity: 72,
    );

    await tester.pumpWidget(
      _TestApp(
        child: TelemetryCard(
          status: SensorStatus.connected,
          reading: reading,
          saveStatus: SaveStatus.idle,
          onAction: () => captured = true,
        ),
      ),
    );

    expect(find.text('Telemetría Sensor'), findsOneWidget);
    expect(find.text('CONEXIÓN SEGURA · USB'), findsOneWidget);
    expect(find.text('72%'), findsOneWidget);
    expect(find.text('24°C'), findsOneWidget);
    expect(find.text('6.2'), findsOneWidget);
    expect(find.text('148'), findsOneWidget);
    expect(find.text('62'), findsOneWidget);
    expect(find.text('95'), findsOneWidget);
    expect(find.text('Capturar muestra'), findsOneWidget);

    final phText = tester.widget<Text>(find.text('6.2'));
    expect(phText.style?.color, const Color(0xFFEF5350));

    await tester.tap(find.text('Capturar muestra'));
    expect(captured, isTrue);
  });

  testWidgets('shows a useful state when the sensor is disconnected', (
    tester,
  ) async {
    var connectRequested = false;

    await tester.pumpWidget(
      _TestApp(
        child: TelemetryCard(
          status: SensorStatus.disconnected,
          reading: null,
          saveStatus: SaveStatus.idle,
          onAction: () => connectRequested = true,
        ),
      ),
    );

    expect(find.text('SENSOR DESCONECTADO'), findsOneWidget);
    expect(find.text('Conectar sensor'), findsOneWidget);
    expect(
      find.text('Conecta el sensor por USB para comenzar la telemetría.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Conectar sensor'));
    expect(connectRequested, isTrue);
  });

  testWidgets('uses the backend diagnosis after saving a sample', (
    tester,
  ) async {
    final reading = SensorReading(
      nitrogen: 20,
      phosphorus: 15,
      potassium: 100,
      ec: 0.5,
      ph: 6.2,
      temperature: 24,
      humidity: 72,
    );
    const diagnosis = SensorDiagnostic(
      readingId: 'reading',
      crop: 'Café',
      engineVersion: 'sensor-diagnostic-1.0.0',
      overallConfidence: 'low',
      parameters: [
        DiagnosticParameter(
          parameter: 'ph',
          label: 'pH',
          value: 6.2,
          unit: 'SU',
          level: SoilDiagnosticLevel.optimal,
          message: 'Rango adecuado',
        ),
      ],
      warnings: [],
    );

    await tester.pumpWidget(
      _TestApp(
        child: TelemetryCard(
          status: SensorStatus.connected,
          reading: reading,
          saveStatus: SaveStatus.saved,
          diagnosis: diagnosis,
          onAction: () {},
        ),
      ),
    );

    expect(find.text('Diagnóstico preliminar'), findsOneWidget);
    final phText = tester.widget<Text>(find.text('6.2'));
    expect(phText.style?.color, const Color(0xFF3B8A61));
  });

  testWidgets('shows every altered parameter without laboratory text', (
    tester,
  ) async {
    final reading = SensorReading(
      nitrogen: 5,
      phosphorus: 5,
      potassium: 100,
      ec: 0.5,
      ph: 5.2,
      temperature: 24,
      humidity: 72,
    );
    const diagnosis = SensorDiagnostic(
      readingId: 'reading',
      crop: 'Café',
      engineVersion: 'sensor-diagnostic-1.0.0',
      overallConfidence: 'low',
      parameters: [],
      warnings: ['Nitrógeno bajo.', 'Fósforo bajo.'],
    );

    await tester.pumpWidget(
      _TestApp(
        child: TelemetryCard(
          status: SensorStatus.connected,
          reading: reading,
          saveStatus: SaveStatus.saved,
          diagnosis: diagnosis,
          onAction: () {},
        ),
      ),
    );

    expect(find.text('Nitrógeno bajo. · Fósforo bajo.'), findsOneWidget);
    expect(find.textContaining('laboratorio'), findsNothing);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.all(20), child: child),
        ),
      ),
    );
  }
}
