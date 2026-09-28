import 'package:flutter/foundation.dart';

import '../../data/api/api_client.dart';
import '../../data/api/finance_repository.dart';
import '../../domain/entities/finance_entry.dart';

enum FinanceStatus { idle, loading, ready, error }

class FinanceProvider extends ChangeNotifier {
  FinanceProvider({FinanceRepository? repository})
    : _repository = repository ?? FinanceRepository();

  final FinanceRepository _repository;

  FinanceStatus status = FinanceStatus.idle;
  List<FinanceEntry> entries = const [];
  String? farmId;
  String? errorMessage;
  bool isSaving = false;

  double get totalIncome => entries
      .where((entry) => entry.type == FinanceEntryType.income)
      .fold(0, (total, entry) => total + entry.amount);

  double get totalExpenses => entries
      .where((entry) => entry.type == FinanceEntryType.expense)
      .fold(0, (total, entry) => total + entry.amount);

  double get balance => totalIncome - totalExpenses;

  Future<void> loadForFarm(String? selectedFarmId, {bool force = false}) async {
    if (selectedFarmId == null) {
      farmId = null;
      entries = const [];
      status = FinanceStatus.idle;
      errorMessage = null;
      notifyListeners();
      return;
    }
    if (!force && selectedFarmId == farmId && status != FinanceStatus.error) {
      return;
    }

    final farmChanged = farmId != selectedFarmId;
    farmId = selectedFarmId;
    if (farmChanged) entries = const [];
    status = FinanceStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final loaded = await _repository.listForFarm(selectedFarmId);
      if (farmId != selectedFarmId) return;
      entries = loaded;
      status = FinanceStatus.ready;
    } catch (error) {
      if (farmId != selectedFarmId) return;
      status = FinanceStatus.error;
      errorMessage = _messageFor(
        error,
        'No se pudieron cargar los movimientos.',
      );
    }
    notifyListeners();
  }

  Future<bool> save(FinanceEntryInput input, {FinanceEntry? existing}) async {
    final selectedFarmId = farmId;
    if (selectedFarmId == null || isSaving) return false;

    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      final saved = existing == null
          ? await _repository.create(selectedFarmId, input)
          : await _repository.update(existing.id, input);
      if (farmId != selectedFarmId) return false;
      entries = existing == null
          ? [...entries, saved]
          : entries
                .map((entry) => entry.id == saved.id ? saved : entry)
                .toList();
      _sortEntries();
      status = FinanceStatus.ready;
      return true;
    } catch (error) {
      errorMessage = _messageFor(error, 'No se pudo guardar el movimiento.');
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> delete(FinanceEntry entry) async {
    if (isSaving) return false;
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.delete(entry);
      entries = entries.where((item) => item.id != entry.id).toList();
      return true;
    } catch (error) {
      errorMessage = _messageFor(error, 'No se pudo eliminar el movimiento.');
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  void _sortEntries() {
    entries.sort((left, right) {
      final dateOrder = right.date.compareTo(left.date);
      return dateOrder != 0 ? dateOrder : right.id.compareTo(left.id);
    });
  }

  String _messageFor(Object error, String fallback) {
    if (error is ApiException) return error.message;
    if (error is ApiAuthException) return error.message;
    return fallback;
  }
}
