import 'package:app_flutter/data/api/parcel_repository.dart';
import 'package:app_flutter/domain/entities/parcel.dart';
import 'package:app_flutter/presentation/farm/parcel_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selects the first parcel and allows changing it', () async {
    final provider = ParcelProvider(
      parcelRepository: _FakeParcelRepository({
        'farm-1': [
          _parcel('parcel-1', 'Lote Norte'),
          _parcel('parcel-2', 'Lote Sur'),
        ],
      }),
    );

    await provider.loadForFarm('farm-1');
    expect(provider.selectedParcelId, 'parcel-1');

    provider.selectParcel('parcel-2');
    expect(provider.currentParcel?.name, 'Lote Sur');
  });

  test('restores each farm last selected parcel', () async {
    final provider = ParcelProvider(
      parcelRepository: _FakeParcelRepository({
        'farm-1': [
          _parcel('parcel-1', 'Lote Norte'),
          _parcel('parcel-2', 'Lote Sur'),
        ],
        'farm-2': [_parcel('parcel-3', 'Lote Central', farmId: 'farm-2')],
      }),
    );

    await provider.loadForFarm('farm-1');
    provider.selectParcel('parcel-2');
    await provider.loadForFarm('farm-2');
    await provider.loadForFarm('farm-1');

    expect(provider.selectedParcelId, 'parcel-2');
  });

  test('exposes an empty state for a farm without parcels', () async {
    final provider = ParcelProvider(
      parcelRepository: _FakeParcelRepository({'farm-1': const []}),
    );

    await provider.loadForFarm('farm-1');

    expect(provider.status, ParcelStatus.noParcel);
    expect(provider.currentParcel, isNull);
  });

  test('increments the data revision when a parcel is replaced', () async {
    final provider = ParcelProvider(
      parcelRepository: _FakeParcelRepository({
        'farm-1': [_parcel('parcel-1', 'Lote Norte')],
      }),
    );
    await provider.loadForFarm('farm-1');
    final revision = provider.dataRevision;

    provider.replaceParcel(_parcel('parcel-1', 'Lote actualizado'));

    expect(provider.dataRevision, revision + 1);
    expect(provider.currentParcel?.name, 'Lote actualizado');
  });
}

class _FakeParcelRepository extends ParcelRepository {
  _FakeParcelRepository(this.byFarm);

  final Map<String, List<Parcel>> byFarm;

  @override
  Future<List<Parcel>> getParcels(String farmId) async => byFarm[farmId] ?? [];
}

Parcel _parcel(String id, String name, {String farmId = 'farm-1'}) {
  return Parcel(
    id: id,
    farmId: farmId,
    cropId: 'crop-1',
    varietyId: 'variety-1',
    name: name,
    areaHectares: 1,
    plantsPerHectare: 4000,
    plantingDate: DateTime(2026),
  );
}
