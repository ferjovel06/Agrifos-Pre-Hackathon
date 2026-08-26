import '../../domain/entities/reading.dart';
import '../../domain/entities/sensor_diagnostic.dart';
import '../sensor/usb_sensor_service.dart';
import 'api_client.dart';

/// Sends sensor readings captured by the app to the Agrifos backend
class ReadingsRepository {
  final ApiClient _client;

  ReadingsRepository({ApiClient? client}) : _client = client ?? ApiClient();

  /// Submits [reading] for the given [parcelId].
  ///
  /// The USB sensor reports EC in µS/cm, but the backend stores and
  /// validates EC in dS/m (0-20 range), so it's converted here
  /// (1 dS/m = 1000 µS/cm) before sending.
  Future<Reading> submitReading({
    required String parcelId,
    required SensorReading reading,
  }) async {
    final response = await _client.post('/readings', {
      'parcel_id': parcelId,
      'nitrogen': reading.nitrogen,
      'phosphorus': reading.phosphorus,
      'potassium': reading.potassium,
      'ec': reading.ec / 1000,
      'ph': reading.ph,
      'temperature': reading.temperature,
      'humidity': reading.humidity,
    });
    return Reading.fromJson(response);
  }

  /// Fetches the most recent stored reading for [parcelId], or `null` if
  /// the parcel has no readings yet.
  ///
  /// Reuses `GET /readings` (already sorted newest-first) with `limit=1`
  /// instead of adding a dedicated "latest" endpoint.
  Future<Reading?> getLatestReading(String parcelId) async {
    final response = await _client.get(
      '/readings',
      query: {'parcel_id': parcelId, 'limit': '1'},
    );
    final list = (response as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) return null;
    final reading = Reading.fromJson(list.first);
    final diagnosisResponse = await _client.get(
      '/diagnostics/readings/${reading.id}',
    );
    return reading.copyWith(
      diagnosis: SensorDiagnostic.fromJson(
        diagnosisResponse as Map<String, dynamic>,
      ),
    );
  }
}
