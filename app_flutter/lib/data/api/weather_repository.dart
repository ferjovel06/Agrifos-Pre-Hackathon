import '../../domain/entities/weather_forecast.dart';
import 'api_client.dart';

class WeatherRepository {
  final ApiClient _client;

  WeatherRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<WeatherForecast> getForecast(String farmId, {int days = 3}) async {
    final response = await _client.get(
      '/weather/farms/$farmId/forecast',
      query: {'days': '$days'},
    );
    return WeatherForecast.fromJson(response as Map<String, dynamic>);
  }
}
