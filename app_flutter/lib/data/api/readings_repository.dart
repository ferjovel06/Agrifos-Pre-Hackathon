import '../sensor/usb_sensor_service.dart';
import 'api_client.dart';

/// Sends sensor readings captured by the app to the Agrifos backend
/// (`POST /readings`), where they are validated and stored.
class ReadingsRepository {
  final ApiClient _client;

  ReadingsRepository({ApiClient? client}) : _client = client ?? ApiClient();

  /// Submits [reading] for the given [parcelId].
  ///
  /// The USB sensor reports EC in µS/cm, but the backend stores and
  /// validates EC in dS/m (0-20 range), so it's converted here
  /// (1 dS/m = 1000 µS/cm) before sending.
  Future<void> submitReading({
    required String parcelId,
    required SensorReading reading,
  }) async {
    await _client.post('/readings', {
      'parcel_id': parcelId,
      'nitrogen': reading.nitrogen,
      'phosphorus': reading.phosphorus,
      'potassium': reading.potassium,
      'ec': reading.ec / 1000,
      'ph': reading.ph,
      'temperature': reading.temperature,
      'humidity': reading.humidity,
    });
  }
}