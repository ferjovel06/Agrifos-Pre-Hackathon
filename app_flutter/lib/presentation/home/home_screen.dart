import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import '../farm/farm_provider.dart';
import '../farm/farm_registration_screen.dart';
import '../farm/parcel_provider.dart';
import '../sensor/sensor_provider.dart';
import 'latest_reading_provider.dart';
import 'weather_provider.dart';
import 'widgets/last_reading_card.dart';
import 'widgets/farm_parcel_selector_card.dart';
import 'widgets/no_farm_state.dart';
import 'widgets/weather_conditions_card.dart';

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
  String? _currentParcelId;
  String? _loadingParcelId;
  String? _loadedFarmId;
  String? _loadingFarmId;
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
    final weatherProvider = context.read<WeatherProvider>();

    if (mounted) setState(() => _isLoadingParcels = true);

    await farmProvider.loadFarms(force: force, userId: userId);
    if (!mounted) return;

    if (farmProvider.status != FarmStatus.hasFarm) {
      _currentParcelId = null;
      _isLoadingParcels = false;
      // Do not query (or retain data from) a parcel that does not belong to a
      // user who has no farm.
      readingProvider.clear();
      weatherProvider.clear();
      return;
    }

    final farmId = farmProvider.currentFarm?.id;
    if (farmId == null) {
      _isLoadingParcels = false;
      readingProvider.clear();
      weatherProvider.clear();
      return;
    }

    await _loadFarmData(farmId, forceParcels: force);
  }

  Future<void> _loadFarmData(String farmId, {bool forceParcels = false}) async {
    if (_loadingFarmId == farmId) return;
    _loadingFarmId = farmId;
    if (mounted) setState(() => _isLoadingParcels = true);

    final readingProvider = context.read<LatestReadingProvider>();
    final weatherProvider = context.read<WeatherProvider>();
    final parcelProvider = context.read<ParcelProvider>();
    final weatherFuture = weatherProvider.fetchForecast(farmId);

    try {
      await parcelProvider.loadForFarm(farmId, force: forceParcels);
      if (!mounted || context.read<FarmProvider>().selectedFarmId != farmId) {
        return;
      }
      _loadedFarmId = farmId;
      _currentParcelId = parcelProvider.selectedParcelId;
      setState(() => _isLoadingParcels = false);
      if (_currentParcelId == null) {
        readingProvider.clear();
      } else {
        await readingProvider.fetchLatest(_currentParcelId!);
      }
      await weatherFuture;
    } catch (_) {
      if (!mounted || context.read<FarmProvider>().selectedFarmId != farmId) {
        return;
      }
      _loadedFarmId = farmId;
      _currentParcelId = null;
      setState(() => _isLoadingParcels = false);
      readingProvider.clear();
    } finally {
      if (_loadingFarmId == farmId) _loadingFarmId = null;
    }
  }

  Future<void> _loadSelectedParcel(String parcelId) async {
    if (_loadingParcelId == parcelId) return;
    _loadingParcelId = parcelId;
    try {
      await context.read<LatestReadingProvider>().fetchLatest(parcelId);
      if (!mounted ||
          context.read<ParcelProvider>().selectedParcelId != parcelId) {
        return;
      }
      setState(() => _currentParcelId = parcelId);
    } finally {
      if (_loadingParcelId == parcelId) _loadingParcelId = null;
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
    final parcel = context.watch<ParcelProvider>();
    final selectedFarmId = farm.selectedFarmId;
    if (farm.status == FarmStatus.hasFarm &&
        selectedFarmId != null &&
        selectedFarmId != _loadedFarmId &&
        selectedFarmId != _loadingFarmId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            context.read<FarmProvider>().selectedFarmId == selectedFarmId) {
          _loadFarmData(selectedFarmId);
        }
      });
    }
    final selectedParcelId = parcel.selectedParcelId;
    if (selectedParcelId != null &&
        selectedParcelId != _currentParcelId &&
        selectedParcelId != _loadingParcelId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            context.read<ParcelProvider>().selectedParcelId ==
                selectedParcelId) {
          _loadSelectedParcel(selectedParcelId);
        }
      });
    }
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
        return _buildFarmContent(farm);
    }
  }

  Widget _buildFarmContent(FarmProvider farm) {
    if (_isLoadingParcels) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_currentParcelId == null) {
      return _NoParcelState(onRegisterTap: _openParcelRegistration);
    }
    return _Dashboard(
      onRetryWeather: () {
        final farmId = farm.currentFarm?.id;
        if (farmId != null) {
          context.read<WeatherProvider>().fetchForecast(farmId, force: true);
        }
      },
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
              'Solo necesitamos nombre, cultivo, variedad, etapa, área, densidad y fecha de siembra.',
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
  const _Dashboard({
    required this.onRetryWeather,
    required this.onRetryReading,
  });

  final VoidCallback onRetryWeather;
  final VoidCallback onRetryReading;

  @override
  Widget build(BuildContext context) {
    final latestReading = context.watch<LatestReadingProvider>();
    final weather = context.watch<WeatherProvider>();
    final sensor = context.watch<SensorProvider>();
    final isSensorConnected = sensor.status == SensorStatus.connected;

    return SingleChildScrollView(
      child: Column(
        children: [
          const FarmParcelSelectorCard(),
          const SizedBox(height: 14),
          WeatherConditionsCard(
            forecast: weather.forecast,
            isLoading:
                weather.status == WeatherStatus.loading ||
                weather.status == WeatherStatus.initial,
            errorMessage: weather.status == WeatherStatus.error
                ? weather.errorMessage
                : null,
            onRetry: onRetryWeather,
          ),
          const SizedBox(height: 14),
          LastReadingCard(
            reading: latestReading.reading,
            isLoading: latestReading.status == LatestReadingStatus.loading,
            isSensorConnected: isSensorConnected,
            errorMessage: latestReading.status == LatestReadingStatus.error
                ? latestReading.errorMessage
                : null,
            onRetry: onRetryReading,
          ),
        ],
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
