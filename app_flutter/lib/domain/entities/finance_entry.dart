enum FinanceEntryType { income, expense }

class FinanceEntry {
  const FinanceEntry({
    required this.id,
    required this.farmId,
    required this.type,
    required this.amount,
    required this.date,
    required this.category,
  });

  final String id;
  final String farmId;
  final FinanceEntryType type;
  final double amount;
  final DateTime date;
  final String category;

  factory FinanceEntry.fromIncomeJson(Map<String, dynamic> json) {
    return FinanceEntry(
      id: json['id'] as String,
      farmId: json['farm_id'] as String,
      type: FinanceEntryType.income,
      amount: _readAmount(json['amount']),
      date: DateTime.parse(json['income_date'] as String),
      category: json['category'] as String,
    );
  }

  factory FinanceEntry.fromExpenseJson(Map<String, dynamic> json) {
    return FinanceEntry(
      id: json['id'] as String,
      farmId: json['farm_id'] as String,
      type: FinanceEntryType.expense,
      amount: _readAmount(json['amount']),
      date: DateTime.parse(json['expense_date'] as String),
      category: json['category'] as String,
    );
  }

  static double _readAmount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.parse(value as String);
  }
}

class FinanceEntryInput {
  const FinanceEntryInput({
    required this.type,
    required this.amount,
    required this.date,
    required this.category,
  });

  final FinanceEntryType type;
  final double amount;
  final DateTime date;
  final String category;

  Map<String, dynamic> toJson({String? farmId}) {
    final dateKey = type == FinanceEntryType.income
        ? 'income_date'
        : 'expense_date';
    return {
      'farm_id': ?farmId,
      'amount': amount,
      dateKey: _dateOnly(date),
      'category': category.trim(),
    };
  }

  static String _dateOnly(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
