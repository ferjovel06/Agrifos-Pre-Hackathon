/// A farm owned by the current user, as stored by the backend (`GET /farms`).
///
/// Mirrors `FarmRead` in `app/schemas/farm.py`.
class Farm {
  final String id;
  final String userId;
  final String name;
  final double areaHectares;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Farm({
    required this.id,
    required this.userId,
    required this.name,
    required this.areaHectares,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Farm.fromJson(Map<String, dynamic> json) {
    return Farm(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      areaHectares: (json['area_hectares'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }
}