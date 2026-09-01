import 'package:flutter/foundation.dart';

import '../../data/api/api_client.dart';
import '../../data/api/parcel_repository.dart';
import '../../domain/entities/parcel.dart';

enum ParcelStatus { initial, loading, hasParcel, noParcel, error }

/// Holds the parcels for the active farm and the parcel selected by the user.
class ParcelProvider extends ChangeNotifier {
  ParcelProvider({ParcelRepository? parcelRepository})
    : _parcelRepository = parcelRepository ?? ParcelRepository();

  final ParcelRepository _parcelRepository;
  final Map<String, String> _selectionByFarm = {};

  ParcelStatus status = ParcelStatus.initial;
  List<Parcel> parcels = const [];
  String? farmId;
  String? selectedParcelId;
  String? errorMessage;

  Parcel? get currentParcel {
    final selectedId = selectedParcelId;
    if (selectedId == null) return null;
    for (final parcel in parcels) {
      if (parcel.id == selectedId) return parcel;
    }
    return null;
  }

  Future<void> loadForFarm(String? nextFarmId, {bool force = false}) async {
    if (nextFarmId == null) {
      farmId = null;
      parcels = const [];
      selectedParcelId = null;
      status = ParcelStatus.initial;
      errorMessage = null;
      notifyListeners();
      return;
    }
    if (!force && farmId == nextFarmId && status != ParcelStatus.initial) {
      return;
    }

    farmId = nextFarmId;
    parcels = const [];
    selectedParcelId = null;
    status = ParcelStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _parcelRepository.getParcels(nextFarmId);
      if (farmId != nextFarmId) return;
      parcels = result;
      final previousSelection = _selectionByFarm[nextFarmId];
      selectedParcelId = result.any((parcel) => parcel.id == previousSelection)
          ? previousSelection
          : result.firstOrNull?.id;
      if (selectedParcelId case final selectedId?) {
        _selectionByFarm[nextFarmId] = selectedId;
      }
      status = result.isEmpty ? ParcelStatus.noParcel : ParcelStatus.hasParcel;
      notifyListeners();
    } on ApiException catch (error) {
      if (farmId != nextFarmId) return;
      status = ParcelStatus.error;
      errorMessage = error.message;
      notifyListeners();
    } catch (_) {
      if (farmId != nextFarmId) return;
      status = ParcelStatus.error;
      errorMessage = 'No se pudieron cargar las parcelas.';
      notifyListeners();
    }
  }

  void selectParcel(String parcelId) {
    if (selectedParcelId == parcelId ||
        !parcels.any((parcel) => parcel.id == parcelId)) {
      return;
    }
    selectedParcelId = parcelId;
    final currentFarmId = farmId;
    if (currentFarmId != null) _selectionByFarm[currentFarmId] = parcelId;
    notifyListeners();
  }

  void replaceParcel(Parcel updated) {
    parcels = parcels
        .map((parcel) => parcel.id == updated.id ? updated : parcel)
        .toList();
    notifyListeners();
  }
}
