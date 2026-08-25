import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/api/parcel_repository.dart';
import '../../data/api/profile_repository.dart';
import '../../domain/entities/crop.dart';
import '../../domain/entities/farm.dart';
import '../../domain/entities/parcel.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/variety.dart';
import '../auth/auth_provider.dart';
import '../farm/farm_provider.dart';

enum _ProfileSection { personal, team, settings }

class _FarmLocationDefaults {
  const _FarmLocationDefaults({this.country, this.department, this.address});

  final String? country;
  final String? department;
  final String? address;
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.parcelRepository,
    this.profileRepository,
  });

  final ParcelRepository? parcelRepository;
  final ProfileRepository? profileRepository;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ParcelRepository _parcelRepository;
  late final ProfileRepository _profileRepository;
  _ProfileSection _section = _ProfileSection.personal;
  UserProfile? _profile;
  List<Parcel> _parcels = const [];
  List<Crop> _crops = const [];
  List<Variety> _varieties = const [];
  String? _profileError;
  String? _summaryError;
  String? _farmSignature;
  String? _locationFarmId;
  _FarmLocationDefaults? _farmLocationDefaults;
  bool _loadingProfile = false;
  bool _loadingSummary = false;
  bool _editingProfile = false;

  @override
  void initState() {
    super.initState();
    _parcelRepository = widget.parcelRepository ?? ParcelRepository();
    _profileRepository = widget.profileRepository ?? ProfileRepository();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  void _scheduleSummary(FarmProvider provider) {
    final farmId = provider.currentFarm?.id;
    final signature = '$farmId:${provider.parcelRevision}';
    if (signature == _farmSignature) return;
    _farmSignature = signature;
    if (farmId == null) {
      _parcels = const [];
      _crops = const [];
      _varieties = const [];
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && signature == _farmSignature) _loadSummary(farmId);
    });
  }

  void _scheduleFarmLocation(Farm? farm) {
    if (farm?.id == _locationFarmId) return;
    _locationFarmId = farm?.id;
    _farmLocationDefaults = null;
    if (farm == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && farm.id == _locationFarmId) {
        _loadFarmLocation(farm);
      }
    });
  }

  Future<void> _loadFarmLocation(Farm farm) async {
    try {
      final placemarks = await Geocoding(
        locale: const Locale('es'),
      ).placemarkFromCoordinates(farm.latitude, farm.longitude);
      if (!mounted || farm.id != _locationFarmId || placemarks.isEmpty) return;
      final place = placemarks.first;
      final addressParts = [
        place.street,
        place.subLocality,
        place.locality,
      ].where((part) => part != null && part.trim().isNotEmpty).toSet();
      setState(() {
        _farmLocationDefaults = _FarmLocationDefaults(
          country: place.country,
          department: place.administrativeArea,
          address: addressParts.join(', '),
        );
      });
    } catch (_) {
      // Native geocoding can be unavailable or rate-limited. Profile loading
      // must continue; the user can still enter the location manually.
    }
  }

  Future<void> _loadProfile() async {
    if (_loadingProfile) return;
    setState(() {
      _loadingProfile = true;
      _profileError = null;
    });
    try {
      final profile = await _profileRepository.getProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loadingProfile = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingProfile = false;
        _profileError = 'No se pudo cargar la información del perfil.';
      });
    }
  }

  Future<void> _loadSummary(String farmId) async {
    setState(() {
      _loadingSummary = true;
      _summaryError = null;
    });
    try {
      final results = await Future.wait([
        _parcelRepository.getParcels(farmId),
        _parcelRepository.getCrops(),
      ]);
      final parcels = results[0] as List<Parcel>;
      final varieties = await Future.wait(
        parcels
            .map((parcel) => parcel.cropId)
            .toSet()
            .map(_parcelRepository.getVarieties),
      );
      if (!mounted || !_farmSignature!.startsWith(farmId)) return;
      setState(() {
        _parcels = parcels;
        _crops = results[1] as List<Crop>;
        _varieties = varieties.expand((items) => items).toList();
        _loadingSummary = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingSummary = false;
        _summaryError = 'No se pudo cargar el resumen agrícola.';
      });
    }
  }

  Future<bool> _saveProfile(UserProfileUpdate update) async {
    setState(() => _loadingProfile = true);
    try {
      final updated = await _profileRepository.updateProfile(update);
      if (!mounted) return false;
      final metadataSaved = await context
          .read<AuthProvider>()
          .updateNameMetadata(update.name);
      if (!mounted) return false;
      setState(() {
        _profile = updated;
        _loadingProfile = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            metadataSaved
                ? 'Perfil actualizado.'
                : 'El perfil se guardó, pero el encabezado no pudo actualizarse.',
          ),
        ),
      );
      return true;
    } catch (_) {
      if (!mounted) return false;
      setState(() => _loadingProfile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar el perfil.')),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthProvider>().user;
    final farmProvider = context.watch<FarmProvider>();
    _scheduleSummary(farmProvider);
    final farm = farmProvider.currentFarm;
    _scheduleFarmLocation(farm);
    final name = _profile?.name ?? authUser?.name ?? 'Usuario Agrifos';
    final email = _profile?.email ?? authUser?.email ?? '';
    final role = _roleLabel(_profile?.role ?? authUser?.role);
    final cropNames = _namesForCrops();
    final varietyNames = _namesForVarieties();

    return ColoredBox(
      color: const Color(0xFFFBF4EF),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            ProfileSummaryCard(
              name: name,
              role: role,
              farm: farm,
              parcelCount: _parcels.length,
              cropCount: cropNames.length,
              onShareProfile: () => _shareProfile(name, email, farm),
              onEditProfile: _profile == null
                  ? null
                  : () => setState(() {
                      _section = _ProfileSection.personal;
                      _editingProfile = true;
                    }),
            ),
            const SizedBox(height: 12),
            _SectionSelector(
              selected: _section,
              onSelected: (section) => setState(() => _section = section),
            ),
            const SizedBox(height: 12),
            switch (_section) {
              _ProfileSection.personal => _PersonalTab(
                profile: _profile,
                fallbackName: name,
                email: email,
                role: role,
                farm: farm,
                locationDefaults: _farmLocationDefaults,
                parcelCount: _parcels.length,
                cropNames: cropNames,
                varietyNames: varietyNames,
                profileError: _profileError,
                summaryLoading: _loadingSummary,
                summaryError: _summaryError,
                editing: _editingProfile,
                onCancelEditing: () => setState(() => _editingProfile = false),
                onEditingComplete: () =>
                    setState(() => _editingProfile = false),
                onRetryProfile: _loadProfile,
                onRetrySummary: farm == null
                    ? null
                    : () => _loadSummary(farm.id),
                onSave: _saveProfile,
              ),
              _ProfileSection.team => const _PlaceholderCard(
                icon: Icons.groups_2_outlined,
                title: 'Equipo',
                message:
                    'La gestión de integrantes estará disponible cuando exista información de equipo asociada a la cuenta.',
              ),
              _ProfileSection.settings => _SettingsTab(
                email: email,
                onSignOut: () => context.read<AuthProvider>().signOut(),
              ),
            },
          ],
        ),
      ),
    );
  }

  List<String> _namesForCrops() {
    final byId = {for (final crop in _crops) crop.id: crop.name};
    return _parcels
        .map((parcel) => byId[parcel.cropId])
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
  }

  List<String> _namesForVarieties() {
    final byId = {for (final variety in _varieties) variety.id: variety.name};
    return _parcels
        .map(
          (parcel) => parcel.varietyId == null ? null : byId[parcel.varietyId],
        )
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
  }

  String _roleLabel(String? role) => switch (role?.toLowerCase()) {
    'admin' => 'Administrador',
    'farmer' => 'Productor',
    _ => 'Usuario',
  };

  Future<void> _shareProfile(String name, String email, Farm? farm) async {
    final text = [name, email, if (farm != null) farm.name].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Datos del perfil copiados.')));
  }
}

@visibleForTesting
class ProfileSummaryCard extends StatelessWidget {
  const ProfileSummaryCard({
    super.key,
    required this.name,
    required this.role,
    required this.farm,
    required this.parcelCount,
    required this.cropCount,
    this.onShareProfile,
    this.onEditProfile,
  });

  final String name;
  final String role;
  final Farm? farm;
  final int parcelCount;
  final int cropCount;
  final VoidCallback? onShareProfile;
  final VoidCallback? onEditProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 118,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF3B1F17), Color(0xFF244D2F)],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  top: 18,
                  child: Text(
                    'AGRIFOS',
                    style: GoogleFonts.josefinSans(
                      color: Colors.white.withValues(alpha: 0.08),
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  bottom: -28,
                  child: _ProfileAvatar(initials: _initials(name)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 38, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.josefinSans(
                    color: const Color(0xFF472319),
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [role, if (farm != null) farm!.name].join(' · '),
                  style: const TextStyle(color: Color(0xFF9B8880)),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onShareProfile,
                        icon: const Icon(Icons.share_outlined, size: 16),
                        label: const Text('Compartir perfil'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onEditProfile,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Editar perfil'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF31543B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _Stat('$parcelCount', 'PARCELAS')),
                    Expanded(child: _Stat('$cropCount', 'CULTIVOS')),
                    Expanded(
                      child: _Stat(
                        farm == null ? '0' : _formatArea(farm!.areaHectares),
                        'HECTÁREAS',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatArea(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);

  static String _initials(String value) => value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          color: Color(0xFF31543B),
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      Text(
        label,
        style: const TextStyle(
          color: Color(0xFFB3A39D),
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) => Container(
    width: 68,
    height: 68,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFFE8F0E8),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 4),
      boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6)],
    ),
    child: Text(
      initials,
      style: GoogleFonts.josefinSans(
        color: const Color(0xFF31543B),
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _SectionSelector extends StatelessWidget {
  const _SectionSelector({required this.selected, required this.onSelected});
  final _ProfileSection selected;
  final ValueChanged<_ProfileSection> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFFEFE5DF),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        _SectionButton(
          icon: Icons.person_outline,
          label: 'Perfil',
          selected: selected == _ProfileSection.personal,
          onTap: () => onSelected(_ProfileSection.personal),
        ),
        _SectionButton(
          icon: Icons.groups_2_outlined,
          label: 'Equipo',
          selected: selected == _ProfileSection.team,
          onTap: () => onSelected(_ProfileSection.team),
        ),
        _SectionButton(
          icon: Icons.settings_outlined,
          label: 'Configuración',
          selected: selected == _ProfileSection.settings,
          onTap: () => onSelected(_ProfileSection.settings),
        ),
      ],
    ),
  );
}

class _SectionButton extends StatelessWidget {
  const _SectionButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 17, color: const Color(0xFF735046)),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    ),
  );
}

class _PersonalTab extends StatefulWidget {
  const _PersonalTab({
    required this.profile,
    required this.fallbackName,
    required this.email,
    required this.role,
    required this.farm,
    required this.locationDefaults,
    required this.parcelCount,
    required this.cropNames,
    required this.varietyNames,
    required this.profileError,
    required this.summaryLoading,
    required this.summaryError,
    required this.editing,
    required this.onCancelEditing,
    required this.onEditingComplete,
    required this.onRetryProfile,
    required this.onRetrySummary,
    required this.onSave,
  });

  final UserProfile? profile;
  final String fallbackName;
  final String email;
  final String role;
  final Farm? farm;
  final _FarmLocationDefaults? locationDefaults;
  final int parcelCount;
  final List<String> cropNames;
  final List<String> varietyNames;
  final String? profileError;
  final bool summaryLoading;
  final String? summaryError;
  final bool editing;
  final VoidCallback onCancelEditing;
  final VoidCallback onEditingComplete;
  final VoidCallback onRetryProfile;
  final VoidCallback? onRetrySummary;
  final Future<bool> Function(UserProfileUpdate) onSave;

  @override
  State<_PersonalTab> createState() => _PersonalTabState();
}

class _PersonalTabState extends State<_PersonalTab> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _birthDate = TextEditingController();
  final _phone = TextEditingController();
  final _country = TextEditingController();
  final _department = TextEditingController();
  final _address = TextEditingController();
  String? _gender;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _resetControllers();
  }

  @override
  void didUpdateWidget(covariant _PersonalTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.editing &&
        (oldWidget.profile != widget.profile ||
            oldWidget.locationDefaults != widget.locationDefaults)) {
      _resetControllers();
    }
    if (widget.editing && !oldWidget.editing) _resetControllers();
    if (widget.editing &&
        oldWidget.locationDefaults != widget.locationDefaults) {
      if (_country.text.trim().isEmpty) {
        _country.text = widget.locationDefaults?.country ?? '';
      }
      if (_department.text.trim().isEmpty) {
        _department.text = widget.locationDefaults?.department ?? '';
      }
      if (_address.text.trim().isEmpty) {
        _address.text = widget.locationDefaults?.address ?? '';
      }
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _birthDate,
      _phone,
      _country,
      _department,
      _address,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (widget.profileError != null)
            _InlineError(
              message: widget.profileError!,
              onRetry: widget.onRetryProfile,
            ),
          if (widget.editing) ...[
            _editingActions(),
            const SizedBox(height: 12),
          ],
          _InfoCard(
            icon: Icons.person_outline,
            title: 'Información personal',
            children: widget.editing
                ? [
                    _EditField(
                      controller: _name,
                      label: 'Nombre completo',
                      validator: (value) => (value?.trim().length ?? 0) < 2
                          ? 'Ingresa al menos 2 caracteres.'
                          : null,
                    ),
                    _EditField(
                      controller: _birthDate,
                      label: 'Fecha de nacimiento',
                      hint: 'Seleccionar fecha',
                      validator: _validateDate,
                      readOnly: true,
                      onTap: _pickBirthDate,
                      suffixIcon: const Icon(Icons.calendar_month_outlined),
                    ),
                    _GenderField(
                      value: _gender,
                      onChanged: (value) => setState(() => _gender = value),
                    ),
                    _ReadOnlyField(label: 'TIPO DE CUENTA', value: widget.role),
                  ]
                : [
                    _ReadOnlyField(
                      label: 'NOMBRE COMPLETO',
                      value: widget.profile?.name ?? widget.fallbackName,
                    ),
                    _ReadOnlyField(
                      label: 'FECHA DE NACIMIENTO',
                      value: _displayDate(widget.profile?.birthDate),
                    ),
                    _ReadOnlyField(
                      label: 'GÉNERO',
                      value: widget.profile?.gender ?? '',
                    ),
                    _ReadOnlyField(label: 'TIPO DE CUENTA', value: widget.role),
                  ],
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.location_on_outlined,
            title: 'Datos de contacto',
            children: widget.editing
                ? [
                    _ReadOnlyField(
                      label: 'CORREO ELECTRÓNICO',
                      value: widget.email,
                    ),
                    _EditField(controller: _phone, label: 'Teléfono'),
                    _EditField(controller: _country, label: 'País'),
                    _EditField(controller: _department, label: 'Departamento'),
                    _EditField(
                      controller: _address,
                      label: 'Dirección',
                      maxLines: 2,
                    ),
                  ]
                : [
                    _ReadOnlyField(
                      label: 'CORREO ELECTRÓNICO',
                      value: widget.email,
                    ),
                    _ReadOnlyField(
                      label: 'TELÉFONO',
                      value: widget.profile?.phone ?? '',
                    ),
                    _ReadOnlyField(
                      label: 'PAÍS',
                      value: _locationValue(
                        widget.profile?.country,
                        widget.locationDefaults?.country,
                      ),
                    ),
                    _ReadOnlyField(
                      label: 'DEPARTAMENTO',
                      value: _locationValue(
                        widget.profile?.department,
                        widget.locationDefaults?.department,
                      ),
                    ),
                    _ReadOnlyField(
                      label: 'DIRECCIÓN',
                      value: _locationValue(
                        widget.profile?.address,
                        widget.locationDefaults?.address,
                      ),
                    ),
                  ],
          ),
          const SizedBox(height: 12),
          _agriculturalCard(),
        ],
      ),
    );
  }

  Widget _editingActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _saving
                ? null
                : () {
                    _resetControllers();
                    widget.onCancelEditing();
                  },
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: const Text('Guardar'),
          ),
        ),
      ],
    );
  }

  Widget _agriculturalCard() => _InfoCard(
    icon: Icons.eco_outlined,
    title: 'Perfil agrícola',
    children: [
      if (widget.farm == null)
        const Text('Registra una finca para completar tu perfil agrícola.')
      else ...[
        _ValueRow(label: 'FINCA', value: widget.farm!.name),
        _ValueRow(
          label: 'SUPERFICIE TOTAL',
          value:
              '${ProfileSummaryCard._formatArea(widget.farm!.areaHectares)} ha',
        ),
        _ValueRow(
          label: 'PARCELAS REGISTRADAS',
          value: '${widget.parcelCount}',
        ),
        if (widget.summaryLoading)
          const LinearProgressIndicator(minHeight: 3)
        else if (widget.summaryError != null)
          _InlineError(
            message: widget.summaryError!,
            onRetry: widget.onRetrySummary,
          )
        else ...[
          _ValueRow(
            label: 'CULTIVOS',
            value: widget.cropNames.isEmpty
                ? 'Sin cultivos registrados'
                : widget.cropNames.join(', '),
          ),
          _ValueRow(
            label: 'VARIEDADES',
            value: widget.varietyNames.isEmpty
                ? 'Sin variedades registradas'
                : widget.varietyNames.join(', '),
          ),
        ],
      ],
    ],
  );

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final birthDate = _birthDate.text.trim().isEmpty
        ? null
        : DateTime.parse(_birthDate.text.trim());
    final saved = await widget.onSave(
      UserProfileUpdate(
        name: _name.text,
        birthDate: birthDate,
        gender: _gender,
        phone: _phone.text,
        country: _country.text,
        department: _department.text,
        address: _address.text,
      ),
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
    });
    if (saved) widget.onEditingComplete();
  }

  void _resetControllers() {
    final profile = widget.profile;
    _name.text = profile?.name ?? widget.fallbackName;
    _birthDate.text = _dateOnly(profile?.birthDate);
    _gender = profile?.gender;
    _phone.text = profile?.phone ?? '';
    _country.text = _locationValue(
      profile?.country,
      widget.locationDefaults?.country,
    );
    _department.text = _locationValue(
      profile?.department,
      widget.locationDefaults?.department,
    );
    _address.text = _locationValue(
      profile?.address,
      widget.locationDefaults?.address,
    );
  }

  String _locationValue(String? saved, String? fallback) {
    if (saved?.trim().isNotEmpty ?? false) return saved!.trim();
    return fallback?.trim() ?? '';
  }

  String? _validateDate(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    return parsed == null || parsed.isAfter(DateTime.now())
        ? 'Usa una fecha válida en formato AAAA-MM-DD.'
        : null;
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final current = DateTime.tryParse(_birthDate.text.trim());
    final selected = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Seleccionar fecha de nacimiento',
    );
    if (selected != null) _birthDate.text = _dateOnly(selected);
  }

  String _dateOnly(DateTime? date) {
    if (date == null) return '';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _displayDate(DateTime? date) {
    if (date == null) return '';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({required this.email, required this.onSignOut});
  final String email;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _InfoCard(
        icon: Icons.lock_outline,
        title: 'Seguridad de la cuenta',
        children: [
          _ReadOnlyField(label: 'CORREO DE LA CUENTA', value: email),
          const Text(
            'Próximamente podrás cambiar tu contraseña y administrar otras opciones de seguridad desde aquí.',
            style: TextStyle(color: Color(0xFF7B6962), height: 1.5),
          ),
        ],
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onSignOut,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Cerrar sesión'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF9B3D35),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    ],
  );
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => _InfoCard(
    icon: icon,
    title: title,
    children: [Text(message, style: const TextStyle(height: 1.5))],
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.children,
  });
  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: _cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF735046)),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.josefinSans(
                color: const Color(0xFF472319),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    ),
  );
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFB19F98),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F7F6),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(value.isEmpty ? 'No especificado' : value),
        ),
      ],
    ),
  );
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
  });
  final TextEditingController controller;
  final String label;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon,
      ),
    ),
  );
}

class _GenderField extends StatelessWidget {
  const _GenderField({required this.value, required this.onChanged});

  static const _options = [
    'Masculino',
    'Femenino',
    'Otro',
    'Prefiero no especificar',
  ];

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = [
      if (value?.trim().isNotEmpty ?? false)
        if (!_options.contains(value)) value!,
      ..._options,
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value?.trim().isEmpty ?? true ? null : value,
        decoration: const InputDecoration(labelText: 'Género'),
        items: options
            .map(
              (option) => DropdownMenuItem(value: option, child: Text(option)),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(0xFFF9F7F6),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFFB19F98), fontSize: 9),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(message, style: const TextStyle(color: Color(0xFF9B3D35))),
      ),
      TextButton(onPressed: onRetry, child: const Text('Reintentar')),
    ],
  );
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(22),
  boxShadow: const [
    BoxShadow(color: Color(0x10000000), blurRadius: 10, offset: Offset(0, 3)),
  ],
);
