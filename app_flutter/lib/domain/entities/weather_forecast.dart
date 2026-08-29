class CurrentWeather {
  final DateTime observedAt;
  final double temperatureC;
  final int relativeHumidityPct;
  final double precipitationMm;
  final int weatherCode;
  final String condition;
  final double windSpeedKmh;

  const CurrentWeather({
    required this.observedAt,
    required this.temperatureC,
    required this.relativeHumidityPct,
    required this.precipitationMm,
    required this.weatherCode,
    required this.condition,
    required this.windSpeedKmh,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      observedAt: DateTime.parse(json['observed_at'] as String).toLocal(),
      temperatureC: (json['temperature_c'] as num).toDouble(),
      relativeHumidityPct: (json['relative_humidity_pct'] as num).toInt(),
      precipitationMm: (json['precipitation_mm'] as num).toDouble(),
      weatherCode: (json['weather_code'] as num).toInt(),
      condition: json['condition'] as String,
      windSpeedKmh: (json['wind_speed_kmh'] as num).toDouble(),
    );
  }
}

class DailyWeather {
  final DateTime date;
  final double temperatureMaxC;
  final double precipitationMm;

  const DailyWeather({
    required this.date,
    required this.temperatureMaxC,
    required this.precipitationMm,
  });

  factory DailyWeather.fromJson(Map<String, dynamic> json) {
    return DailyWeather(
      date: DateTime.parse(json['date'] as String),
      temperatureMaxC: (json['temperature_max_c'] as num).toDouble(),
      precipitationMm: (json['precipitation_mm'] as num).toDouble(),
    );
  }
}

class WeatherForecast {
  final String farmId;
  final String provider;
  final CurrentWeather current;
  final List<DailyWeather> daily;

  const WeatherForecast({
    required this.farmId,
    required this.provider,
    required this.current,
    required this.daily,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      farmId: json['farm_id'] as String,
      provider: json['provider'] as String,
      current: CurrentWeather.fromJson(json['current'] as Map<String, dynamic>),
      daily: (json['daily'] as List)
          .cast<Map<String, dynamic>>()
          .map(DailyWeather.fromJson)
          .toList(),
    );
  }

  double get precipitationNext72Hours =>
      daily.take(3).fold(0, (total, day) => total + day.precipitationMm);

  double get maximumTemperatureNext72Hours =>
      daily.take(3).fold(current.temperatureC, (maximum, day) {
        return day.temperatureMaxC > maximum ? day.temperatureMaxC : maximum;
      });
}
