import 'package:app_flutter/data/api/farm_repository.dart';
import 'package:app_flutter/domain/entities/farm.dart';
import 'package:app_flutter/presentation/farm/farm_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selects the first farm initially and allows changing it', () async {
    final first = _farm('farm-1', 'Finca Norte');
    final second = _farm('farm-2', 'Finca Sur');
    final provider = FarmProvider(
      farmRepository: _FakeFarmRepository([first, second]),
    );

    await provider.loadFarms(userId: 'user-1');

    expect(provider.currentFarm, same(first));
    provider.selectFarm(second.id);
    expect(provider.currentFarm, same(second));
  });

  test('preserves the selected farm after refreshing the list', () async {
    final first = _farm('farm-1', 'Finca Norte');
    final second = _farm('farm-2', 'Finca Sur');
    final repository = _FakeFarmRepository([first, second]);
    final provider = FarmProvider(farmRepository: repository);

    await provider.loadFarms(userId: 'user-1');
    provider.selectFarm(second.id);
    await provider.loadFarms(force: true, userId: 'user-1');

    expect(provider.selectedFarmId, second.id);
  });

  test('ignores an unknown farm selection', () async {
    final first = _farm('farm-1', 'Finca Norte');
    final provider = FarmProvider(farmRepository: _FakeFarmRepository([first]));

    await provider.loadFarms(userId: 'user-1');
    provider.selectFarm('unknown');

    expect(provider.currentFarm, same(first));
  });
}

class _FakeFarmRepository extends FarmRepository {
  _FakeFarmRepository(this.result);

  final List<Farm> result;

  @override
  Future<List<Farm>> getFarms() async => result;
}

Farm _farm(String id, String name) {
  return Farm(
    id: id,
    userId: 'user-1',
    name: name,
    areaHectares: 10,
    latitude: 12,
    longitude: -86,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}
