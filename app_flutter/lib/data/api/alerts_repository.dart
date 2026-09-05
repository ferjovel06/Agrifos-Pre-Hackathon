import '../../domain/entities/climate_alert.dart';
import 'api_client.dart';

class AlertsRepository {
  AlertsRepository({ApiClient? client}) : _client = client ?? ApiClient();
  final ApiClient _client;

  Future<List<ClimateAlert>> load(
    String farmId, {
    bool evaluate = false,
  }) async {
    final dynamic response = evaluate
        ? (await _client.post(
            '/alerts/farms/$farmId/evaluate',
            {},
          ))['active_alerts']
        : await _client.get('/alerts/farms/$farmId');
    return (response as List)
        .map((item) => ClimateAlert.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
