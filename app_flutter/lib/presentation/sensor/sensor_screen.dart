import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/api/api_client.dart';
import '../../data/api/fertilization_repository.dart';
import '../../data/api/lab_analysis_repository.dart';
import '../../data/api/parcel_repository.dart';
import '../../data/sensor/usb_sensor_service.dart';
import '../../domain/entities/fertilization_recommendation.dart';
import '../../domain/entities/lab_analysis.dart';
import '../../domain/entities/parcel.dart';
import '../../domain/entities/phenological_stage.dart';
import '../../domain/entities/sensor_diagnostic.dart';
import '../farm/farm_provider.dart';
import '../home/latest_reading_provider.dart';
import '../lab_analysis/lab_analysis_screen.dart';
import 'sensor_provider.dart';
import 'widgets/conventional_fertilization_card.dart';
import 'widgets/input_data_card.dart';
import 'widgets/lab_analysis_card.dart';
import 'widgets/phenological_stage_card.dart';
import 'widgets/telemetry_card.dart';

class SensorScreen extends StatefulWidget {
  const SensorScreen({super.key});

  @override
  State<SensorScreen> createState() => _SensorScreenState();
}

class _SensorScreenState extends State<SensorScreen> {
  final _parcelRepository = ParcelRepository();
  final _fertilizationRepository = FertilizationRepository();
  final _labAnalysisRepository = LabAnalysisRepository();

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
  bool _isLoadingFertilization = false;
  FertilizationRecommendation? _fertilizationRecommendation;
  String? _fertilizationError;
  List<LabAnalysis> _labAnalyses = const [];
  bool _isLoadingLabAnalyses = false;
  String? _labAnalysesError;

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
          _labAnalyses = const [];
          _labAnalysesError = null;
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
      await _loadLabAnalyses(parcel.id);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingParcel = false;
        _parcelError = 'No se pudieron cargar los datos de la parcela.';
      });
    }
  }

  Future<void> _loadLabAnalyses(String parcelId) async {
    setState(() {
      _isLoadingLabAnalyses = true;
      _labAnalysesError = null;
    });
    try {
      final analyses = await _labAnalysisRepository.listForParcel(parcelId);
      if (!mounted || _parcel?.id != parcelId) return;
      setState(() {
        _labAnalyses = analyses;
        _isLoadingLabAnalyses = false;
      });
      if (analyses.isNotEmpty) {
        await _requestLabRecommendation(_parcel!, analyses.first);
      }
    } catch (_) {
      if (!mounted || _parcel?.id != parcelId) return;
      setState(() {
        _isLoadingLabAnalyses = false;
        _labAnalysesError = 'No se pudieron cargar los análisis.';
      });
    }
  }

  Future<void> _requestLabRecommendation(
    Parcel parcel,
    LabAnalysis analysis,
  ) async {
    if ((analysis.phosphorusMethod?.trim().isEmpty ?? true) ||
        (analysis.potassiumMethod?.trim().isEmpty ?? true)) {
      setState(() {
        _isLoadingFertilization = false;
        _fertilizationRecommendation = null;
        _fertilizationError =
            'Edita el análisis y completa los métodos de fósforo y potasio.';
      });
      return;
    }
    setState(() {
      _isLoadingFertilization = true;
      _fertilizationRecommendation = null;
      _fertilizationError = null;
    });
    try {
      final recommendation = await _fertilizationRepository
          .createFromLabAnalysis(
            parcelId: parcel.id,
            labAnalysisId: analysis.id,
            targetYield: 20,
            yieldUnit: 'qq_gold_ha',
            fruitStage: _fruitStageFor(_stageName),
          );
      if (!mounted || _parcel?.id != parcel.id) return;
      setState(() {
        _fertilizationRecommendation = recommendation;
        _isLoadingFertilization = false;
      });
    } on ApiAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingFertilization = false;
        _fertilizationError = error.message;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingFertilization = false;
        _fertilizationError = _fertilizationErrorMessage(error.message);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingFertilization = false;
        _fertilizationError =
            'No se pudo generar la sugerencia con el análisis de laboratorio.';
      });
    }
  }

  Future<void> _openLabAnalyses(Parcel parcel) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => LabAnalysisScreen(
          parcelId: parcel.id,
          parcelName: parcel.name,
          repository: _labAnalysisRepository,
        ),
      ),
    );
    if (mounted) await _loadLabAnalyses(parcel.id);
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
          if (parcel != null) ...[
            const SizedBox(height: 16),
            LabAnalysisCard(
              analyses: _labAnalyses,
              isLoading: _isLoadingLabAnalyses,
              errorMessage: _labAnalysesError,
              onManage: () => _openLabAnalyses(parcel),
            ),
          ],
          const SizedBox(height: 16),
          TelemetryCard(
            status: sensor.status,
            reading: sensor.lastReading,
            diagnosis: sensor.savedDiagnosis,
            saveStatus: sensor.saveStatus,
            errorMessage: sensor.saveErrorMessage ?? sensor.errorMessage,
            onAction: parcel == null
                ? null
                : () => _handleTelemetryAction(sensor, parcel),
          ),
          const SizedBox(height: 16),
          ConventionalFertilizationCard(
            scenario: _fertilizationRecommendation?.conventionalScenario,
            isLoading: _isLoadingFertilization,
            emptyMessage:
                _fertilizationError ??
                'Captura una muestra para generar las fuentes y dosis.',
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
      final diagnosis = sensor.savedDiagnosis;
      final reading = sensor.lastReading;
      if (diagnosis != null && reading != null) {
        await _requestSensorRecommendation(
          parcel: parcel,
          reading: reading,
          diagnosis: diagnosis,
        );
      }
    }
  }

  Future<void> _requestSensorRecommendation({
    required Parcel parcel,
    required SensorReading reading,
    required SensorDiagnostic diagnosis,
  }) async {
    setState(() {
      _isLoadingFertilization = true;
      _fertilizationRecommendation = null;
      _fertilizationError = null;
    });

    try {
      final recommendation = await _fertilizationRepository
          .createRecommendation(
            parcelId: parcel.id,
            targetYield: 20,
            yieldUnit: 'qq_gold_ha',
            fruitStage: _fruitStageFor(_stageName),
            soilSource: 'sensor',
            nitrogenStatus: _nutrientStatus(
              diagnosis.parameter('nitrogen')?.level,
            ),
            phosphorusStatus: _nutrientStatus(
              diagnosis.parameter('phosphorus')?.level,
            ),
            potassiumStatus: _nutrientStatus(
              diagnosis.parameter('potassium')?.level,
            ),
            ph: reading.ph,
            electricalConductivity: reading.ec / 1000,
          );
      if (!mounted) return;
      setState(() {
        _fertilizationRecommendation = recommendation;
        _isLoadingFertilization = false;
      });
    } on ApiAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingFertilization = false;
        _fertilizationError = error.message;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingFertilization = false;
        _fertilizationError = _fertilizationErrorMessage(error.message);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingFertilization = false;
        _fertilizationError =
            'No se pudo conectar con el motor de fertilización: $error';
      });
    }
  }

  String _fertilizationErrorMessage(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('plants_per_hectare')) {
      return 'Configura la densidad de plantas por hectárea de la parcela.';
    }
    if (normalized.contains('registered variety')) {
      return 'Selecciona una variedad para la parcela.';
    }
    if (normalized.contains('electrical conductivity')) {
      return 'El análisis se guardó, pero una conductividad de 1.1 dS/m o '
          'más requiere revisión por riesgo de salinidad. Verifica la unidad: '
          'si el informe usa µS/cm, divide el valor entre 1,000.';
    }
    if (normalized.contains('sensor-only')) {
      return 'El servidor sigue usando la versión anterior. Reinicia el '
          'backend para habilitar recomendaciones con el sensor.';
    }
    if (normalized.contains('not configured for crop')) {
      return 'El motor de fertilización todavía no está configurado para '
          'este cultivo.';
    }
    return message;
  }

  String _nutrientStatus(SoilDiagnosticLevel? level) {
    switch (level) {
      case SoilDiagnosticLevel.deficient:
        return 'deficient';
      case SoilDiagnosticLevel.optimal:
        return 'adequate';
      case SoilDiagnosticLevel.high:
      case SoilDiagnosticLevel.critical:
        return 'high';
      case null:
        return 'probable_response';
    }
  }

  String _fruitStageFor(String? stageName) {
    switch (stageName?.trim().toLowerCase()) {
      case 'floración':
      case 'floracion':
        return 'flowering';
      case 'cuajado':
        return 'fruit_set';
      case 'expansión':
      case 'expansion':
        return 'expansion';
      case 'llenado':
        return 'filling';
      case 'maduración':
      case 'maduracion':
        return 'ripening';
      case 'cosecha':
        return 'harvest';
      default:
        return 'no_flowering';
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
