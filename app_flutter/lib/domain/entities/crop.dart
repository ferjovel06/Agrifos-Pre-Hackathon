class Crop {
  final String id;
  final String name;

  const Crop({required this.id, required this.name});

  factory Crop.fromJson(Map<String, dynamic> json) {
    return Crop(id: json['id'] as String, name: json['name'] as String);
  }
}
