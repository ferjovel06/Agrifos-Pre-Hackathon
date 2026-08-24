class Parcel {
  final String id;
  final String farmId;
  final String cropId;
  final String? varietyId;
  final String name;
  final double areaHectares;
  final int? plantsPerHectare;
  final DateTime plantingDate;

  const Parcel({
    required this.id,
    required this.farmId,
    required this.cropId,
    required this.varietyId,
    required this.name,
    required this.areaHectares,
    required this.plantsPerHectare,
    required this.plantingDate,
  });

  factory Parcel.fromJson(Map<String, dynamic> json) {
    return Parcel(
      id: json['id'] as String,
      farmId: json['farm_id'] as String,
      cropId: json['crop_id'] as String,
      varietyId: json['variety_id'] as String?,
      name: json['name'] as String,
      areaHectares: (json['area_hectares'] as num).toDouble(),
      plantsPerHectare: (json['plants_per_hectare'] as num?)?.toInt(),
      plantingDate: DateTime.parse(json['planting_date'] as String),
    );
  }
}
