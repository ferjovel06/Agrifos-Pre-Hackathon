import 'package:flutter/foundation.dart';

import '../../data/api/api_client.dart';
import '../../data/api/farm_repository.dart';
import '../../domain/entities/farm.dart';

enum FarmStatus { loading, hasFarm, noFarm, error }

/// Holds the farms owned by the current user and drives whether the app
/// shows the dashboard or the "register your farm" empty state.
class FarmProvider extends ChangeNotifier {
  final FarmRepository _farmRepository;

  FarmProvider({FarmRepository? farmRepository})
    : _farmRepository = farmRepository ?? FarmRepository();

  FarmStatus status = FarmStatus.loading;
  List<Farm> farms = [];
  String? _selectedFarmId;
  String? errorMessage;
  int parcelRevision = 0;

  String? get selectedFarmId => _selectedFarmId;

  /// The farm selected by the user, once farms have been loaded.
  Farm? get currentFarm {
    final selectedId = _selectedFarmId;
    if (selectedId == null) return null;
    for (final farm in farms) {
      if (farm.id == selectedId) return farm;
    }
    return null;
  }

  /// Selects the farm used by every farm-scoped screen.
  void selectFarm(String farmId) {
    if (_selectedFarmId == farmId || !farms.any((farm) => farm.id == farmId)) {
      return;
    }
    _selectedFarmId = farmId;
    notifyListeners();
  }

  void notifyParcelChanged() {
    parcelRevision++;
    notifyListeners();
  }

  bool _hasLoadedOnce = false;
  String? _loadedUserId;

  /// Fetches the current user's farms.
  Future<void> loadFarms({bool force = false, String? userId}) async {
    if (userId == null) {
      farms = [];
      _selectedFarmId = null;
      _loadedUserId = null;
      _hasLoadedOnce = false;
      status = FarmStatus.loading;
      notifyListeners();
      return;
    }

    final userChanged = _loadedUserId != null && _loadedUserId != userId;
    if (_hasLoadedOnce && !force && !userChanged) return;

    status = FarmStatus.loading;
    errorMessage = null;
    if (userChanged) farms = [];
    notifyListeners();

    try {
      final result = await _farmRepository.getFarms();
      // Admins receive every farm from GET /farms. The mobile home screen is
      // user-specific, so only the authenticated user's farms should decide
      // whether its empty state is shown.
      farms = result.where((farm) => farm.userId == userId).toList();
      if (!farms.any((farm) => farm.id == _selectedFarmId)) {
        _selectedFarmId = farms.firstOrNull?.id;
      }
      _loadedUserId = userId;
      _hasLoadedOnce = true;
      status = farms.isEmpty ? FarmStatus.noFarm : FarmStatus.hasFarm;
      notifyListeners();
    } on ApiAuthException catch (e) {
      status = FarmStatus.error;
      errorMessage = e.message;
      notifyListeners();
    } on ApiException catch (e) {
      status = FarmStatus.error;
      errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      status = FarmStatus.error;
      errorMessage = 'No se pudieron cargar tus fincas: $e';
      notifyListeners();
    }
  }

  /// Registers a new farm for the current user and refreshes the farm
  /// list on success. Returns `true` on success.
  Future<bool> createFarm({
    required String name,
    required double areaHectares,
    required double latitude,
    required double longitude,
  }) async {
    errorMessage = null;
    notifyListeners();

    try {
      final farm = await _farmRepository.createFarm(
        name: name,
        areaHectares: areaHectares,
        latitude: latitude,
        longitude: longitude,
      );
      farms = [farm, ...farms];
      _selectedFarmId = farm.id;
      _hasLoadedOnce = true;
      status = FarmStatus.hasFarm;
      notifyListeners();
      return true;
    } on ApiAuthException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = 'No se pudo registrar la finca: $e';
      notifyListeners();
      return false;
    }
  }
}
