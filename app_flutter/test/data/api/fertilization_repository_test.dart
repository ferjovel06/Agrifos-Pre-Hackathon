import 'package:app_flutter/data/api/api_client.dart';
import 'package:app_flutter/data/api/fertilization_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loading the latest plan performs a read-only request', () async {
    final client = _RecordingApiClient();
    final repository = FertilizationRepository(client: client);

    final result = await repository.getLatestPlan('parcel-1');

    expect(result, isNull);
    expect(client.getCalls, 1);
    expect(client.postCalls, 0);
    expect(client.lastPath, '/fertilization/plans/latest');
    expect(client.lastQuery, {'parcel_id': 'parcel-1'});
  });
}

class _RecordingApiClient extends ApiClient {
  int getCalls = 0;
  int postCalls = 0;
  String? lastPath;
  Map<String, String>? lastQuery;

  @override
  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    getCalls++;
    lastPath = path;
    lastQuery = query;
    return null;
  }

  @override
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    postCalls++;
    return <String, dynamic>{};
  }
}
