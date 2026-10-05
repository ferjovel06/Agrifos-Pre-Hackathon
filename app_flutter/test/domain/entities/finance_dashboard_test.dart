import 'package:app_flutter/domain/entities/finance_dashboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses decimal strings and nullable comparisons', () {
    final metrics = FinanceDashboardMetrics.fromJson({
      'farm_id': 'farm-1',
      'period_start': '2026-09-01',
      'period_end': '2026-09-28',
      'gross_income': '30060.00',
      'total_expenses': 17610,
      'operating_balance': '12450.00',
      'net_margin_percentage': null,
      'balance_change_percentage': '18.50',
      'net_margin_change_percentage_points': null,
      'projected_annual_income': '120000.00',
      'cash_flow': [
        {'month': '2026-08-01', 'income': '18000.00', 'expenses': 12000},
      ],
    });

    expect(metrics.grossIncome, 30060);
    expect(metrics.totalExpenses, 17610);
    expect(metrics.netMarginPercentage, isNull);
    expect(metrics.balanceChangePercentage, 18.5);
    expect(metrics.netMarginChangePercentagePoints, isNull);
    expect(metrics.cashFlow.single.month, DateTime(2026, 8));
    expect(metrics.cashFlow.single.income, 18000);
    expect(metrics.cashFlow.single.expenses, 12000);
  });
}
