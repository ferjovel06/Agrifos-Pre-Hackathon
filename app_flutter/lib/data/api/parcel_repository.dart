import '../../domain/entities/crop.dart';
import '../../domain/entities/parcel.dart';
import 'api_client.dart';

class ParcelRepository {
  final ApiClient _client;

  ParcelRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<Crop>> getCrops() async {
    final response = await _client.get('/crops');
    final list = (response as List).cast<Map<String, dynamic>>();
    return list.map(Crop.fromJson).toList();
  }

  Future<List<Parcel>> getParcels(String farmId) async {
    final response = await _client.get('/parcels', query: {'farm_id': farmId});
    final list = (response as List).cast<Map<String, dynamic>>();
    return list.map(Parcel.fromJson).toList();
  }

  Future<Parcel> createParcel({
    required String farmId,
    required String cropId,
    required String name,
    required double areaHectares,
    required DateTime plantingDate,
  }) async {
    final response = await _client.post('/parcels', {
      'farm_id': farmId,
      'crop_id': cropId,
      'name': name,
      'area_hectares': areaHectares,
      'planting_date': _dateOnly(plantingDate),
    });
    return Parcel.fromJson(response);
  }

  String _dateOnly(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
