import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../data/api/farm_repository.dart';
import '../../data/api/parcel_repository.dart';
import '../../domain/entities/crop.dart';
import '../../domain/entities/farm.dart';
import '../../domain/entities/parcel.dart';
import '../../domain/entities/phenological_stage.dart';
import '../../domain/entities/variety.dart';
import 'farm_provider.dart';
import 'parcel_provider.dart';

class FarmEditScreen extends StatefulWidget {
  const FarmEditScreen({super.key, required this.farm});
  final Farm farm;
  @override
  State<FarmEditScreen> createState() => _FarmEditScreenState();
}

class _FarmEditScreenState extends State<FarmEditScreen> {
  final key = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.farm.name);
  late final area = TextEditingController(text: '${widget.farm.areaHectares}');
  late double latitude = widget.farm.latitude;
  late double longitude = widget.farm.longitude;
  bool saving = false;
  bool locating = false;

  @override
  void dispose() {
    name.dispose();
    area.dispose();
    super.dispose();
  }

  Future<void> updateLocation() async {
    setState(() => locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception();
      }
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
        locating = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => locating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener la ubicación.')),
      );
    }
  }

  Future<void> save() async {
    if (!key.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      final updated = await FarmRepository().updateFarm(
        id: widget.farm.id,
        name: name.text.trim(),
        areaHectares: double.parse(area.text),
        latitude: latitude,
        longitude: longitude,
      );
      if (!mounted) return;
      context.read<FarmProvider>().replaceFarm(updated);
      Navigator.pop(context, updated);
    } catch (_) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo actualizar la finca.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => _EditScaffold(
    title: 'Editar finca',
    subtitle: 'Actualiza la información general de tu finca',
    icon: Icons.eco_outlined,
    saving: saving,
    onSave: save,
    child: Form(
      key: key,
      child: Column(
        children: [
          _field(name, 'Nombre de la finca', icon: Icons.badge_outlined),
          _field(area, 'Área total (ha)', number: true, icon: Icons.straighten),
          const _SectionLabel(
            icon: Icons.location_on_outlined,
            text: 'Ubicación',
          ),
          _FarmLocationMap(latitude: latitude, longitude: longitude),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: locating ? null : updateLocation,
              icon: locating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(
                locating ? 'Obteniendo ubicación...' : 'Usar ubicación actual',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class ParcelEditScreen extends StatefulWidget {
  const ParcelEditScreen({
    super.key,
    required this.parcel,
    required this.farm,
    this.repository,
  });
  final Parcel parcel;
  final Farm farm;
  final ParcelRepository? repository;
  @override
  State<ParcelEditScreen> createState() => _ParcelEditScreenState();
}

class _ParcelEditScreenState extends State<ParcelEditScreen> {
  final key = GlobalKey<FormState>();
  late final ParcelRepository repository;
  late final name = TextEditingController(text: widget.parcel.name);
  late final area = TextEditingController(
    text: '${widget.parcel.areaHectares}',
  );
  late final density = TextEditingController(
    text: '${widget.parcel.plantsPerHectare ?? ''}',
  );
  late DateTime plantingDate = widget.parcel.plantingDate;
  bool saving = false;
  bool loadingOptions = true;
  String? optionsError;
  List<Crop> crops = const [];
  List<Variety> varieties = const [];
  List<PhenologicalStageTemplate> stageTemplates = const [];
  late String selectedCropId = widget.parcel.cropId;
  String? selectedVarietyId;
  String? selectedStageTemplateId;
  int optionsLoadToken = 0;

  @override
  void initState() {
    super.initState();
    repository = widget.repository ?? ParcelRepository();
    selectedVarietyId = widget.parcel.varietyId;
    loadInitialOptions();
  }

  Future<void> loadInitialOptions() async {
    final loadToken = ++optionsLoadToken;
    try {
      final results = await Future.wait([
        repository.getCrops(),
        repository.getVarieties(selectedCropId),
        repository.getStageTemplates(selectedCropId),
        repository.getStageInstances(widget.parcel.id),
      ]);
      if (!mounted || loadToken != optionsLoadToken) return;
      final instances = results[3] as List<PhenologicalStageInstance>;
      setState(() {
        crops = results[0] as List<Crop>;
        varieties = results[1] as List<Variety>;
        stageTemplates = results[2] as List<PhenologicalStageTemplate>;
        selectedStageTemplateId = currentStage(instances)?.templateId;
        loadingOptions = false;
        optionsError = null;
      });
    } catch (_) {
      if (!mounted || loadToken != optionsLoadToken) return;
      setState(() {
        loadingOptions = false;
        optionsError = 'No se pudieron cargar los cultivos y etapas.';
      });
    }
  }

  PhenologicalStageInstance? currentStage(
    List<PhenologicalStageInstance> instances,
  ) {
    if (instances.isEmpty) return null;
    final sorted = [...instances]
      ..sort((a, b) {
        final aDate = a.selectedAt ?? a.actualDate;
        final bDate = b.selectedAt ?? b.actualDate;
        if (aDate == null && bDate == null) {
          return b.stageOrder.compareTo(a.stageOrder);
        }
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });
    return sorted.first;
  }

  Future<void> selectCrop(String cropId) async {
    if (cropId == selectedCropId) return;
    final loadToken = ++optionsLoadToken;
    setState(() {
      selectedCropId = cropId;
      selectedVarietyId = null;
      selectedStageTemplateId = null;
      varieties = const [];
      stageTemplates = const [];
      loadingOptions = true;
      optionsError = null;
    });
    try {
      final results = await Future.wait([
        repository.getVarieties(cropId),
        repository.getStageTemplates(cropId),
      ]);
      if (!mounted || loadToken != optionsLoadToken) return;
      setState(() {
        varieties = results[0] as List<Variety>;
        stageTemplates = results[1] as List<PhenologicalStageTemplate>;
        loadingOptions = false;
      });
    } catch (_) {
      if (!mounted || loadToken != optionsLoadToken) return;
      setState(() {
        loadingOptions = false;
        optionsError = 'No se pudieron cargar las opciones del cultivo.';
      });
    }
  }

  @override
  void dispose() {
    name.dispose();
    area.dispose();
    density.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: plantingDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (value != null) setState(() => plantingDate = value);
  }

  Future<void> save() async {
    if (!key.currentState!.validate()) return;
    if (selectedVarietyId == null || selectedStageTemplateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la variedad y la etapa.')),
      );
      return;
    }
    setState(() => saving = true);
    try {
      final updated = await repository.updateParcelConfiguration(
        id: widget.parcel.id,
        cropId: selectedCropId,
        varietyId: selectedVarietyId!,
        stageTemplateId: selectedStageTemplateId!,
        name: name.text.trim(),
        areaHectares: double.parse(area.text),
        plantsPerHectare: int.parse(density.text),
        plantingDate: plantingDate,
      );
      if (!mounted) return;
      context.read<ParcelProvider>().replaceParcel(updated);
      context.read<FarmProvider>().notifyParcelChanged();
      Navigator.pop(context, updated);
    } catch (_) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo actualizar la parcela.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => _EditScaffold(
    title: 'Editar parcela',
    subtitle: 'Mantén actualizados los datos productivos',
    icon: Icons.grid_view_rounded,
    saving: saving,
    onSave: save,
    child: Form(
      key: key,
      child: Column(
        children: [
          if (loadingOptions)
            const Padding(
              padding: EdgeInsets.only(bottom: 18),
              child: LinearProgressIndicator(),
            )
          else if (optionsError != null)
            _OptionsError(message: optionsError!, onRetry: loadInitialOptions),
          _selector<String>(
            value: crops.any((item) => item.id == selectedCropId)
                ? selectedCropId
                : null,
            label: 'Cultivo',
            icon: Icons.eco_outlined,
            items: crops
                .map(
                  (item) =>
                      DropdownMenuItem(value: item.id, child: Text(item.name)),
                )
                .toList(),
            onChanged: loadingOptions
                ? null
                : (value) {
                    if (value != null) selectCrop(value);
                  },
          ),
          _selector<String>(
            value: varieties.any((item) => item.id == selectedVarietyId)
                ? selectedVarietyId
                : null,
            label: 'Variedad',
            icon: Icons.spa_outlined,
            items: varieties
                .map(
                  (item) =>
                      DropdownMenuItem(value: item.id, child: Text(item.name)),
                )
                .toList(),
            onChanged: loadingOptions
                ? null
                : (value) => setState(() => selectedVarietyId = value),
          ),
          _selector<String>(
            value:
                stageTemplates.any((item) => item.id == selectedStageTemplateId)
                ? selectedStageTemplateId
                : null,
            label: 'Etapa fenológica actual',
            icon: Icons.timeline,
            items: stageTemplates
                .map(
                  (item) =>
                      DropdownMenuItem(value: item.id, child: Text(item.name)),
                )
                .toList(),
            onChanged: loadingOptions
                ? null
                : (value) => setState(() => selectedStageTemplateId = value),
          ),
          _field(name, 'Nombre de la parcela', icon: Icons.label_outline),
          _field(
            area,
            'Área (ha)',
            number: true,
            max: widget.farm.areaHectares,
            icon: Icons.straighten,
          ),
          _field(
            density,
            'Densidad (plantas/ha)',
            integer: true,
            icon: Icons.grass,
          ),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDDE6DB)),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.calendar_month_outlined,
                  color: Color(0xFF31543B),
                ),
                title: const Text('Fecha de siembra'),
                subtitle: Text(
                  '${plantingDate.day}/${plantingDate.month}/${plantingDate.year}',
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _selector<T>({
  required T? value,
  required String label,
  required IconData icon,
  required List<DropdownMenuItem<T>> items,
  required ValueChanged<T?>? onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: DropdownButtonFormField<T>(
      key: ValueKey('$label:$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF31543B)),
      ),
      items: items,
      onChanged: onChanged,
      validator: (selected) =>
          selected == null ? 'Selecciona una opción.' : null,
    ),
  );
}

class _OptionsError extends StatelessWidget {
  const _OptionsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: Colors.redAccent),
        const SizedBox(width: 8),
        Expanded(child: Text(message)),
        TextButton(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    ),
  );
}

Widget _field(
  TextEditingController controller,
  String label, {
  bool number = false,
  bool integer = false,
  double? max,
  IconData? icon,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null
            ? null
            : Icon(icon, color: const Color(0xFF31543B)),
      ),
      keyboardType: number || integer
          ? TextInputType.number
          : TextInputType.text,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Este campo es obligatorio.';
        }
        if (number || integer) {
          final parsed = num.tryParse(value);
          if (parsed == null || parsed <= 0) {
            return 'Ingresa un valor mayor que cero.';
          }
          if (integer && parsed % 1 != 0) {
            return 'Ingresa un número entero.';
          }
          if (max != null && parsed > max) {
            return 'No puede superar el área de la finca.';
          }
        } else if (value.trim().length < 2) {
          return 'Ingresa al menos 2 caracteres.';
        }
        return null;
      },
    ),
  );
}

class _EditScaffold extends StatelessWidget {
  const _EditScaffold({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    required this.saving,
    required this.onSave,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final bool saving;
  final VoidCallback onSave;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      foregroundColor: const Color(0xFF472319),
      backgroundColor: const Color(0xFFFBF4EF),
      surfaceTintColor: Colors.transparent,
    ),
    backgroundColor: const Color(0xFFFBF4EF),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE8E1DC)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D472319),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF1E9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: const Color(0xFF31543B)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF472319),
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF77716E),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  child,
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: saving ? null : onSave,
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF31543B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                label: Text(saving ? 'Guardando...' : 'Guardar cambios'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 2, bottom: 12),
    child: Row(
      children: [
        Icon(icon, size: 19, color: const Color(0xFF31543B)),
        const SizedBox(width: 7),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF472319),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _FarmLocationMap extends StatelessWidget {
  const _FarmLocationMap({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 190,
        child: FlutterMap(
          key: ValueKey('$latitude:$longitude'),
          options: MapOptions(initialCenter: point, initialZoom: 15),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'dev.agrifos.agrifos',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 52,
                  height: 52,
                  child: const Icon(
                    Icons.location_pin,
                    size: 46,
                    color: Color(0xFF31543B),
                  ),
                ),
              ],
            ),
            const Align(
              alignment: Alignment.bottomRight,
              child: ColoredBox(
                color: Color(0xD9FFFFFF),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  child: Text(
                    '© OpenStreetMap contributors',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
