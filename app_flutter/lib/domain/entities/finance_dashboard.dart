class FinanceDashboardMetrics {
  const FinanceDashboardMetrics({
    required this.farmId,
    required this.periodStart,
    required this.periodEnd,
    required this.grossIncome,
    required this.totalExpenses,
    required this.operatingBalance,
    required this.netMarginPercentage,
    required this.balanceChangePercentage,
    required this.netMarginChangePercentagePoints,
    required this.projectedAnnualIncome,
    required this.cashFlow,
  });

  final String farmId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double grossIncome;
  final double totalExpenses;
  final double operatingBalance;
  final double? netMarginPercentage;
  final double? balanceChangePercentage;
  final double? netMarginChangePercentagePoints;
  final double projectedAnnualIncome;
  final List<FinanceCashFlowPoint> cashFlow;

  factory FinanceDashboardMetrics.fromJson(Map<String, dynamic> json) {
    return FinanceDashboardMetrics(
      farmId: json['farm_id'] as String,
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      grossIncome: _readNumber(json['gross_income']),
      totalExpenses: _readNumber(json['total_expenses']),
      operatingBalance: _readNumber(json['operating_balance']),
      netMarginPercentage: _readNullableNumber(json['net_margin_percentage']),
      balanceChangePercentage: _readNullableNumber(
        json['balance_change_percentage'],
      ),
      netMarginChangePercentagePoints: _readNullableNumber(
        json['net_margin_change_percentage_points'],
      ),
      projectedAnnualIncome: _readNumber(json['projected_annual_income']),
      cashFlow: (json['cash_flow'] as List<dynamic>)
          .map(
            (point) =>
                FinanceCashFlowPoint.fromJson(point as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  static double _readNumber(dynamic value) {
    if (value is num) return value.toDouble();
    return double.parse(value as String);
  }

  static double? _readNullableNumber(dynamic value) {
    return value == null ? null : _readNumber(value);
  }
}

class FinanceCashFlowPoint {
  const FinanceCashFlowPoint({
    required this.month,
    required this.income,
    required this.expenses,
  });

  final DateTime month;
  final double income;
  final double expenses;

  factory FinanceCashFlowPoint.fromJson(Map<String, dynamic> json) {
    return FinanceCashFlowPoint(
      month: DateTime.parse(json['month'] as String),
      income: FinanceDashboardMetrics._readNumber(json['income']),
      expenses: FinanceDashboardMetrics._readNumber(json['expenses']),
    );
  }
}
