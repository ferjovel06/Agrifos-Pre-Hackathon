import 'package:app_flutter/domain/entities/fertilization_recommendation.dart';
import 'package:app_flutter/presentation/sensor/widgets/conventional_fertilization_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows conventional NPK sources with doses and units', (
    tester,
  ) async {
    const scenario = FertilizerScenario(
      name: 'Económico',
      products: [
        FertilizerProductDose(
          product: 'Urea',
          guaranteedAnalysis: {'N': 46},
          kgPerHectare: 93.8,
          kgPerManzana: 66.1,
          gramsPerPlant: 0.60,
          nutrientContributions: {'N': 43.1},
        ),
        FertilizerProductDose(
          product: 'DAP',
          guaranteedAnalysis: {'N': 18, 'P2O5': 46},
          kgPerHectare: 42,
          kgPerManzana: 29.6,
          gramsPerPlant: 0.27,
          nutrientContributions: {'N': 7.6, 'P2O5': 19.3},
        ),
        FertilizerProductDose(
          product: 'KCl',
          guaranteedAnalysis: {'K2O': 60},
          kgPerHectare: 80.5,
          kgPerManzana: 56.7,
          gramsPerPlant: 0.52,
          nutrientContributions: {'K2O': 48.3},
        ),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ConventionalFertilizationCard(scenario: scenario)),
      ),
    );

    expect(find.text('Convencional'), findsOneWidget);
    expect(find.text('QUÍMICA'), findsOneWidget);
    expect(find.text('Urea (46-0-0)'), findsOneWidget);
    expect(find.text('DAP (18-46-0)'), findsOneWidget);
    expect(find.text('KCl (0-0-60)'), findsOneWidget);
    expect(find.textContaining('93.8'), findsOneWidget);
    expect(find.textContaining('42.0'), findsOneWidget);
    expect(find.textContaining('80.5'), findsOneWidget);
    expect(find.text('0.60 g/planta'), findsOneWidget);
  });

  testWidgets('explains why no recommendation can be displayed', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ConventionalFertilizationCard(scenario: null)),
      ),
    );

    expect(find.textContaining('Captura una muestra'), findsOneWidget);
    expect(find.textContaining('kg/ha'), findsNothing);
  });

  testWidgets('shows only the next young-crop application dose', (
    tester,
  ) async {
    const application = FertilizerApplication(
      number: 2,
      moment: 'Mes 6 de levante',
      monthAfterPlanting: 6,
      fraction: 0.20,
      products: [
        FertilizerProductDose(
          product: 'Urea',
          guaranteedAnalysis: {'N': 46},
          kgPerHectare: 91.2,
          kgPerManzana: 64.22,
          gramsPerPlant: 22.8,
          nutrientContributions: {'N': 41.95},
        ),
        FertilizerProductDose(
          product: 'DAP',
          guaranteedAnalysis: {'N': 18, 'P2O5': 46},
          kgPerHectare: 26.4,
          kgPerManzana: 18.59,
          gramsPerPlant: 6.6,
          nutrientContributions: {'P2O5': 12.14},
        ),
        FertilizerProductDose(
          product: 'KCl',
          guaranteedAnalysis: {'K2O': 60},
          kgPerHectare: 20,
          kgPerManzana: 14.08,
          gramsPerPlant: 5,
          nutrientContributions: {'K2O': 12},
        ),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ConventionalFertilizationCard(
            scenario: null,
            application: application,
          ),
        ),
      ),
    );

    expect(find.text('Próxima aplicación: Mes 6 de levante'), findsOneWidget);
    expect(find.text('20 %'), findsOneWidget);
    expect(find.textContaining('91.2'), findsOneWidget);
    expect(find.textContaining('26.4'), findsOneWidget);
    expect(find.textContaining('20.0'), findsOneWidget);
    expect(find.textContaining('456.0'), findsNothing);
  });
}
