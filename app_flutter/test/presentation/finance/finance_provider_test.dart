import 'package:app_flutter/data/api/finance_repository.dart';
import 'package:app_flutter/domain/entities/finance_entry.dart';
import 'package:app_flutter/presentation/finance/finance_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final income = FinanceEntry(
    id: 'income-1',
    farmId: 'farm-1',
    type: FinanceEntryType.income,
    amount: 500,
    date: _date,
    category: 'Venta de café',
  );
  final expense = FinanceEntry(
    id: 'expense-1',
    farmId: 'farm-1',
    type: FinanceEntryType.expense,
    amount: 125,
    date: _date,
    category: 'Insumos',
  );

  test('loads entries and calculates finance totals', () async {
    final repository = _FinanceRepositoryStub()..loaded = [income, expense];
    final provider = FinanceProvider(repository: repository);

    await provider.loadForFarm('farm-1');

    expect(provider.status, FinanceStatus.ready);
    expect(provider.totalIncome, 500);
    expect(provider.totalExpenses, 125);
    expect(provider.balance, 375);
  });

  test('create updates the local list', () async {
    final repository = _FinanceRepositoryStub()..created = income;
    final provider = FinanceProvider(repository: repository);
    await provider.loadForFarm('farm-1');

    final result = await provider.save(
      FinanceEntryInput(
        type: FinanceEntryType.income,
        amount: 500,
        date: DateTime(2026, 9, 27),
        category: 'Venta de café',
      ),
    );

    expect(result, isTrue);
    expect(provider.entries, [income]);
  });

  test('delete removes the entry locally', () async {
    final repository = _FinanceRepositoryStub()..loaded = [expense];
    final provider = FinanceProvider(repository: repository);
    await provider.loadForFarm('farm-1');

    expect(await provider.delete(expense), isTrue);
    expect(provider.entries, isEmpty);
    expect(repository.deleted, expense);
  });
}

final _date = DateTime(2026, 9, 27);

class _FinanceRepositoryStub extends FinanceRepository {
  List<FinanceEntry> loaded = [];
  FinanceEntry? created;
  FinanceEntry? deleted;

  @override
  Future<List<FinanceEntry>> listForFarm(String farmId) async => loaded;

  @override
  Future<FinanceEntry> create(String farmId, FinanceEntryInput input) async =>
      created!;

  @override
  Future<void> delete(FinanceEntry entry) async {
    deleted = entry;
  }
}
