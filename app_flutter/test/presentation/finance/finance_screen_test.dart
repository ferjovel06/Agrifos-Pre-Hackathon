import 'package:app_flutter/data/api/finance_repository.dart';
import 'package:app_flutter/domain/entities/finance_dashboard.dart';
import 'package:app_flutter/domain/entities/finance_entry.dart';
import 'package:app_flutter/presentation/farm/farm_provider.dart';
import 'package:app_flutter/presentation/finance/finance_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('keeps the dashboard in two columns at phone width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider<FarmProvider>.value(
        value: _FarmProviderStub(),
        child: MaterialApp(
          home: Scaffold(
            body: FinanceScreen(repository: _FinanceRepositoryStub()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final balancePosition = tester.getTopLeft(
      find.text('BALANCE NETO\nOPERATIVO'),
    );
    final incomePosition = tester.getTopLeft(
      find.text('TOTAL INGRESOS\nBRUTOS'),
    );
    final expensePosition = tester.getTopLeft(find.text('TOTAL EGRESOS'));
    final chartPosition = tester.getTopLeft(find.text('Flujo de Caja'));
    final operationsPosition = tester.getTopLeft(
      find.text('Registro de Operaciones'),
    );

    expect(incomePosition.dy, closeTo(balancePosition.dy, 0.1));
    expect(incomePosition.dx, greaterThan(balancePosition.dx));
    expect(expensePosition.dy, greaterThan(balancePosition.dy));
    expect(chartPosition.dy, greaterThan(expensePosition.dy));
    expect(operationsPosition.dy, greaterThan(chartPosition.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('matches the operations register and opens the income form', (
    tester,
  ) async {
    final repository = _FinanceRepositoryStub();

    await tester.pumpWidget(
      ChangeNotifierProvider<FarmProvider>.value(
        value: _FarmProviderStub(),
        child: MaterialApp(
          home: Scaffold(body: FinanceScreen(repository: repository)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BALANCE NETO\nOPERATIVO'), findsOneWidget);
    expect(find.text(r'C$ 12,450'), findsOneWidget);
    expect(find.text('+18.5% mensual'), findsOneWidget);
    expect(find.text('41.4%'), findsOneWidget);
    expect(find.text('+3.2 pp vs agosto'), findsOneWidget);
    expect(find.text(r'Proyección anual: C$ 120 mil'), findsOneWidget);
    expect(find.text('Flujo de Caja'), findsOneWidget);
    expect(find.text('Últimos 6 meses · Ingresos vs Gastos'), findsOneWidget);
    expect(find.text('Ingresos'), findsWidgets);
    expect(find.text('Gastos'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Registro de Operaciones'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Registro de Operaciones'), findsOneWidget);
    expect(find.text('FECHA'), findsOneWidget);
    expect(find.text('CONCEPTO'), findsOneWidget);
    expect(find.text('MONTO'), findsOneWidget);
    expect(find.text(r'+C$ 500'), findsOneWidget);
    expect(find.text('Insumos'), findsOneWidget);

    await tester.ensureVisible(find.text('Nuevo\nRegistro'));
    expect(find.text('Ingresos'), findsWidgets);
    expect(find.text('Gastos'), findsWidgets);
    await tester.tap(find.text('Nuevo\nRegistro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ingreso').last);
    await tester.pumpAndSettle();

    expect(find.text('Registrar ingreso'), findsOneWidget);
    expect(find.text('Monto'), findsOneWidget);
    expect(find.text('Guardar movimiento'), findsOneWidget);
  });
}

class _FarmProviderStub extends FarmProvider {
  @override
  String? get selectedFarmId => 'farm-1';
}

class _FinanceRepositoryStub extends FinanceRepository {
  @override
  Future<FinanceDashboardMetrics> getDashboard(String farmId) async =>
      FinanceDashboardMetrics(
        farmId: farmId,
        periodStart: DateTime(2026, 9),
        periodEnd: DateTime(2026, 9, 28),
        grossIncome: 30060,
        totalExpenses: 17610,
        operatingBalance: 12450,
        netMarginPercentage: 41.4,
        balanceChangePercentage: 18.5,
        netMarginChangePercentagePoints: 3.2,
        projectedAnnualIncome: 120000,
        cashFlow: _cashFlow,
      );

  @override
  Future<List<FinanceEntry>> listForFarm(String farmId) async => [
    FinanceEntry(
      id: 'income-1',
      farmId: farmId,
      type: FinanceEntryType.income,
      amount: 500,
      date: DateTime(2026, 9, 27),
      category: 'Venta de café',
    ),
    FinanceEntry(
      id: 'expense-1',
      farmId: farmId,
      type: FinanceEntryType.expense,
      amount: 125,
      date: DateTime(2026, 9, 26),
      category: 'Insumos',
    ),
  ];
}

final _cashFlow = [
  FinanceCashFlowPoint(
    month: DateTime(2026, 4),
    income: 18000,
    expenses: 14000,
  ),
  FinanceCashFlowPoint(
    month: DateTime(2026, 5),
    income: 22000,
    expenses: 15000,
  ),
  FinanceCashFlowPoint(
    month: DateTime(2026, 6),
    income: 17000,
    expenses: 13000,
  ),
  FinanceCashFlowPoint(
    month: DateTime(2026, 7),
    income: 28000,
    expenses: 15500,
  ),
  FinanceCashFlowPoint(month: DateTime(2026, 8), income: 9000, expenses: 12000),
  FinanceCashFlowPoint(month: DateTime(2026, 9), income: 15000, expenses: 8000),
];
