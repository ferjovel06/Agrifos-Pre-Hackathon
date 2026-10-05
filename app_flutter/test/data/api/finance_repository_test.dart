import 'package:app_flutter/data/api/api_client.dart';
import 'package:app_flutter/data/api/finance_repository.dart';
import 'package:app_flutter/domain/entities/finance_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('combines income and expenses in newest-first order', () async {
    final client = _ApiClientStub()
      ..incomes = [
        {
          'id': 'income-1',
          'farm_id': 'farm-1',
          'category': 'Venta de café',
          'amount': 200,
          'income_date': '2026-09-20',
        },
      ]
      ..expenses = [
        {
          'id': 'expense-1',
          'farm_id': 'farm-1',
          'category': 'Insumos',
          'amount': 50,
          'expense_date': '2026-09-25',
        },
      ];

    final entries = await FinanceRepository(
      client: client,
    ).listForFarm('farm-1');

    expect(entries.map((entry) => entry.id), ['expense-1', 'income-1']);
    expect(client.queries, [
      ('/finances/incomes', 'farm-1'),
      ('/finances/expenses', 'farm-1'),
    ]);
  });

  test('uses the correct endpoint when creating an expense', () async {
    final client = _ApiClientStub();
    final repository = FinanceRepository(client: client);

    await repository.create(
      'farm-1',
      FinanceEntryInput(
        type: FinanceEntryType.expense,
        amount: 32,
        date: DateTime(2026, 9, 27),
        category: 'Café',
      ),
    );

    expect(client.lastMutationPath, '/finances/expenses');
    expect(client.lastBody?['farm_id'], 'farm-1');
  });

  test('loads and parses dashboard metrics', () async {
    final client = _ApiClientStub();

    final metrics = await FinanceRepository(
      client: client,
    ).getDashboard('farm-1');

    expect(metrics.farmId, 'farm-1');
    expect(metrics.operatingBalance, 12450);
    expect(metrics.netMarginPercentage, 41.4);
    expect(metrics.balanceChangePercentage, 18.5);
    expect(client.queries.last, ('/finances/dashboard', 'farm-1'));
  });
}

class _ApiClientStub extends ApiClient {
  List<Map<String, dynamic>> incomes = [];
  List<Map<String, dynamic>> expenses = [];
  final List<(String, String?)> queries = [];
  String? lastMutationPath;
  Map<String, dynamic>? lastBody;

  @override
  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    queries.add((path, query?['farm_id']));
    if (path.endsWith('dashboard')) {
      return {
        'farm_id': 'farm-1',
        'period_start': '2026-09-01',
        'period_end': '2026-09-28',
        'gross_income': '30060.00',
        'total_expenses': '17610.00',
        'operating_balance': '12450.00',
        'net_margin_percentage': '41.40',
        'balance_change_percentage': '18.50',
        'net_margin_change_percentage_points': '3.20',
        'projected_annual_income': '120000.00',
        'cash_flow': [
          {'month': '2026-09-01', 'income': '30060.00', 'expenses': '17610.00'},
        ],
      };
    }
    return path.endsWith('incomes') ? incomes : expenses;
  }

  @override
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    lastMutationPath = path;
    lastBody = body;
    return {'id': 'created-1', ...body};
  }
}
