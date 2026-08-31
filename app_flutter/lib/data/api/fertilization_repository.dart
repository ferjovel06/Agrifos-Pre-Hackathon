import '../../domain/entities/fertilization_recommendation.dart';
import 'api_client.dart';

class FertilizationRepository {
  FertilizationRepository({ApiClient? client})
    : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<FertilizationRecommendation> createFromLabAnalysis({
    required String parcelId,
    required String labAnalysisId,
    double? targetYield,
    required String yieldUnit,
    required String fruitStage,
  }) async {
    final body = <String, dynamic>{
      'parcel_id': parcelId,
      'lab_analysis_id': labAnalysisId,
      'target_yield': targetYield,
      'yield_unit': yieldUnit,
      'fruit_stage': fruitStage,
    }..removeWhere((_, value) => value == null);
    final response = await _client.post('/fertilization/recommendations', body);
    return FertilizationRecommendation.fromJson(response);
  }

  Future<FertilizationRecommendation> createRecommendation({
    required String parcelId,
    String? readingId,
    double? targetYield,
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
    final soil = <String, dynamic>{
      'source': soilSource,
      'nitrogen': nitrogenStatus,
      'phosphorus': phosphorusStatus,
      'potassium': potassiumStatus,
      'phosphorus_method': phosphorusMethod,
      'potassium_method': potassiumMethod,
      'ph': ph,
      'ec_ds_m': electricalConductivity,
    }..removeWhere((_, value) => value == null);
    final body = <String, dynamic>{
      'parcel_id': parcelId,
      'reading_id': readingId,
      'target_yield': targetYield,
      'yield_unit': yieldUnit,
      'fruit_stage': fruitStage,
      'soil': soil,
    }..removeWhere((_, value) => value == null);
    final response = await _client.post('/fertilization/recommendations', body);
    return FertilizationRecommendation.fromJson(response);
  }
}
