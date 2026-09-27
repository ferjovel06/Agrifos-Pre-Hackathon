import 'package:app_flutter/data/api/finance_repository.dart';
import 'package:app_flutter/domain/entities/finance_entry.dart';
import 'package:app_flutter/presentation/farm/farm_provider.dart';
import 'package:app_flutter/presentation/finance/finance_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
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

    expect(find.text('Registro de Operaciones'), findsOneWidget);
    expect(find.text('Ingresos'), findsOneWidget);
    expect(find.text('Gastos'), findsOneWidget);
    expect(find.text('FECHA'), findsOneWidget);
    expect(find.text('CONCEPTO'), findsOneWidget);
    expect(find.text('MONTO'), findsOneWidget);
    expect(find.text(r'+C$ 500'), findsOneWidget);
    expect(find.text('Insumos'), findsOneWidget);

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
