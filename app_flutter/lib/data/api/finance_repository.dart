import '../../domain/entities/finance_dashboard.dart';
import '../../domain/entities/finance_entry.dart';
import 'api_client.dart';

class FinanceRepository {
  FinanceRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<FinanceDashboardMetrics> getDashboard(String farmId) async {
    final response = await _client.get(
      '/finances/dashboard',
      query: {'farm_id': farmId},
    );
    return FinanceDashboardMetrics.fromJson(response as Map<String, dynamic>);
  }

  Future<List<FinanceEntry>> listForFarm(String farmId) async {
    final responses = await Future.wait([
      _client.get('/finances/incomes', query: {'farm_id': farmId}),
      _client.get('/finances/expenses', query: {'farm_id': farmId}),
    ]);
    final incomes = (responses[0] as List<dynamic>).map(
      (item) => FinanceEntry.fromIncomeJson(item as Map<String, dynamic>),
    );
    final expenses = (responses[1] as List<dynamic>).map(
      (item) => FinanceEntry.fromExpenseJson(item as Map<String, dynamic>),
    );
    final entries = [...incomes, ...expenses];
    entries.sort((left, right) {
      final dateOrder = right.date.compareTo(left.date);
      return dateOrder != 0 ? dateOrder : right.id.compareTo(left.id);
    });
    return entries;
  }

  Future<FinanceEntry> create(String farmId, FinanceEntryInput input) async {
    final response = await _client.post(
      _collectionPath(input.type),
      input.toJson(farmId: farmId),
    );
    return _fromJson(input.type, response);
  }

  Future<FinanceEntry> update(String id, FinanceEntryInput input) async {
    final response = await _client.patch(
      '${_collectionPath(input.type)}/$id',
      input.toJson(),
    );
    return _fromJson(input.type, response);
  }

  Future<void> delete(FinanceEntry entry) {
    return _client.delete('${_collectionPath(entry.type)}/${entry.id}');
  }

  static String _collectionPath(FinanceEntryType type) {
    return type == FinanceEntryType.income
        ? '/finances/incomes'
        : '/finances/expenses';
  }

  static FinanceEntry _fromJson(
    FinanceEntryType type,
    Map<String, dynamic> json,
  ) {
    return type == FinanceEntryType.income
        ? FinanceEntry.fromIncomeJson(json)
        : FinanceEntry.fromExpenseJson(json);
  }
}
