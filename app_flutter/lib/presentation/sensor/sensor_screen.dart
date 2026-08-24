import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/api/parcel_repository.dart';
import '../../domain/entities/parcel.dart';
import '../farm/farm_provider.dart';
import '../home/latest_reading_provider.dart';
import 'sensor_provider.dart';
import 'widgets/input_data_card.dart';

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
          _isLoadingParcel = false;
          _parcelError =
              'Registra una parcela antes de realizar un diagnóstico.';
        });
        return;
      }

      final parcel = parcels.first;
      final varietiesFuture = _parcelRepository.getVarieties(parcel.cropId);
      final stagesFuture = _parcelRepository.getStageInstances(parcel.id);
      final varieties = await varietiesFuture;
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
      }

      setState(() {
        _parcel = parcel;
        _cropName = cropName;
        _varietyName = varietyName;
        _stageName = stageName;
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
    final canSave =
        sensor.lastReading != null &&
        parcel != null &&
        sensor.saveStatus != SaveStatus.saving;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputDataSection(),
          const SizedBox(height: 18),
          Row(
            children: [
              Text('Estado: ${sensor.status.name}'),
              if (sensor.status == SensorStatus.reconnecting) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          if (sensor.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                sensor.errorMessage!,
                style: TextStyle(
                  color: sensor.status == SensorStatus.reconnecting
                      ? Colors.orange
                      : Colors.red,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: parcel == null
                    ? null
                    : () => context.read<SensorProvider>().connectAndListen(),
                child: const Text('Conectar sensor'),
              ),
              if (sensor.status == SensorStatus.connected ||
                  sensor.status == SensorStatus.reconnecting)
                OutlinedButton(
                  onPressed: () => context.read<SensorProvider>().disconnect(),
                  child: const Text('Desconectar'),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (sensor.lastReading != null) ...[
            Text('Nitrógeno: ${sensor.lastReading!.nitrogen}'),
            Text('Fósforo: ${sensor.lastReading!.phosphorus}'),
            Text('Potasio: ${sensor.lastReading!.potassium}'),
            Text('EC: ${sensor.lastReading!.ec}'),
            Text('pH: ${sensor.lastReading!.ph}'),
            Text('Temperatura: ${sensor.lastReading!.temperature} °C'),
            Text('Humedad: ${sensor.lastReading!.humidity} %'),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: canSave
                      ? () async {
                          final sensorProvider = context.read<SensorProvider>();
                          await sensorProvider.saveCurrentReading(parcel.id);
                          if (sensorProvider.saveStatus == SaveStatus.saved &&
                              context.mounted) {
                            context.read<LatestReadingProvider>().fetchLatest(
                              parcel.id,
                            );
                          }
                        }
                      : null,
                  child: sensor.saveStatus == SaveStatus.saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar lectura'),
                ),
                const SizedBox(width: 12),
                if (sensor.saveStatus == SaveStatus.saved)
                  const Text(
                    'Lectura guardada ✓',
                    style: TextStyle(color: Colors.green),
                  ),
              ],
            ),
            if (sensor.saveStatus == SaveStatus.error &&
                sensor.saveErrorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  sensor.saveErrorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ] else
            const Text('Sin lecturas todavía'),
        ],
      ),
    );
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
      return InputDataCard(
        parcelName: parcel.name,
        cropName: _cropName!,
        varietyName: _varietyName!,
        stageName: _stageName!,
        ageMonths: _ageInMonths(parcel.plantingDate),
        plantsPerHectare: parcel.plantsPerHectare,
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
