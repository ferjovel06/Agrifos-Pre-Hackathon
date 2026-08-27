import '../../domain/entities/fertilization_recommendation.dart';
import 'api_client.dart';

class FertilizationRepository {
  FertilizationRepository({ApiClient? client})
    : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<FertilizationRecommendation> createRecommendation({
    required String parcelId,
    required double targetYield,
    required String yieldUnit,
    required String fruitStage,
    required String soilSource,
    required String nitrogenStatus,
    required String phosphorusStatus,
    required String potassiumStatus,
    String? phosphorusMethod,
    String? potassiumMethod,
    double? ph,
    double? electricalConductivity,
  }) async {
    final response = await _client.post('/fertilization/recommendations', {
      'parcel_id': parcelId,
      'target_yield': targetYield,
      'yield_unit': yieldUnit,
      'fruit_stage': fruitStage,
      'soil': {
        'source': soilSource,
        'nitrogen': nitrogenStatus,
        'phosphorus': phosphorusStatus,
        'potassium': potassiumStatus,
        if (phosphorusMethod != null)
          'phosphorus_method': phosphorusMethod,
        if (potassiumMethod != null) 'potassium_method': potassiumMethod,
        if (ph != null) 'ph': ph,
        if (electricalConductivity != null) 'ec_ds_m': electricalConductivity,
      },
    });
    return FertilizationRecommendation.fromJson(response);
  }
}
