import 'package:flutter/material.dart';

import '../../../domain/entities/nutrient_level.dart';
import '../../../domain/entities/reading.dart';
import '../../../shared/relative_time.dart';

/// "Última Lectura Global" card shown on the home dashboard: the most
/// recent stored reading (humidity, N/P/K, pH) plus live sensor connection
/// status.
class LastReadingCard extends StatelessWidget {
  const LastReadingCard({
    super.key,
    required this.reading,
    required this.isLoading,
    required this.isSensorConnected,
    this.errorMessage,
    this.onRetry,
  });

  final Reading? reading;
  final bool isLoading;
  final bool isSensorConnected;
  final String? errorMessage;
  final VoidCallback? onRetry;

  static const _titleColor = Color(0xFF472319);
  static const _labelColor = Color(0xFF8A8A8A);
  static const _borderColor = Color(0xFFEDE7E0);
  static const _neutralValueColor = Color(0xFF222222);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(reading: reading),
          const SizedBox(height: 18),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (errorMessage != null)
            _ErrorState(message: errorMessage!, onRetry: onRetry)
          else if (reading == null)
              const Text(
                'Todavía no hay lecturas registradas para esta parcela.',
                style: TextStyle(color: _labelColor),
              )
            else ...[
                _MetricsGrid(reading: reading!),
              ],
          const SizedBox(height: 16),
          _ConnectionFooter(isConnected: isSensorConnected),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.reading});

  final Reading? reading;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Text(
              '#',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: LastReadingCard._titleColor,
              ),
            ),
            SizedBox(width: 6),
            Text(
              'Última Lectura Global',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: LastReadingCard._titleColor,
              ),
            ),
          ],
        ),
        if (reading != null)
          Row(
            children: [
              Icon(Icons.access_time_rounded,
                  size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                formatRelativeTime(reading!.recordedAt),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
      ],
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.reading});

  final Reading reading;

  @override
  Widget build(BuildContext context) {
    final nitrogenLevel = NpkThresholds.nitrogen(reading.nitrogen);
    final phosphorusLevel = NpkThresholds.phosphorus(reading.phosphorus);
    final potassiumLevel = NpkThresholds.potassium(reading.potassium);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Humedad',
                value: '${reading.humidity.toStringAsFixed(0)}%',
                valueColor: const Color(0xFF2563EB),
              ),
            ),
            Expanded(
              child: _MetricTile(
                label: 'Nitrógeno',
                value: '${reading.nitrogen.toStringAsFixed(0)} mg/kg',
                valueColor: NpkThresholds.colorFor(nitrogenLevel),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Fósforo',
                value: '${reading.phosphorus.toStringAsFixed(0)} mg/kg',
                valueColor: NpkThresholds.colorFor(phosphorusLevel),
              ),
            ),
            Expanded(
              child: _MetricTile(
                label: 'Potasio',
                value: '${reading.potassium.toStringAsFixed(0)} mg/kg',
                valueColor: NpkThresholds.colorFor(potassiumLevel),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'pH',
                value: reading.ph.toStringAsFixed(1),
                valueColor: LastReadingCard._neutralValueColor,
              ),
            ),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: LastReadingCard._labelColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _ConnectionFooter extends StatelessWidget {
  const _ConnectionFooter({required this.isConnected});

  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? Colors.green : Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isConnected ? 'Sensor NPK conectado' : 'Sensor NPK desconectado',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: const TextStyle(color: Colors.red)),
        if (onRetry != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ),
      ],
    );
  }
}