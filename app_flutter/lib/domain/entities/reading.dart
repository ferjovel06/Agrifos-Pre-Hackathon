/// A soil/sensor reading as stored by the backend (`GET /readings`).
///
/// Mirrors `ReadingRead` in `app/schemas/reading.py`. Units match what the
/// backend stores: nitrogen/phosphorus/potassium in mg/kg, ec in dS/m,
/// temperature in °C, humidity in %.
class Reading {
  final String id;
  final String parcelId;
  final double nitrogen;
  final double phosphorus;
  final double potassium;
  final double ec;
  final double ph;
  final double temperature;
  final double humidity;
  final DateTime recordedAt;

  const Reading({
    required this.id,
    required this.parcelId,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.ec,
    required this.ph,
    required this.temperature,
    required this.humidity,
    required this.recordedAt,
  });

  factory Reading.fromJson(Map<String, dynamic> json) {
    return Reading(
      id: json['id'] as String,
      parcelId: json['parcel_id'] as String,
      nitrogen: (json['nitrogen'] as num).toDouble(),
      phosphorus: (json['phosphorus'] as num).toDouble(),
      potassium: (json['potassium'] as num).toDouble(),
      ec: (json['ec'] as num).toDouble(),
      ph: (json['ph'] as num).toDouble(),
      temperature: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      recordedAt: DateTime.parse(json['recorded_at'] as String).toLocal(),
    );
  }
}