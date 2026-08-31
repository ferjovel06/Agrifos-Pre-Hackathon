import 'package:app_flutter/domain/entities/fertilization_recommendation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preserves the complete fertilization response', () {
    final recommendation = FertilizationRecommendation.fromJson({
      'plan_id': 'plan-1',
      'source_type': 'laboratory',
      'source_recorded_at': '2026-08-31T12:00:00Z',
      'parcel_id': 'parcel-1',
      'crop': 'Café',
      'variety': 'Caturra',
      'plant_age_months': 40,
      'life_stage': 'initial_production',
      'fruit_stage': 'expansion',
      'target_green_kg_ha': 920,
      'engine_version': 'coffee-fertilization-1.0.0',
      'recommendation_status': 'reference_plan',
      'nutrient_requirements': [
        {
          'nutrient': 'N',
          'unit': 'kg/ha',
          'exported_kg_ha': 28.4,
          'total_demand_kg_ha': 34.1,
          'soil_credit_kg_ha': 10,
          'fertilizer_requirement_kg_ha': 24.1,
          'soil_status': 'deficient',
        },
      ],
      'fertilizer_scenarios': [
        {
          'name': 'Económico',
          'selection_method': 'documented_cascade',
          'is_mathematically_valid': true,
          'products': [_productJson(25)],
          'application_schedule': [
            {
              'application_number': 1,
              'moment': 'Inicio de lluvias',
              'fraction': 0.25,
              'products': [_productJson(6.25)],
            },
          ],
        },
      ],
      'limiting_nutrients': ['N'],
      'warnings': ['Verificar condiciones locales.'],
      'assumptions': ['Eficiencia de referencia.'],
    });

    expect(recommendation.planId, 'plan-1');
    expect(recommendation.sourceType, 'laboratory');
    expect(recommendation.sourceRecordedAt, isNotNull);
    expect(recommendation.nutrientRequirements.single.totalDemandKgHa, 34.1);
    expect(
      recommendation.scenarios.single.selectionMethod,
      'documented_cascade',
    );
    expect(
      recommendation.scenarios.single.applicationSchedule.single.fraction,
      0.25,
    );
    expect(recommendation.limitingNutrients, ['N']);
    expect(recommendation.assumptions, ['Eficiencia de referencia.']);
  });
}

Map<String, dynamic> _productJson(double kgHa) => {
  'product_key': 'urea',
  'product': 'Urea',
  'guaranteed_analysis_pct': {'N': 46},
  'kg_ha': kgHa,
  'kg_manzana': kgHa * 0.704,
  'g_plant': kgHa / 5,
  'nutrient_contributions_kg_ha': {'N': kgHa * 0.46},
};
