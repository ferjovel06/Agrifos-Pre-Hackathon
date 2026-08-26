import 'package:flutter/material.dart';

import '../../../data/sensor/usb_sensor_service.dart';
import '../../../domain/entities/nutrient_level.dart';
import '../../../domain/entities/sensor_diagnostic.dart';
import '../../../domain/reference/soil_reference_ranges.dart';
import '../sensor_provider.dart';

class TelemetryCard extends StatelessWidget {
  const TelemetryCard({
    super.key,
    required this.status,
    required this.reading,
    required this.saveStatus,
    required this.onAction,
    this.diagnosis,
    this.errorMessage,
  });

  final SensorStatus status;
  final SensorReading? reading;
  final SaveStatus saveStatus;
  final SensorDiagnostic? diagnosis;
  final VoidCallback? onAction;
  final String? errorMessage;

  static const _background = Color(0xFF2A1712);
  static const _surface = Color(0xFF39231E);
  static const _green = Color(0xFF315E45);
  static const _mutedText = Color(0xFF9C8982);
  static const _track = Color(0xFF4A332D);

  bool get _isConnected => status == SensorStatus.connected;
  bool get _isBusy =>
      status == SensorStatus.connecting ||
      status == SensorStatus.reconnecting ||
      saveStatus == SaveStatus.saving;

  @override
  Widget build(BuildContext context) {
    final serverPh = diagnosis?.parameter('ph');
    final nitrogen = diagnosis?.parameter('nitrogen');
    final phosphorus = diagnosis?.parameter('phosphorus');
    final potassium = diagnosis?.parameter('potassium');
    final phLevel = reading == null
        ? null
        : classifySoilParameter(SoilParameterId.ph, reading!.ph);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildConnectionHeader()),
              const SizedBox(width: 12),
              _CaptureButton(
                label: _actionLabel,
                isLoading: _isBusy,
                onPressed: _canUseAction ? onAction : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _TelemetryMetric(
                  label: 'HUMEDAD\nVOL.',
                  value: reading == null
                      ? '—'
                      : '${reading!.humidity.toStringAsFixed(0)}%',
                  color: const Color(0xFF4D8DFF),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _TelemetryMetric(
                  label: 'TEMP.\nSUELO',
                  value: reading == null
                      ? '—'
                      : '${reading!.temperature.toStringAsFixed(0)}°C',
                  color: const Color(0xFFFFA000),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _TelemetryMetric(
                  label: 'PH ACTUAL',
                  value: reading?.ph.toStringAsFixed(1) ?? '—',
                  color: phLevel == null
                      ? _mutedText
                      : serverPh == null
                      ? _colorForSoilLevel(phLevel)
                      : _colorForDiagnosticLevel(serverPh.level),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('MACRONUTRIENTES (MG/KG)', style: _sectionLabelStyle),
                    Text('NIVEL ÓPTIMO', style: _sectionLabelStyle),
                  ],
                ),
                const SizedBox(height: 13),
                _NutrientBar(
                  label: 'N',
                  value: reading?.nitrogen,
                  optimalMax: 30,
                  level: reading == null
                      ? null
                      : NpkThresholds.nitrogen(reading!.nitrogen),
                  diagnosticLevel: nitrogen?.level,
                ),
                const SizedBox(height: 12),
                _NutrientBar(
                  label: 'P',
                  value: reading?.phosphorus,
                  optimalMax: 20,
                  level: reading == null
                      ? null
                      : NpkThresholds.phosphorus(reading!.phosphorus),
                  diagnosticLevel: phosphorus?.level,
                ),
                const SizedBox(height: 12),
                _NutrientBar(
                  label: 'K',
                  value: reading?.potassium,
                  optimalMax: 156,
                  level: reading == null
                      ? null
                      : NpkThresholds.potassium(reading!.potassium),
                  diagnosticLevel: potassium?.level,
                ),
              ],
            ),
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: _statusMessageColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _statusMessage!,
                style: TextStyle(
                  color: _statusMessageColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectionHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _connectionColor,
                shape: BoxShape.circle,
                boxShadow: _isConnected
                    ? const [
                        BoxShadow(
                          color: _green,
                          blurRadius: 7,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 9),
            const Expanded(
              child: Text(
                'Telemetría Sensor',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(left: 17, top: 2),
          child: Text(
            'ESP32',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Text(
            _connectionLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _mutedText,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }

  bool get _canUseAction {
    if (onAction == null || _isBusy) return false;
    if (_isConnected) return reading != null;
    return status == SensorStatus.disconnected || status == SensorStatus.error;
  }

  String get _actionLabel {
    if (saveStatus == SaveStatus.saving) return 'Guardando...';
    if (status == SensorStatus.connecting) return 'Conectando...';
    if (status == SensorStatus.reconnecting) return 'Reconectando...';
    if (!_isConnected) return 'Conectar sensor';
    if (reading == null) return 'Esperando lectura';
    return 'Capturar muestra';
  }

  String get _connectionLabel {
    switch (status) {
      case SensorStatus.connected:
        return reading == null
            ? 'CONECTADO · ESPERANDO DATOS'
            : 'CONEXIÓN SEGURA · USB';
      case SensorStatus.connecting:
        return 'BUSCANDO SENSOR USB';
      case SensorStatus.reconnecting:
        return 'RECONECTANDO SENSOR';
      case SensorStatus.error:
        return 'SIN CONEXIÓN';
      case SensorStatus.disconnected:
        return 'SENSOR DESCONECTADO';
    }
  }

  Color get _connectionColor {
    switch (status) {
      case SensorStatus.connected:
        return const Color(0xFF4FA66F);
      case SensorStatus.connecting:
      case SensorStatus.reconnecting:
        return const Color(0xFFFFA000);
      case SensorStatus.disconnected:
      case SensorStatus.error:
        return const Color(0xFFD64545);
    }
  }

  String? get _statusMessage {
    if (saveStatus == SaveStatus.saved && diagnosis != null) {
      final warnings = diagnosis!.actionableWarnings;
      return warnings.isEmpty ? diagnosis!.displayLabel : warnings.join(' · ');
    }
    if (saveStatus == SaveStatus.saved) return 'Muestra guardada correctamente';
    if (errorMessage != null && errorMessage!.trim().isNotEmpty) {
      return errorMessage;
    }
    if (!_isConnected && status == SensorStatus.disconnected) {
      return 'Conecta el sensor por USB para comenzar la telemetría.';
    }
    return null;
  }

  Color get _statusMessageColor {
    if (saveStatus == SaveStatus.saved) return const Color(0xFF72B88B);
    if (status == SensorStatus.disconnected) return const Color(0xFFFFC46B);
    return const Color(0xFFFF8B7D);
  }

  Color _colorForSoilLevel(SoilLevel level) {
    switch (level) {
      case SoilLevel.deficient:
        return const Color(0xFFD64545);
      case SoilLevel.optimal:
        return const Color(0xFF3B8A61);
      case SoilLevel.high:
        return const Color(0xFFE08A2C);
      case SoilLevel.critical:
        return const Color(0xFFEF5350);
    }
  }

  Color _colorForDiagnosticLevel(SoilDiagnosticLevel level) {
    switch (level) {
      case SoilDiagnosticLevel.deficient:
        return const Color(0xFFD64545);
      case SoilDiagnosticLevel.optimal:
        return const Color(0xFF3B8A61);
      case SoilDiagnosticLevel.high:
        return const Color(0xFFE08A2C);
      case SoilDiagnosticLevel.critical:
        return const Color(0xFFEF5350);
    }
  }

  static const _sectionLabelStyle = TextStyle(
    color: _mutedText,
    fontSize: 9,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
  );
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      height: 56,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: TelemetryCard._green,
          disabledBackgroundColor: TelemetryCard._green.withValues(alpha: 0.4),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: isLoading
            ? const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.camera_alt_outlined, size: 17),
        label: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _TelemetryMetric extends StatelessWidget {
  const _TelemetryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 103,
      padding: const EdgeInsets.fromLTRB(13, 13, 8, 10),
      decoration: BoxDecoration(
        color: TelemetryCard._surface,
        borderRadius: BorderRadius.circular(14),
        border: Border(bottom: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: TelemetryCard._mutedText,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              height: 1.3,
            ),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NutrientBar extends StatelessWidget {
  const _NutrientBar({
    required this.label,
    required this.value,
    required this.optimalMax,
    required this.level,
    this.diagnosticLevel,
  });

  final String label;
  final double? value;
  final double optimalMax;
  final NutrientLevel? level;
  final SoilDiagnosticLevel? diagnosticLevel;

  @override
  Widget build(BuildContext context) {
    final color = diagnosticLevel != null
        ? _diagnosticColor(diagnosticLevel!)
        : level == null
        ? TelemetryCard._mutedText
        : NpkThresholds.colorFor(level!);
    final progress = value == null
        ? 0.0
        : (value! / (optimalMax * 2)).clamp(0.0, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFD8CBC6),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: TelemetryCard._track,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 40,
          child: Text(
            value?.toStringAsFixed(0) ?? '—',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Color _diagnosticColor(SoilDiagnosticLevel level) {
    switch (level) {
      case SoilDiagnosticLevel.deficient:
        return const Color(0xFFD64545);
      case SoilDiagnosticLevel.optimal:
        return const Color(0xFF3B8A61);
      case SoilDiagnosticLevel.high:
        return const Color(0xFFE08A2C);
      case SoilDiagnosticLevel.critical:
        return const Color(0xFFEF5350);
    }
  }
}
