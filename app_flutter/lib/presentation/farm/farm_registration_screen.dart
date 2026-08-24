import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../data/api/parcel_repository.dart';
import '../../domain/entities/crop.dart';
import '../../shared/field_label.dart';
import 'farm_provider.dart';

/// A minimal two-step flow that creates a farm and its first parcel.
class FarmRegistrationScreen extends StatefulWidget {
  const FarmRegistrationScreen({super.key, this.farmId});

  /// When supplied, opens directly on parcel registration for this farm.
  final String? farmId;

  @override
  State<FarmRegistrationScreen> createState() => _FarmRegistrationScreenState();
}

class _FarmRegistrationScreenState extends State<FarmRegistrationScreen> {
  final _farmFormKey = GlobalKey<FormState>();
  final _parcelFormKey = GlobalKey<FormState>();
  final _farmNameController = TextEditingController();
  final _farmAreaController = TextEditingController();
  final _parcelNameController = TextEditingController();
  final _parcelAreaController = TextEditingController();
  final _parcelRepository = ParcelRepository();

  int _step = 0;
  bool _isSubmitting = false;
  bool _isLocating = false;
  bool _isLoadingCrops = true;
  double? _latitude;
  double? _longitude;
  double? _locationAccuracy;
  String? _locationError;
  String? _cropError;
  String? _selectedCropId;
  String? _createdFarmId;
  DateTime _plantingDate = DateTime.now();
  List<Crop> _crops = [];

  static const _brandGreen = Color(0xFF2E4A2E);
  static const _titleColor = Color(0xFF472319);
  static const _pageBackground = Color(0xFFF9F2EC);

  @override
  void initState() {
    super.initState();
    if (widget.farmId != null) {
      _createdFarmId = widget.farmId;
      _step = 1;
    }
    _loadCrops();
  }

  @override
  void dispose() {
    _farmNameController.dispose();
    _farmAreaController.dispose();
    _parcelNameController.dispose();
    _parcelAreaController.dispose();
    super.dispose();
  }

  Future<void> _loadCrops() async {
    try {
      final crops = await _parcelRepository.getCrops();
      if (!mounted) return;
      setState(() {
        _crops = crops;
        _isLoadingCrops = false;
        _cropError = crops.isEmpty ? 'No hay cultivos disponibles.' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingCrops = false;
        _cropError = 'No se pudieron cargar los cultivos.';
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() => _locationError = 'Activa la ubicación del dispositivo.');
        _showLocationSettingsSnackBar();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() {
          _locationError = 'Necesitamos permiso para obtener la ubicación.';
        });
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locationError = 'Habilita el permiso de ubicación en Ajustes.';
        });
        _showAppSettingsSnackBar();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationAccuracy = position.accuracy;
        _locationError = null;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _locationError =
            'No pudimos obtener la ubicación. Intenta al aire libre.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationError = 'No se pudo obtener la ubicación. Intenta de nuevo.';
      });
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _submitFarm() async {
    if (!_farmFormKey.currentState!.validate()) return;
    final latitude = _latitude;
    final longitude = _longitude;
    if (latitude == null || longitude == null) {
      setState(() {
        _locationError = 'Obtén la ubicación de la finca antes de continuar.';
      });
      return;
    }

    setState(() => _isSubmitting = true);
    final farmProvider = context.read<FarmProvider>();
    final ok = await farmProvider.createFarm(
      name: _farmNameController.text.trim(),
      areaHectares: double.parse(_farmAreaController.text.trim()),
      latitude: latitude,
      longitude: longitude,
    );
    if (!mounted) return;

    final createdFarm = farmProvider.currentFarm;
    setState(() => _isSubmitting = false);
    if (ok && createdFarm != null) {
      setState(() {
        _createdFarmId = createdFarm.id;
        _step = 1;
      });
      return;
    }

    _showError(farmProvider.errorMessage ?? 'No se pudo registrar la finca.');
  }

  Future<void> _submitParcel() async {
    if (!_parcelFormKey.currentState!.validate()) return;
    final farmId = _createdFarmId;
    final cropId = _selectedCropId;
    if (farmId == null || cropId == null) {
      setState(() => _cropError = 'Selecciona el cultivo de la parcela.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final parcel = await _parcelRepository.createParcel(
        farmId: farmId,
        cropId: cropId,
        name: _parcelNameController.text.trim(),
        areaHectares: double.parse(_parcelAreaController.text.trim()),
        plantingDate: _plantingDate,
      );
      if (!mounted) return;
      Navigator.of(context).pop(parcel.id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showError('No se pudo registrar la parcela: $error');
    }
  }

  Future<void> _pickPlantingDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _plantingDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Fecha de siembra',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (selected != null && mounted) {
      setState(() => _plantingDate = selected);
    }
  }

  void _showLocationSettingsSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('La ubicación del dispositivo está desactivada.'),
        action: SnackBarAction(
          label: 'Activar',
          onPressed: Geolocator.openLocationSettings,
        ),
      ),
    );
  }

  void _showAppSettingsSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('El permiso de ubicación está bloqueado.'),
        action: SnackBarAction(
          label: 'Ajustes',
          onPressed: Geolocator.openAppSettings,
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _requiredNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo requerido.';
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0) return 'Ingresa un área válida.';
    return null;
  }

  String? _parcelAreaValidator(String? value) {
    final requiredError = _requiredNumber(value);
    if (requiredError != null) return requiredError;

    final parcelArea = double.parse(value!.trim());
    final farmArea = double.tryParse(_farmAreaController.text.trim());
    if (farmArea != null && parcelArea > farmArea) {
      return 'No puede superar el área total de la finca.';
    }
    return null;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: _brandGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registro territorial',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            Text(
              'FINCA Y PARCELA',
              style: TextStyle(fontSize: 9, letterSpacing: 1.8),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _StepHeader(currentStep: _step),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _step == 0 ? _buildFarmStep() : _buildParcelStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmStep() {
    return SingleChildScrollView(
      key: const ValueKey('farm-step'),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      child: Form(
        key: _farmFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RegistrationCard(
              icon: Icons.eco_outlined,
              title: 'Datos de la finca',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FieldLabel('NOMBRE DE LA FINCA'),
                  TextFormField(
                    controller: _farmNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Ej. Finca La Esperanza',
                    ),
                    validator: (value) =>
                        value == null || value.trim().length < 2
                        ? 'Ingresa el nombre de la finca.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  const FieldLabel('ÁREA TOTAL (HECTÁREAS)'),
                  TextFormField(
                    controller: _farmAreaController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(hintText: 'Ej. 12.5'),
                    validator: _requiredNumber,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _RegistrationCard(
              icon: Icons.location_on_outlined,
              title: 'Ubicación',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Obtén la ubicación mientras estés en la finca.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _isLocating || _isSubmitting
                        ? null
                        : _getCurrentLocation,
                    icon: _isLocating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _latitude == null
                                ? Icons.my_location
                                : Icons.check_circle_outline,
                          ),
                    label: Text(
                      _isLocating
                          ? 'Obteniendo ubicación...'
                          : _latitude == null
                          ? 'Usar ubicación actual'
                          : 'Ubicación guardada · ${_locationAccuracy!.round()} m',
                    ),
                  ),
                  if (_locationError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _locationError!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            _PrimaryButton(
              label: 'Continuar a parcela',
              loading: _isSubmitting,
              onPressed: _isLocating ? null : _submitFarm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParcelStep() {
    return SingleChildScrollView(
      key: const ValueKey('parcel-step'),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      child: Form(
        key: _parcelFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RegistrationCard(
              icon: Icons.grid_view_outlined,
              title: 'Datos de la parcela',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FieldLabel('NOMBRE DE LA PARCELA'),
                  TextFormField(
                    controller: _parcelNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Ej. Parcela Norte',
                    ),
                    validator: (value) =>
                        value == null || value.trim().length < 2
                        ? 'Ingresa el nombre de la parcela.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  const FieldLabel('ÁREA (HECTÁREAS)'),
                  TextFormField(
                    controller: _parcelAreaController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(hintText: 'Ej. 4.5'),
                    validator: _parcelAreaValidator,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _RegistrationCard(
              icon: Icons.grass_outlined,
              title: 'Cultivo',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FieldLabel('TIPO DE CULTIVO'),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCropId,
                    items: _crops
                        .map(
                          (crop) => DropdownMenuItem(
                            value: crop.id,
                            child: Text(crop.name),
                          ),
                        )
                        .toList(),
                    onChanged: _isLoadingCrops
                        ? null
                        : (value) => setState(() {
                            _selectedCropId = value;
                            _cropError = null;
                          }),
                    decoration: InputDecoration(
                      hintText: _isLoadingCrops
                          ? 'Cargando cultivos...'
                          : 'Seleccionar cultivo',
                    ),
                    validator: (value) =>
                        value == null ? 'Selecciona un cultivo.' : null,
                  ),
                  if (_cropError != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _cropError!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _isLoadingCrops = true);
                            _loadCrops();
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  const FieldLabel('FECHA DE SIEMBRA'),
                  OutlinedButton.icon(
                    onPressed: _pickPlantingDate,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(_formatDate(_plantingDate)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _PrimaryButton(
              label: 'Guardar finca y parcela',
              loading: _isSubmitting,
              onPressed: _isLoadingCrops ? null : _submitParcel,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _FarmRegistrationScreenState._brandGreen,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF1F3B25),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            _StepTab(label: 'Finca', active: currentStep == 0),
            _StepTab(label: 'Parcela', active: currentStep == 1),
          ],
        ),
      ),
    );
  }
}

class _StepTab extends StatelessWidget {
  const _StepTab({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? const Color(0xFF472319) : Colors.white70,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RegistrationCard extends StatelessWidget {
  const _RegistrationCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: _FarmRegistrationScreenState._brandGreen,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: _FarmRegistrationScreenState._titleColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: _FarmRegistrationScreenState._brandGreen,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}
