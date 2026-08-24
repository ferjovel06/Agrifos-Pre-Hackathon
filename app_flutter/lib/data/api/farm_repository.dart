import '../../domain/entities/farm.dart';
import 'api_client.dart';

/// Talks to the Agrifos backend's `/farms` endpoints.
class FarmRepository {
  final ApiClient _client;

  FarmRepository({ApiClient? client}) : _client = client ?? ApiClient();

  /// Fetches every farm owned by the current user.
  Future<List<Farm>> getFarms() async {
    final response = await _client.get('/farms');
    final list = (response as List).cast<Map<String, dynamic>>();
    return list.map(Farm.fromJson).toList();
  }

  /// Creates a new farm for the current user.
  Future<Farm> createFarm({
    required String name,
    required double areaHectares,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _client.post('/farms', {
      'name': name,
      'area_hectares': areaHectares,
      'latitude': latitude,
      'longitude': longitude,
    });
    return Farm.fromJson(response as Map<String, dynamic>);
  }
}