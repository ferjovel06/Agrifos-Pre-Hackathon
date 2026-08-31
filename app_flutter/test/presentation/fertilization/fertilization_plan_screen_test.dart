import 'package:app_flutter/domain/entities/fertilization_recommendation.dart';
import 'package:app_flutter/presentation/fertilization/fertilization_plan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows calculated requirements and application schedule', (
    tester,
  ) async {
    const product = FertilizerProductDose(
      product: 'Urea',
      guaranteedAnalysis: {'N': 46},
      kgPerHectare: 25,
      kgPerManzana: 17.6,
      gramsPerPlant: 5,
      nutrientContributions: {'N': 11.5},
    );
    const recommendation = FertilizationRecommendation(
      crop: 'Café',
      variety: 'Caturra',
      plantAgeMonths: 40,
      lifeStage: 'initial_production',
      targetGreenKgHa: 920,
      status: 'reference_plan',
      engineVersion: '1.0.0',
      nutrientRequirements: [
        NutrientRequirement(
          nutrient: 'N',
          unit: 'kg/ha',
          exportedKgHa: 28,
          totalDemandKgHa: 34,
          soilCreditKgHa: 10,
          fertilizerRequirementKgHa: 24,
          soilStatus: 'deficient',
        ),
      ],
      scenarios: [
        FertilizerScenario(
          name: 'Económico',
          products: [product],
          applicationSchedule: [
            FertilizerApplication(
              number: 1,
              moment: 'Inicio de lluvias',
              fraction: 0.25,
              products: [product],
            ),
          ],
        ),
      ],
      warnings: ['Verificar condiciones locales.'],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: FertilizationPlanScreen(recommendation: recommendation),
      ),
    );

    expect(find.text('Necesidades del cultivo'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
    expect(find.text('Aplicaciones'), findsOneWidget);

    await tester.tap(find.text('Aplicaciones'));
    await tester.pumpAndSettle();

    expect(find.text('Calendario de aplicación'), findsOneWidget);
    expect(find.textContaining('Inicio de lluvias'), findsOneWidget);
  });
}
