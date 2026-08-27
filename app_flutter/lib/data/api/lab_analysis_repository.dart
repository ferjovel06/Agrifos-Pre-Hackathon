import '../../domain/entities/lab_analysis.dart';
import 'api_client.dart';

class LabAnalysisRepository {
  LabAnalysisRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<LabAnalysis>> listForParcel(String parcelId) async {
    final response =
        await _client.get('/lab-analyses', query: {'parcel_id': parcelId})
            as List<dynamic>;
    return response
        .map((item) => LabAnalysis.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<LabAnalysis> create(String parcelId, LabAnalysisInput input) async {
    final response = await _client.post('/lab-analyses', {
      'parcel_id': parcelId,
      ...input.toJson(),
    });
    return LabAnalysis.fromJson(response);
  }

  Future<LabAnalysis> update(String id, LabAnalysisInput input) async {
    final response = await _client.patch('/lab-analyses/$id', input.toJson());
    return LabAnalysis.fromJson(response);
  }

  Future<void> delete(String id) => _client.delete('/lab-analyses/$id');
}
