import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/api/parcel_repository.dart';
import '../../domain/entities/parcel.dart';
import '../../domain/entities/phenological_stage.dart';
import '../farm/farm_provider.dart';
import '../home/latest_reading_provider.dart';
import 'sensor_provider.dart';
import 'widgets/input_data_card.dart';
import 'widgets/phenological_stage_card.dart';
import 'widgets/telemetry_card.dart';

class SensorScreen extends StatefulWidget {
  const SensorScreen({super.key});

  @override
  State<SensorScreen> createState() => _SensorScreenState();
}

class _SensorScreenState extends State<SensorScreen> {
  final _parcelRepository = ParcelRepository();

  Parcel? _parcel;
  String? _cropName;
  String? _varietyName;
  String? _stageName;
  List<PhenologicalStageTemplate> _stageTemplates = const [];
  int? _currentStageOrder;
  String? _loadedFarmId;
  int? _loadedParcelRevision;
  String? _parcelError;
  bool _isLoadingParcel = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final farmProvider = context.watch<FarmProvider>();
    final farmId = farmProvider.currentFarm?.id;
    final parcelRevision = farmProvider.parcelRevision;
    if (farmId != null &&
        (farmId != _loadedFarmId || parcelRevision != _loadedParcelRevision)) {
      _loadedFarmId = farmId;
      _loadedParcelRevision = parcelRevision;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadParcelData(farmId);
      });
    }
  }

  Future<void> _loadParcelData(String farmId) async {
    setState(() {
      _isLoadingParcel = true;
      _parcelError = null;
    });

    try {
      final parcelsFuture = _parcelRepository.getParcels(farmId);
      final cropsFuture = _parcelRepository.getCrops();
      final parcels = await parcelsFuture;
      final crops = await cropsFuture;
      if (!mounted || farmId != _loadedFarmId) return;

      if (parcels.isEmpty) {
        setState(() {
          _parcel = null;
          _cropName = null;
          _varietyName = null;
          _stageName = null;
          _stageTemplates = const [];
          _currentStageOrder = null;
          _isLoadingParcel = false;
          _parcelError =
              'Registra una parcela antes de realizar un diagnóstico.';
        });
        return;
      }

      final parcel = parcels.first;
      final varietiesFuture = _parcelRepository.getVarieties(parcel.cropId);
      final templatesFuture = _parcelRepository.getStageTemplates(
        parcel.cropId,
      );
      final stagesFuture = _parcelRepository.getStageInstances(parcel.id);
      final varieties = await varietiesFuture;
      final templates = await templatesFuture;
      final stages = await stagesFuture;
      if (!mounted || farmId != _loadedFarmId) return;
      String cropName = 'Sin especificar';
      for (final crop in crops) {
        if (crop.id == parcel.cropId) {
          cropName = crop.name;
          break;
        }
      }
      String varietyName = 'Sin especificar';
      for (final variety in varieties) {
        if (variety.id == parcel.varietyId) {
          varietyName = variety.name;
          break;
        }
      }
      String stageName = 'Sin especificar';
      int? currentStageOrder;
      if (stages.isNotEmpty) {
        var currentStage = stages.first;
        for (final stage in stages.skip(1)) {
          final currentDate = currentStage.actualDate;
          final candidateDate = stage.actualDate;
          if (candidateDate != null &&
              (currentDate == null || candidateDate.isAfter(currentDate))) {
            currentStage = stage;
          }
        }
        stageName = currentStage.name;
        currentStageOrder = currentStage.stageOrder;
      }

      setState(() {
        _parcel = parcel;
        _cropName = cropName;
        _varietyName = varietyName;
        _stageName = stageName;
        _stageTemplates = templates;
        _currentStageOrder = currentStageOrder;
        _isLoadingParcel = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingParcel = false;
        _parcelError = 'No se pudieron cargar los datos de la parcela.';
      });
    }
  }

  int _ageInMonths(DateTime plantingDate) {
    final now = DateTime.now();
    var months =
        (now.year - plantingDate.year) * 12 + now.month - plantingDate.month;
    if (now.day < plantingDate.day) months--;
    return months < 0 ? 0 : months;
  }

  @override
  Widget build(BuildContext context) {
    final sensor = context.watch<SensorProvider>();
    final parcel = _parcel;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputDataSection(),
          const SizedBox(height: 16),
          TelemetryCard(
            status: sensor.status,
            reading: sensor.lastReading,
            saveStatus: sensor.saveStatus,
            errorMessage: sensor.saveErrorMessage ?? sensor.errorMessage,
            onAction: parcel == null
                ? null
                : () => _handleTelemetryAction(sensor, parcel),
          ),
        ],
      ),
    );
  }

  Future<void> _handleTelemetryAction(
    SensorProvider sensor,
    Parcel parcel,
  ) async {
    if (sensor.status != SensorStatus.connected) {
      await sensor.connectAndListen();
      return;
    }

    if (sensor.lastReading == null) return;
    await sensor.saveCurrentReading(parcel.id);
    if (sensor.saveStatus == SaveStatus.saved && mounted) {
      context.read<LatestReadingProvider>().fetchLatest(parcel.id);
    }
  }

  Widget _buildInputDataSection() {
    final parcel = _parcel;
    if (_isLoadingParcel) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (parcel != null &&
        _cropName != null &&
        _varietyName != null &&
        _stageName != null) {
      return Column(
        children: [
          InputDataCard(
            parcelName: parcel.name,
            cropName: _cropName!,
            varietyName: _varietyName!,
            stageName: _stageName!,
            ageMonths: _ageInMonths(parcel.plantingDate),
            plantsPerHectare: parcel.plantsPerHectare,
          ),
          if (_stageTemplates.isNotEmpty) ...[
            const SizedBox(height: 16),
            PhenologicalStageCard(
              stages: _stageTemplates,
              currentStageOrder: _currentStageOrder,
            ),
          ],
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _parcelError ?? 'Esperando los datos de la parcela...',
              style: const TextStyle(height: 1.35),
            ),
          ),
          if (_loadedFarmId != null)
            IconButton(
              tooltip: 'Reintentar',
              onPressed: () => _loadParcelData(_loadedFarmId!),
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
    );
  }
}
