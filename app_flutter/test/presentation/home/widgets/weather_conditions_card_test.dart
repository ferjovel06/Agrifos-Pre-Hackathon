import 'package:app_flutter/domain/entities/weather_forecast.dart';
import 'package:app_flutter/presentation/home/widgets/weather_conditions_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows current conditions and available weather values', (
    tester,
  ) async {
    final forecast = _forecast();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeatherConditionsCard(forecast: forecast, isLoading: false),
        ),
      ),
    );

    expect(find.text('CONDICIONES ACTUALES'), findsOneWidget);
    expect(find.text('Datos: Open-Meteo'), findsOneWidget);
    expect(find.text('Condiciones favorables para labores'), findsOneWidget);
    expect(find.text('24°C'), findsOneWidget);
    expect(find.text('72% humedad'), findsOneWidget);
    expect(find.text('12 km/h'), findsOneWidget);
    expect(find.text('0.0 mm'), findsOneWidget);
    expect(
      find.text('No se esperan lluvias durante las próximas 72 horas.'),
      findsOneWidget,
    );
  });

  testWidgets('shows a compact retry state when weather is unavailable', (
    tester,
  ) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeatherConditionsCard(
            forecast: null,
            isLoading: false,
            errorMessage: 'provider error',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Clima no disponible'), findsOneWidget);
    expect(find.text('provider error'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    expect(retried, isTrue);
  });
}

WeatherForecast _forecast() {
  return WeatherForecast(
    farmId: 'farm',
    provider: 'Open-Meteo',
    current: CurrentWeather(
      observedAt: DateTime(2026, 8, 27, 10),
      temperatureC: 24,
      relativeHumidityPct: 72,
      precipitationMm: 0,
      weatherCode: 1,
      condition: 'Parcialmente nublado',
      windSpeedKmh: 12,
    ),
    daily: [
      for (var day = 0; day < 3; day++)
        DailyWeather(
          date: DateTime(2026, 8, 27 + day),
          temperatureMaxC: 28,
          precipitationMm: 0,
        ),
    ],
  );
}
