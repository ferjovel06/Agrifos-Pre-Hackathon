enum SoilDiagnosticLevel { deficient, optimal, high, critical }

class DiagnosticParameter {
  const DiagnosticParameter({
    required this.parameter,
    required this.label,
    required this.value,
    required this.unit,
    required this.level,
    required this.message,
  });

  final String parameter;
  final String label;
  final double value;
  final String unit;
  final SoilDiagnosticLevel level;
  final String message;

  factory DiagnosticParameter.fromJson(Map<String, dynamic> json) {
    return DiagnosticParameter(
      parameter: json['parameter'] as String,
      label: json['label'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      level: SoilDiagnosticLevel.values.byName(json['level'] as String),
      message: json['message'] as String,
    );
  }
}

class SensorDiagnostic {
  const SensorDiagnostic({
    required this.readingId,
    required this.crop,
    required this.engineVersion,
    required this.overallConfidence,
    required this.parameters,
    required this.warnings,
  });

  final String readingId;
  final String crop;
  final String engineVersion;
  final String overallConfidence;
  final List<DiagnosticParameter> parameters;
  final List<String> warnings;

  DiagnosticParameter? parameter(String name) {
    for (final result in parameters) {
      if (result.parameter == name) return result;
    }
    return null;
  }

  String get confidenceLabel {
    switch (overallConfidence) {
      case 'low':
        return 'confianza baja';
      case 'medium':
        return 'confianza media';
      case 'high':
        return 'confianza alta';
      default:
        return overallConfidence;
    }
  }

  String get displayLabel {
    if (overallConfidence == 'low') return 'Diagnóstico preliminar';
    return 'Diagnóstico del servidor · $confidenceLabel';
  }

  List<String> get actionableWarnings {
    return warnings
        .where(
          (warning) =>
              warning.contains('bajo') ||
              warning.contains('elevada') ||
              warning.startsWith('pH '),
        )
        .toList(growable: false);
  }

  factory SensorDiagnostic.fromJson(Map<String, dynamic> json) {
    return SensorDiagnostic(
      readingId: json['reading_id'] as String,
      crop: json['crop'] as String,
      engineVersion: json['engine_version'] as String,
      overallConfidence: json['overall_confidence'] as String,
      parameters: (json['parameters'] as List<dynamic>)
          .map(
            (item) =>
                DiagnosticParameter.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      warnings: (json['warnings'] as List<dynamic>).cast<String>(),
    );
  }
}
