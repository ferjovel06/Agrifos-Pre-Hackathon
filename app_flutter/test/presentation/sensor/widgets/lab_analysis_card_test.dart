import 'package:app_flutter/domain/entities/lab_analysis.dart';
import 'package:app_flutter/presentation/sensor/widgets/lab_analysis_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('offers registration when no analyses exist', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LabAnalysisCard(
            analyses: const [],
            isLoading: false,
            onManage: () {},
          ),
        ),
      ),
    );

    expect(find.text('Análisis de laboratorio'), findsOneWidget);
    expect(find.text('Registrar'), findsOneWidget);
    expect(find.textContaining('Registra los resultados'), findsOneWidget);
  });

  testWidgets('shows the latest analysis summary', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LabAnalysisCard(
            analyses: [_analysis()],
            isLoading: false,
            onManage: () {},
          ),
        ),
      ),
    );

    expect(find.text('Gestionar'), findsOneWidget);
    expect(find.text('M-001'), findsOneWidget);
    expect(find.text('5.8'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });
}

LabAnalysis _analysis() => LabAnalysis(
  id: 'analysis-1',
  parcelId: 'parcel-1',
  sampleCode: 'M-001',
  sampledAt: DateTime(2026, 8, 20),
  depthStartCm: 0,
  depthEndCm: 20,
  lab: 'Laboratorio Agrícola',
  ph: 5.8,
  phMethod: 'Agua',
  ec: 0.4,
  ecMethod: 'Extracto',
  organicMatterPct: 4.2,
  cic: 18,
  clayPct: 30,
  siltPct: 30,
  sandPct: 40,
  nitrogen: 24,
  phosphorus: 12,
  phosphorusMethod: 'Bray II',
  potassium: 110,
  potassiumMethod: 'Acetato',
  calcium: 1200,
  magnesium: 180,
  sulfur: 14,
  recordedAt: DateTime(2026, 8, 21),
);
