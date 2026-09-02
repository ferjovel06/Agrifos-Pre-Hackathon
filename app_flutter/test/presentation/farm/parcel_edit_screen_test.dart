import 'package:app_flutter/data/api/parcel_repository.dart';
import 'package:app_flutter/domain/entities/crop.dart';
import 'package:app_flutter/domain/entities/farm.dart';
import 'package:app_flutter/domain/entities/parcel.dart';
import 'package:app_flutter/domain/entities/phenological_stage.dart';
import 'package:app_flutter/domain/entities/variety.dart';
import 'package:app_flutter/presentation/farm/entity_edit_screens.dart';
import 'package:app_flutter/presentation/farm/farm_provider.dart';
import 'package:app_flutter/presentation/farm/parcel_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('reloads compatible varieties and stages after changing crop', (
    tester,
  ) async {
    final repository = _FakeParcelRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: ParcelEditScreen(
          parcel: parcel,
          farm: farm,
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Caturra'), findsOneWidget);
    expect(find.text('Levante'), findsOneWidget);

    await tester.tap(find.text('Café').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Maíz').last);
    await tester.pumpAndSettle();

    expect(repository.lastVarietyCropId, 'crop-2');
    expect(repository.lastStageCropId, 'crop-2');

    final selectors = find.byType(DropdownButtonFormField<String>);
    await tester.tap(selectors.at(1));
    await tester.pumpAndSettle();
    expect(find.text('Híbrido'), findsOneWidget);
    await tester.tap(find.text('Híbrido'));
    await tester.pumpAndSettle();

    await tester.tap(selectors.at(2));
    await tester.pumpAndSettle();
    expect(find.text('Crecimiento vegetativo'), findsOneWidget);
  });

  testWidgets('saves parcel fields and current stage in one request', (
    tester,
  ) async {
    final repository = _FakeParcelRepository();
    final parcelProvider = ParcelProvider(parcelRepository: repository);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: parcelProvider),
          ChangeNotifierProvider(create: (_) => FarmProvider()),
        ],
        child: MaterialApp(
          home: ParcelEditScreen(
            parcel: parcel,
            farm: farm,
            repository: repository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final saveButton = find.text('Guardar cambios');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(repository.configurationUpdates, 1);
    expect(repository.savedCropId, 'crop-1');
    expect(repository.savedVarietyId, 'variety-1');
    expect(repository.savedStageId, 'stage-1');
  });
}

class _FakeParcelRepository extends ParcelRepository {
  String? lastVarietyCropId;
  String? lastStageCropId;
  int configurationUpdates = 0;
  String? savedCropId;
  String? savedVarietyId;
  String? savedStageId;

  @override
  Future<List<Crop>> getCrops() async => const [
    Crop(id: 'crop-1', name: 'Café'),
    Crop(id: 'crop-2', name: 'Maíz'),
  ];

  @override
  Future<List<Variety>> getVarieties(String cropId) async {
    lastVarietyCropId = cropId;
    return cropId == 'crop-1'
        ? const [Variety(id: 'variety-1', cropId: 'crop-1', name: 'Caturra')]
        : const [Variety(id: 'variety-2', cropId: 'crop-2', name: 'Híbrido')];
  }

  @override
  Future<List<PhenologicalStageTemplate>> getStageTemplates(
    String cropId,
  ) async {
    lastStageCropId = cropId;
    return cropId == 'crop-1'
        ? const [
            PhenologicalStageTemplate(
              id: 'stage-1',
              cropId: 'crop-1',
              name: 'Levante',
              stageOrder: 2,
              durationDays: 365,
            ),
          ]
        : const [
            PhenologicalStageTemplate(
              id: 'stage-2',
              cropId: 'crop-2',
              name: 'Crecimiento vegetativo',
              stageOrder: 1,
              durationDays: 45,
            ),
          ];
  }

  @override
  Future<List<PhenologicalStageInstance>> getStageInstances(
    String parcelId,
  ) async => [
    PhenologicalStageInstance(
      id: 'instance-1',
      parcelId: parcelId,
      templateId: 'stage-1',
      name: 'Levante',
      stageOrder: 2,
      durationDays: 365,
      estimatedDate: null,
      actualDate: DateTime(2026, 1, 1),
      selectedAt: DateTime(2026, 1, 1),
    ),
  ];

  @override
  Future<Parcel> updateParcelConfiguration({
    required String id,
    required String cropId,
    required String varietyId,
    required String stageTemplateId,
    required String name,
    required double areaHectares,
    required int plantsPerHectare,
    required DateTime plantingDate,
  }) async {
    configurationUpdates++;
    savedCropId = cropId;
    savedVarietyId = varietyId;
    savedStageId = stageTemplateId;
    return Parcel(
      id: id,
      farmId: parcel.farmId,
      cropId: cropId,
      varietyId: varietyId,
      name: name,
      areaHectares: areaHectares,
      plantsPerHectare: plantsPerHectare,
      plantingDate: plantingDate,
    );
  }
}

final parcel = Parcel(
  id: 'parcel-1',
  farmId: 'farm-1',
  cropId: 'crop-1',
  varietyId: 'variety-1',
  name: 'Lote norte',
  areaHectares: 1,
  plantsPerHectare: 4000,
  plantingDate: DateTime(2025, 1, 1),
);

final farm = Farm(
  id: 'farm-1',
  userId: 'user-1',
  name: 'Finca principal',
  areaHectares: 10,
  latitude: 12.1,
  longitude: -86.2,
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);
