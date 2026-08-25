import 'package:app_flutter/domain/entities/phenological_stage.dart';
import 'package:app_flutter/presentation/sensor/widgets/phenological_stage_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows completed, active, and pending stages in order', (
    tester,
  ) async {
    const stages = [
      PhenologicalStageTemplate(
        id: 'growth',
        cropId: 'coffee',
        name: 'Crecimiento',
        stageOrder: 1,
        durationDays: 548,
      ),
      PhenologicalStageTemplate(
        id: 'flowering',
        cropId: 'coffee',
        name: 'Floración',
        stageOrder: 2,
        durationDays: 183,
      ),
      PhenologicalStageTemplate(
        id: 'harvest',
        cropId: 'coffee',
        name: 'Cosecha',
        stageOrder: 3,
        durationDays: null,
      ),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PhenologicalStageCard(stages: stages, currentStageOrder: 2),
          ),
        ),
      ),
    );

    expect(find.text('Etapa fenológica'), findsOneWidget);
    expect(find.text('Crecimiento'), findsOneWidget);
    expect(find.text('Floración'), findsOneWidget);
    expect(find.text('Cosecha'), findsOneWidget);
    expect(find.text('Activa'), findsOneWidget);
    expect(find.text('0 – 18 meses'), findsOneWidget);
    expect(find.text('18 – 24 meses'), findsOneWidget);
    expect(find.text('24+ meses'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.byIcon(Icons.eco_outlined), findsOneWidget);
  });
}
