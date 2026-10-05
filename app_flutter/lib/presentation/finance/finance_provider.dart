import 'package:flutter/foundation.dart';

import '../../data/api/api_client.dart';
import '../../data/api/finance_repository.dart';
import '../../domain/entities/finance_dashboard.dart';
import '../../domain/entities/finance_entry.dart';

enum FinanceStatus { idle, loading, ready, error }

class FinanceProvider extends ChangeNotifier {
  FinanceProvider({FinanceRepository? repository})
    : _repository = repository ?? FinanceRepository();

  final FinanceRepository _repository;

  FinanceStatus status = FinanceStatus.idle;
  FinanceDashboardMetrics? dashboard;
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
      dashboard = null;
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
    if (farmChanged) {
      dashboard = null;
      entries = const [];
    }
    status = FinanceStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait<Object>([
        _repository.listForFarm(selectedFarmId),
        _repository.getDashboard(selectedFarmId),
      ]);
      if (farmId != selectedFarmId) return;
      entries = results[0] as List<FinanceEntry>;
      dashboard = results[1] as FinanceDashboardMetrics;
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
      await _refreshDashboard(selectedFarmId);
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
      final selectedFarmId = farmId;
      if (selectedFarmId != null) await _refreshDashboard(selectedFarmId);
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

  Future<void> _refreshDashboard(String selectedFarmId) async {
    try {
      final refreshed = await _repository.getDashboard(selectedFarmId);
      if (farmId == selectedFarmId) dashboard = refreshed;
    } catch (error) {
      if (farmId == selectedFarmId) {
        errorMessage = _messageFor(
          error,
          'El movimiento se actualizó, pero no se pudo refrescar el resumen.',
        );
      }
    }
  }

  String _messageFor(Object error, String fallback) {
    if (error is ApiException) return error.message;
    if (error is ApiAuthException) return error.message;
    return fallback;
  }
}
