class ClimateAlert {
  const ClimateAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    this.date,
    this.riskScore,
  });

  final String id;
  final String title;
  final String message;
  final String severity;
  final DateTime? date;
  final double? riskScore;

  factory ClimateAlert.fromJson(Map<String, dynamic> json) => ClimateAlert(
    id: json['id'] as String,
    title: json['title'] as String,
    message: json['message'] as String,
    severity: json['severity'] as String,
    date: DateTime.tryParse(json['event_date'] as String? ?? ''),
    riskScore: (json['risk_score'] as num?)?.toDouble(),
  );
}
