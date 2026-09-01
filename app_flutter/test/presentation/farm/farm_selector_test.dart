import 'package:app_flutter/data/api/farm_repository.dart';
import 'package:app_flutter/domain/entities/farm.dart';
import 'package:app_flutter/presentation/farm/farm_provider.dart';
import 'package:app_flutter/presentation/farm/farm_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shows the active farm and add action with one farm', (
    tester,
  ) async {
    final provider = FarmProvider(
      farmRepository: _FakeFarmRepository([_farm('farm-1', 'Finca Norte')]),
    );
    await provider.loadFarms(userId: 'user-1');

    await tester.pumpWidget(_app(provider));

    expect(find.text('Finca activa'), findsOneWidget);
    expect(find.text('Finca Norte'), findsOneWidget);
    expect(find.byKey(const ValueKey('add-farm-button')), findsOneWidget);
  });

  testWidgets('changes the active farm from the selector', (tester) async {
    final provider = FarmProvider(
      farmRepository: _FakeFarmRepository([
        _farm('farm-1', 'Finca Norte'),
        _farm('farm-2', 'Finca Sur'),
      ]),
    );
    await provider.loadFarms(userId: 'user-1');

    await tester.pumpWidget(_app(provider));
    await tester.tap(find.text('Finca Norte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finca Sur').last);
    await tester.pumpAndSettle();

    expect(provider.selectedFarmId, 'farm-2');
    expect(find.text('Finca Sur'), findsOneWidget);
  });
}

Widget _app(FarmProvider provider) {
  return ChangeNotifierProvider.value(
    value: provider,
    child: const MaterialApp(home: Scaffold(body: FarmSelector())),
  );
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
