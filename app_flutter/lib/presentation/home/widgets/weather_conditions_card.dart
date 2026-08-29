import 'package:flutter/material.dart';

import '../../../domain/entities/weather_forecast.dart';

class WeatherConditionsCard extends StatelessWidget {
  const WeatherConditionsCard({
    super.key,
    required this.forecast,
    required this.isLoading,
    this.errorMessage,
    this.onRetry,
  });

  final WeatherForecast? forecast;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  static const _radius = 20.0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: SizedBox(
        width: double.infinity,
        height: 190,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/backgrounds/weather_background.png',
              fit: BoxFit.cover,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xEE2B1A14),
                    Color(0xC92B1A14),
                    Color(0x7531543B),
                  ],
                ),
              ),
            ),
            Padding(padding: const EdgeInsets.all(18), child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      );
    }
    if (errorMessage != null || forecast == null) {
      return _WeatherUnavailable(message: errorMessage, onRetry: onRetry);
    }

    final data = forecast!;
    final presentation = _WeatherPresentation.fromForecast(data);
    final current = data.current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.circle, size: 7, color: Color(0xFF6FB782)),
            const SizedBox(width: 7),
            const Text(
              'CONDICIONES ACTUALES',
              style: TextStyle(
                color: Color(0xFFD7D2CA),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            Text(
              'Datos: ${data.provider}',
              style: const TextStyle(color: Color(0xFFB9C7BC), fontSize: 8),
            ),
          ],
        ),
        const Spacer(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    presentation.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    presentation.message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFD7D2CA),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x7A241812),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x28FFFFFF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          presentation.icon,
                          color: presentation.accent,
                          size: 19,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${current.temperatureC.round()}°C',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    _MetricLine(
                      icon: Icons.water_drop_outlined,
                      text: '${current.relativeHumidityPct}% humedad',
                    ),
                    const SizedBox(height: 5),
                    _MetricLine(
                      icon: Icons.air_rounded,
                      text: '${current.windSpeedKmh.toStringAsFixed(0)} km/h',
                    ),
                    const SizedBox(height: 5),
                    _MetricLine(
                      icon: Icons.grain_rounded,
                      text: '${current.precipitationMm.toStringAsFixed(1)} mm',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: const Color(0xFFB9C7BC)),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFE9E5DF), fontSize: 10),
          ),
        ),
      ],
    );
  }
}

class _WeatherUnavailable extends StatelessWidget {
  const _WeatherUnavailable({this.message, this.onRetry});

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.cloud_off_outlined, color: Colors.white, size: 30),
        const SizedBox(height: 8),
        const Text(
          'Clima no disponible',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          message ?? 'No pudimos actualizar las condiciones actuales.',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFFD7D2CA), fontSize: 11),
        ),
        if (onRetry != null)
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Reintentar'),
          ),
      ],
    );
  }
}

class _WeatherPresentation {
  const _WeatherPresentation({
    required this.title,
    required this.message,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color accent;

  factory _WeatherPresentation.fromForecast(WeatherForecast forecast) {
    final current = forecast.current;
    final rain = forecast.precipitationNext72Hours;
    final maximumTemperature = forecast.maximumTemperatureNext72Hours;

    if (current.weatherCode >= 95) {
      return const _WeatherPresentation(
        title: 'Tormenta en la zona',
        message: 'Pospón las labores al aire libre mientras dure la tormenta.',
        icon: Icons.thunderstorm_outlined,
        accent: Color(0xFFFFC857),
      );
    }
    if (maximumTemperature >= 37) {
      return _WeatherPresentation(
        title: 'Calor intenso',
        message:
            'Se esperan hasta ${maximumTemperature.round()}°C. Evita labores en las horas más cálidas.',
        icon: Icons.wb_sunny_outlined,
        accent: const Color(0xFFFFB423),
      );
    }
    if (current.precipitationMm > 0 || rain > 10) {
      return _WeatherPresentation(
        title: 'Lluvia prevista',
        message:
            'Se esperan ${rain.toStringAsFixed(1)} mm durante las próximas 72 horas.',
        icon: Icons.water_drop_outlined,
        accent: const Color(0xFF78B7FF),
      );
    }
    return _WeatherPresentation(
      title: 'Condiciones favorables para labores',
      message: rain == 0
          ? 'No se esperan lluvias durante las próximas 72 horas.'
          : 'Precipitación baja prevista: ${rain.toStringAsFixed(1)} mm en 72 horas.',
      icon: Icons.wb_sunny_outlined,
      accent: const Color(0xFFFFC928),
    );
  }
}
