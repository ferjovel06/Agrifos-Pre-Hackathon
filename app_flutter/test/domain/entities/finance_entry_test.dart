import 'package:app_flutter/domain/entities/finance_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses income amounts returned as strings', () {
    final entry = FinanceEntry.fromIncomeJson({
      'id': 'income-1',
      'farm_id': 'farm-1',
      'category': 'Venta de café',
      'amount': '1250.50',
      'income_date': '2026-09-27',
    });

    expect(entry.type, FinanceEntryType.income);
    expect(entry.amount, 1250.5);
    expect(entry.category, 'Venta de café');
    expect(entry.date, DateTime(2026, 9, 27));
  });

  test('serializes expense input with API field names', () {
    final input = FinanceEntryInput(
      type: FinanceEntryType.expense,
      amount: 75.25,
      date: DateTime(2026, 2, 3),
      category: ' Transporte ',
    );

    expect(input.toJson(farmId: 'farm-1'), {
      'farm_id': 'farm-1',
      'amount': 75.25,
      'expense_date': '2026-02-03',
      'category': 'Transporte',
    });
  });
}
