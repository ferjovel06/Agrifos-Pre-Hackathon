import 'package:flutter/foundation.dart';

import '../../data/api/api_client.dart';
import '../../data/api/weather_repository.dart';
import '../../domain/entities/weather_forecast.dart';

enum WeatherStatus { initial, loading, loaded, error }

class WeatherProvider extends ChangeNotifier {
  final WeatherRepository _repository;

  WeatherProvider({WeatherRepository? repository})
    : _repository = repository ?? WeatherRepository();

  WeatherStatus status = WeatherStatus.initial;
  WeatherForecast? forecast;
  String? errorMessage;
  String? _loadedFarmId;
  DateTime? _loadedAt;

  static const _cacheDuration = Duration(minutes: 30);

  void clear() {
    status = WeatherStatus.initial;
    forecast = null;
    errorMessage = null;
    _loadedFarmId = null;
    _loadedAt = null;
    notifyListeners();
  }

  Future<void> fetchForecast(String farmId, {bool force = false}) async {
    final loadedAt = _loadedAt;
    if (!force &&
        status == WeatherStatus.loaded &&
        forecast != null &&
        _loadedFarmId == farmId &&
        loadedAt != null &&
        DateTime.now().difference(loadedAt) < _cacheDuration) {
      return;
    }

    status = WeatherStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      forecast = await _repository.getForecast(farmId);
      _loadedFarmId = farmId;
      _loadedAt = DateTime.now();
      status = WeatherStatus.loaded;
    } on ApiAuthException catch (error) {
      forecast = null;
      status = WeatherStatus.error;
      errorMessage = error.message;
    } on ApiException catch (error) {
      forecast = null;
      status = WeatherStatus.error;
      errorMessage = error.message;
    } catch (_) {
      forecast = null;
      status = WeatherStatus.error;
      errorMessage = 'No pudimos consultar el clima en este momento.';
    }
    notifyListeners();
  }
}
