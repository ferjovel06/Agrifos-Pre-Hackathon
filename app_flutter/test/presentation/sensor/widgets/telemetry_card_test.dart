import 'package:app_flutter/data/sensor/usb_sensor_service.dart';
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
