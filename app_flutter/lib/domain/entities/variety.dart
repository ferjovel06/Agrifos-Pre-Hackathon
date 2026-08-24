class Variety {
  final String id;
  final String cropId;
  final String name;

  const Variety({required this.id, required this.cropId, required this.name});

  factory Variety.fromJson(Map<String, dynamic> json) {
    return Variety(
      id: json['id'] as String,
      cropId: json['crop_id'] as String,
      name: json['name'] as String,
    );
  }
}
