import 'package:app_flutter/presentation/sensor/widgets/input_data_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('edits and submits the expected yield', (tester) async {
    String? changed;
    String? submitted;
    var recalculations = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InputDataCard(
            parcelName: 'Lote norte',
            cropName: 'Café',
            varietyName: 'Caturra',
            stageName: 'Llenado',
            ageMonths: 40,
            plantsPerHectare: 5000,
            targetYield: '20',
            onTargetYieldChanged: (value) => changed = value,
            onTargetYieldSubmitted: (value) => submitted = value,
            onRecalculate: () => recalculations++,
            isRecalculating: false,
          ),
        ),
      ),
    );

    expect(find.text('qq oro/ha'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '27,5');
    await tester.testTextInput.receiveAction(TextInputAction.done);

    expect(changed, '27,5');
    expect(submitted, '27,5');
    await tester.tap(find.text('Recalcular plan'));
    expect(recalculations, 1);
  });

  testWidgets('shows the expected-yield validation error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InputDataCard(
            parcelName: 'Lote norte',
            cropName: 'Café',
            varietyName: 'Caturra',
            stageName: 'Llenado',
            ageMonths: 40,
            plantsPerHectare: 5000,
            targetYield: '0',
            targetYieldError: 'Ingresa un rendimiento mayor que cero.',
            onTargetYieldChanged: (_) {},
            onTargetYieldSubmitted: (_) {},
            onRecalculate: null,
            isRecalculating: false,
          ),
        ),
      ),
    );

    expect(find.text('Ingresa un rendimiento mayor que cero.'), findsOneWidget);
  });

  testWidgets('hides expected yield before initial production', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InputDataCard(
            parcelName: 'Lote joven',
            cropName: 'Café',
            varietyName: 'Caturra',
            stageName: 'Crecimiento',
            ageMonths: 18,
            plantsPerHectare: 5000,
            targetYield: '20',
            onTargetYieldChanged: (_) {},
            onTargetYieldSubmitted: (_) {},
            onRecalculate: () {},
            isRecalculating: false,
          ),
        ),
      ),
    );

    expect(find.text('RENDIMIENTO ESPERADO'), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Recalcular plan'), findsNothing);
  });
}
