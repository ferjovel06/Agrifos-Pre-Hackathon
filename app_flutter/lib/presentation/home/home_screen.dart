import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/api/parcel_repository.dart';
import '../auth/auth_provider.dart';
import '../farm/farm_provider.dart';
import '../farm/farm_registration_screen.dart';
import '../sensor/sensor_provider.dart';
import 'latest_reading_provider.dart';
import 'widgets/last_reading_card.dart';
import 'widgets/no_farm_state.dart';

/// Home / dashboard tab shown in [MainShell].
///
/// Shows [NoFarmState] instead of the dashboard until the user has
/// registered at least one farm.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _parcelRepository = ParcelRepository();
  String? _currentParcelId;
  bool _isLoadingParcels = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHome());
  }

  Future<void> _loadHome({bool force = false}) async {
    final userId = context.read<AuthProvider>().user?.id;
    final farmProvider = context.read<FarmProvider>();
    final readingProvider = context.read<LatestReadingProvider>();

    if (mounted) setState(() => _isLoadingParcels = true);

    await farmProvider.loadFarms(force: force, userId: userId);
    if (!mounted) return;

    if (farmProvider.status != FarmStatus.hasFarm) {
      _currentParcelId = null;
      _isLoadingParcels = false;
      // Do not query (or retain data from) a parcel that does not belong to a
      // user who has no farm.
      readingProvider.clear();
      return;
    }

    final farmId = farmProvider.currentFarm?.id;
    if (farmId == null) {
      _isLoadingParcels = false;
      readingProvider.clear();
      return;
    }

    try {
      final parcels = await _parcelRepository.getParcels(farmId);
      if (!mounted) return;
      _currentParcelId = parcels.isEmpty ? null : parcels.first.id;
      setState(() => _isLoadingParcels = false);
      if (_currentParcelId == null) {
        readingProvider.clear();
      } else {
        await readingProvider.fetchLatest(_currentParcelId!);
      }
    } catch (_) {
      if (!mounted) return;
      _currentParcelId = null;
      setState(() => _isLoadingParcels = false);
      readingProvider.clear();
    }
  }

  Future<void> _openFarmRegistration() async {
    await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const FarmRegistrationScreen()),
    );
    if (!mounted) return;
    await _loadHome(force: true);
  }

  Future<void> _openParcelRegistration() async {
    final farmId = context.read<FarmProvider>().currentFarm?.id;
    if (farmId == null) return;

    await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => FarmRegistrationScreen(farmId: farmId)),
    );
    if (!mounted) return;
    await _loadHome(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final farm = context.watch<FarmProvider>();
    return _buildBody(farm);
  }

  Widget _buildBody(FarmProvider farm) {
    switch (farm.status) {
      case FarmStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case FarmStatus.error:
        return _FarmLoadError(
          message: farm.errorMessage,
          onRetry: () => _loadHome(force: true),
        );
      case FarmStatus.noFarm:
        return NoFarmState(onRegisterTap: _openFarmRegistration);
      case FarmStatus.hasFarm:
        if (_isLoadingParcels) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_currentParcelId == null) {
          return _NoParcelState(onRegisterTap: _openParcelRegistration);
        }
        return _Dashboard(
          onRetryReading: () {
            final parcelId = _currentParcelId;
            if (parcelId == null) {
              _loadHome(force: true);
            } else {
              context.read<LatestReadingProvider>().fetchLatest(parcelId);
            }
          },
        );
    }
  }
}

class _NoParcelState extends StatelessWidget {
  const _NoParcelState({required this.onRegisterTap});

  final VoidCallback onRegisterTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.grid_view_outlined,
                size: 38,
                color: Color(0xFF2E4A2E),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Agrega tu primera parcela',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF472319),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Solo necesitamos nombre, cultivo, variedad, etapa, área y fecha de siembra.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRegisterTap,
              icon: const Icon(Icons.add),
              label: const Text('Registrar parcela'),
            ),
          ],
        ),
      ),
    );
  }
}

/// The existing dashboard content, shown once the user has a farm.
class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.onRetryReading});

  final VoidCallback onRetryReading;

  @override
  Widget build(BuildContext context) {
    final latestReading = context.watch<LatestReadingProvider>();
    final sensor = context.watch<SensorProvider>();
    final isSensorConnected = sensor.status == SensorStatus.connected;

    return SingleChildScrollView(
      child: LastReadingCard(
        reading: latestReading.reading,
        isLoading: latestReading.status == LatestReadingStatus.loading,
        isSensorConnected: isSensorConnected,
        errorMessage: latestReading.status == LatestReadingStatus.error
            ? latestReading.errorMessage
            : null,
        onRetry: onRetryReading,
      ),
    );
  }
}

class _FarmLoadError extends StatelessWidget {
  const _FarmLoadError({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 36, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            message ?? 'No se pudieron cargar tus fincas.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
