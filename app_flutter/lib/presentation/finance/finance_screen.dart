import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/api/finance_repository.dart';
import '../../domain/entities/finance_dashboard.dart';
import '../../domain/entities/finance_entry.dart';
import '../farm/farm_provider.dart';
import 'finance_provider.dart';

enum _EntryFilter { all, income, expense }

const _currencySymbol = r'C$';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key, this.repository});

  final FinanceRepository? repository;

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  late final FinanceProvider _provider;
  _EntryFilter _filter = _EntryFilter.all;

  static const green = Color(0xFF31543B);
  static const red = Color(0xFFC75B4B);
  static const brown = Color(0xFF472319);
  static const background = Color(0xFFF7EEE8);

  @override
  void initState() {
    super.initState();
    _provider = FinanceProvider(repository: widget.repository);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final selectedFarmId = context.watch<FarmProvider>().selectedFarmId;
    if (_provider.farmId != selectedFarmId) {
      unawaited(_provider.loadForFarm(selectedFarmId));
    }
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _provider,
      builder: (context, _) {
        if (_provider.farmId == null) return const _NoFarmState();
        if (_provider.status == FinanceStatus.loading &&
            _provider.entries.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_provider.status == FinanceStatus.error &&
            _provider.entries.isEmpty) {
          return _ErrorState(
            message: _provider.errorMessage!,
            onRetry: () => _provider.loadForFarm(_provider.farmId, force: true),
          );
        }

        final visibleEntries = _provider.entries.where((entry) {
          return switch (_filter) {
            _EntryFilter.all => true,
            _EntryFilter.income => entry.type == FinanceEntryType.income,
            _EntryFilter.expense => entry.type == FinanceEntryType.expense,
          };
        }).toList();

        return ColoredBox(
          color: background,
          child: RefreshIndicator(
            onRefresh: () =>
                _provider.loadForFarm(_provider.farmId, force: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 6, 0, 28),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: _MetricsGrid(metrics: _provider.dashboard!),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: _CashFlowCard(points: _provider.dashboard!.cashFlow),
                ),
                const SizedBox(height: 16),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 22,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.description_outlined,
                            color: brown,
                            size: 17,
                          ),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'Registro de Operaciones',
                              style: TextStyle(
                                color: brown,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: _provider.isSaving
                                ? null
                                : _chooseEntryType,
                            style: FilledButton.styleFrom(
                              backgroundColor: green,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              minimumSize: const Size(0, 0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.add, size: 15),
                            label: const Text(
                              'Nuevo\nRegistro',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 10, height: 1.05),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _FilterControl(
                          selected: _filter,
                          onChanged: (filter) {
                            setState(() => _filter = filter);
                          },
                        ),
                      ),
                      if (_provider.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        _InlineError(message: _provider.errorMessage!),
                      ],
                      const SizedBox(height: 16),
                      const _OperationsHeader(),
                      const Divider(height: 15, color: Color(0xFFEDE7E3)),
                      if (visibleEntries.isEmpty)
                        _EmptyState(filter: _filter, onAdd: _chooseEntryType)
                      else
                        ...visibleEntries.map(
                          (entry) => _EntryTile(
                            entry: entry,
                            onEdit: () =>
                                _openForm(entry.type, existing: entry),
                            onDelete: () => _confirmDelete(entry),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _chooseEntryType() async {
    final type = await showModalBottomSheet<FinanceEntryType>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Registrar movimiento',
                style: TextStyle(
                  color: brown,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _TypeOption(
                icon: Icons.south_west,
                color: green,
                title: 'Ingreso',
                subtitle: 'Dinero recibido por la finca',
                onTap: () => Navigator.pop(context, FinanceEntryType.income),
              ),
              const SizedBox(height: 8),
              _TypeOption(
                icon: Icons.north_east,
                color: red,
                title: 'Egreso',
                subtitle: 'Compra, servicio u otro gasto',
                onTap: () => Navigator.pop(context, FinanceEntryType.expense),
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted && type != null) await _openForm(type);
  }

  Future<void> _openForm(
    FinanceEntryType type, {
    FinanceEntry? existing,
  }) async {
    final input = await showModalBottomSheet<FinanceEntryInput>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _FinanceEntryForm(type: type, existing: existing),
    );
    if (!mounted || input == null) return;
    final saved = await _provider.save(input, existing: existing);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Movimiento guardado correctamente.'
              : _provider.errorMessage ?? 'No se pudo guardar el movimiento.',
        ),
      ),
    );
  }

  Future<void> _confirmDelete(FinanceEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar movimiento'),
        content: const Text(
          'Esta acción eliminará el movimiento de forma permanente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final deleted = await _provider.delete(entry);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted
              ? 'Movimiento eliminado.'
              : _provider.errorMessage ?? 'No se pudo eliminar el movimiento.',
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.metrics});

  final FinanceDashboardMetrics metrics;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const spacing = 12.0;
      final columns = constraints.maxWidth >= 280 ? 2 : 1;
      final cardWidth =
          (constraints.maxWidth - spacing * (columns - 1)) / columns;
      final previousMonth = _monthName(
        metrics.periodStart.subtract(const Duration(days: 1)).month,
      );
      final balanceColor = metrics.operatingBalance < 0
          ? _FinanceScreenState.red
          : _FinanceScreenState.green;

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          _MetricCard(
            width: cardWidth,
            title: 'BALANCE NETO\nOPERATIVO',
            value: _signedMoney(metrics.operatingBalance),
            valueColor: balanceColor,
            icon: Icons.trending_up_rounded,
            detail: metrics.balanceChangePercentage == null
                ? 'Sin comparación mensual'
                : '${_signedPercentage(metrics.balanceChangePercentage!)} mensual',
            detailAsBadge: metrics.balanceChangePercentage != null,
          ),
          _MetricCard(
            width: cardWidth,
            title: 'TOTAL INGRESOS\nBRUTOS',
            value: _money(metrics.grossIncome),
            valueColor: const Color(0xFF4386F4),
            icon: Icons.attach_money_rounded,
            detail:
                'Proyección anual: ${_compactMoney(metrics.projectedAnnualIncome)}',
          ),
          _MetricCard(
            width: cardWidth,
            title: 'TOTAL EGRESOS',
            value: _money(metrics.totalExpenses),
            valueColor: const Color(0xFFE52D2D),
            icon: Icons.bar_chart_rounded,
            detail: 'Egresos del mes actual',
          ),
          _MetricCard(
            width: cardWidth,
            title: 'MARGEN NETO',
            value: metrics.netMarginPercentage == null
                ? '—'
                : '${_decimal(metrics.netMarginPercentage!)}%',
            valueColor: const Color(0xFF8B5CF6),
            icon: Icons.percent_rounded,
            detail: metrics.netMarginChangePercentagePoints == null
                ? 'Sin comparación disponible'
                : '${_signedDecimal(metrics.netMarginChangePercentagePoints!)} pp vs $previousMonth',
            detailAsBadge: metrics.netMarginChangePercentagePoints != null,
          ),
        ],
      );
    },
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.title,
    required this.value,
    required this.valueColor,
    required this.icon,
    required this.detail,
    this.detailAsBadge = false,
  });

  final double width;
  final String title;
  final String value;
  final Color valueColor;
  final IconData icon;
  final String detail;
  final bool detailAsBadge;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: 136,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(25),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D000000),
          blurRadius: 18,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          right: -5,
          bottom: -10,
          child: IgnorePointer(
            child: Icon(
              icon,
              size: 66,
              color: valueColor.withValues(alpha: 0.055),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFB3A5A0),
                  fontSize: 11,
                  height: 1.45,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 24,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
              ),
              const Spacer(),
              if (detailAsBadge)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F3F0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _FinanceScreenState.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              else
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFB4A7A2),
                    fontSize: 10,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CashFlowCard extends StatelessWidget {
  const _CashFlowCard({required this.points});

  final List<FinanceCashFlowPoint> points;

  static const incomeColor = Color(0xFF4386F4);
  static const expenseColor = Color(0xFFE52D2D);

  @override
  Widget build(BuildContext context) {
    final highestValue = points.fold<double>(
      0,
      (highest, point) =>
          math.max(highest, math.max(point.income, point.expenses)),
    );
    final hasData = highestValue > 0;
    final maxY = _niceAxisMaximum(highestValue);
    final interval = maxY / 4;

    return Semantics(
      container: true,
      label: 'Flujo de caja de los últimos ${points.length} meses',
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 17, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 18,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  color: _FinanceScreenState.brown,
                  size: 19,
                ),
                SizedBox(width: 7),
                Text(
                  'Flujo de Caja',
                  style: TextStyle(
                    color: _FinanceScreenState.brown,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Últimos ${points.length} meses · Ingresos vs Gastos',
              style: const TextStyle(
                color: Color(0xFFB4A7A2),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 13),
            const Row(
              children: [
                _ChartLegend(color: incomeColor, label: 'Ingresos'),
                SizedBox(width: 20),
                _ChartLegend(color: expenseColor, label: 'Gastos'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 190,
              child: hasData
                  ? LineChart(
                      _chartData(maxY: maxY, interval: interval),
                      duration: const Duration(milliseconds: 350),
                    )
                  : const _EmptyCashFlow(),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _chartData({required double maxY, required double interval}) {
    final lastIndex = math.max(0, points.length - 1).toDouble();
    return LineChartData(
      minX: 0,
      maxX: lastIndex,
      minY: 0,
      maxY: maxY,
      clipData: const FlClipData(
        top: true,
        bottom: true,
        left: false,
        right: false,
      ),
      gridData: FlGridData(
        drawVerticalLine: false,
        horizontalInterval: interval,
        getDrawingHorizontalLine: (_) => const FlLine(
          color: Color(0xFFEDE7E3),
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            interval: interval,
            getTitlesWidget: (value, meta) => SideTitleWidget(
              meta: meta,
              child: Text(
                _compactAxisMoney(value),
                style: const TextStyle(
                  color: Color(0xFFB6AAA5),
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 27,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.round();
              if (index < 0 || index >= points.length || value != index) {
                return const SizedBox.shrink();
              }
              return SideTitleWidget(
                meta: meta,
                space: 8,
                child: Text(
                  _shortMonth(points[index].month.month),
                  style: const TextStyle(
                    color: Color(0xFF9E918C),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      extraLinesData: ExtraLinesData(
        verticalLines: [
          VerticalLine(
            x: lastIndex,
            color: const Color(0xFF9FA9A2),
            strokeWidth: 1,
            dashArray: [4, 3],
            label: VerticalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              padding: const EdgeInsets.only(bottom: 3),
              style: const TextStyle(
                color: _FinanceScreenState.green,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
              labelResolver: (_) => 'HOY',
            ),
          ),
        ],
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => _FinanceScreenState.brown,
          getTooltipItems: (spots) => spots.map((spot) {
            final income = spot.barIndex == 0;
            return LineTooltipItem(
              '${income ? 'Ingresos' : 'Gastos'}\n${_money(spot.y)}',
              const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            );
          }).toList(),
        ),
      ),
      lineBarsData: [
        _lineData(
          points.map((point) => point.income).toList(growable: false),
          incomeColor,
        ),
        _lineData(
          points.map((point) => point.expenses).toList(growable: false),
          expenseColor,
        ),
      ],
    );
  }

  LineChartBarData _lineData(List<double> values, Color color) {
    return LineChartBarData(
      spots: [
        for (var index = 0; index < values.length; index++)
          FlSpot(index.toDouble(), values[index]),
      ],
      isCurved: false,
      color: color,
      barWidth: 2.5,
      dotData: FlDotData(
        show: true,
        getDotPainter: (_, _, _, _) => FlDotCirclePainter(
          radius: 3,
          color: color,
          strokeWidth: 1.5,
          strokeColor: Colors.white,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.11),
            color.withValues(alpha: 0.015),
          ],
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 25, height: 2.5, color: color),
      const SizedBox(width: 7),
      Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _EmptyCashFlow extends StatelessWidget {
  const _EmptyCashFlow();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.show_chart_rounded, color: Color(0xFFC9BFBB), size: 34),
        SizedBox(height: 8),
        Text(
          'Registra movimientos para ver el flujo de caja.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF9E918C), fontSize: 11),
        ),
      ],
    ),
  );
}

class _FilterControl extends StatelessWidget {
  const _FilterControl({required this.selected, required this.onChanged});

  final _EntryFilter selected;
  final ValueChanged<_EntryFilter> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    width: 240,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F1EF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        _FilterButton(
          label: 'Todos',
          selected: selected == _EntryFilter.all,
          onTap: () => onChanged(_EntryFilter.all),
        ),
        _FilterButton(
          label: 'Ingresos',
          selected: selected == _EntryFilter.income,
          onTap: () => onChanged(_EntryFilter.income),
        ),
        _FilterButton(
          label: 'Gastos',
          selected: selected == _EntryFilter.expense,
          onTap: () => onChanged(_EntryFilter.expense),
        ),
      ],
    ),
  );
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 7,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected
                ? _FinanceScreenState.brown
                : const Color(0xFFB6AAA5),
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}

class _OperationsHeader extends StatelessWidget {
  const _OperationsHeader();

  static const style = TextStyle(
    color: Color(0xFFC4B8B3),
    fontSize: 9,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.1,
  );

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      SizedBox(width: 57, child: Text('FECHA', style: style)),
      SizedBox(width: 36),
      Expanded(child: Text('CONCEPTO', style: style)),
      SizedBox(
        width: 82,
        child: Text('MONTO', textAlign: TextAlign.right, style: style),
      ),
    ],
  );
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final FinanceEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final income = entry.type == FinanceEntryType.income;
    final color = income ? _FinanceScreenState.green : _FinanceScreenState.red;
    return InkWell(
      onTap: onEdit,
      onLongPress: onDelete,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFF0EBE8), width: 1),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 57,
              child: Text(
                _shortDate(entry.date),
                style: const TextStyle(
                  color: Color(0xFFB3A6A1),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(
              width: 36,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.10),
                  ),
                  child: Icon(
                    income ? Icons.north_east : Icons.south_west,
                    color: color,
                    size: 13,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _FinanceScreenState.brown,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    income ? 'Operación de ingreso' : 'Operación de gasto',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFB9ADA8),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 82,
              child: Text(
                '${income ? '+' : '-'}${_money(entry.amount)}',
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinanceEntryForm extends StatefulWidget {
  const _FinanceEntryForm({required this.type, this.existing});

  final FinanceEntryType type;
  final FinanceEntry? existing;

  @override
  State<_FinanceEntryForm> createState() => _FinanceEntryFormState();
}

class _FinanceEntryFormState extends State<_FinanceEntryForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _categoryController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _amountController = TextEditingController(
      text: existing == null ? '' : existing.amount.toStringAsFixed(2),
    );
    _categoryController = TextEditingController(text: existing?.category ?? '');
    _selectedDate = existing?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.type == FinanceEntryType.income;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${widget.existing == null ? 'Registrar' : 'Editar'} '
                '${isIncome ? 'ingreso' : 'egreso'}',
                style: const TextStyle(
                  color: _FinanceScreenState.brown,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixText: '$_currencySymbol ',
                ),
                validator: (value) {
                  final parsed = double.tryParse(
                    (value ?? '').replaceAll(',', '.'),
                  );
                  if (parsed == null || parsed <= 0) {
                    return 'Ingresa un monto mayor que cero.';
                  }
                  if (parsed > 9999999999.99) {
                    return 'El monto es demasiado alto.';
                  }
                  final decimals = (value ?? '').split(RegExp(r'[.,]'));
                  if (decimals.length > 1 && decimals.last.length > 2) {
                    return 'Usa como máximo dos decimales.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 50,
                decoration: InputDecoration(
                  labelText: 'Categoría',
                  hintText: isIncome
                      ? 'Ej. Venta de café, cosecha o anticipo'
                      : 'Ej. Insumos, transporte o mano de obra',
                ),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Ingresa una categoría.'
                    : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha',
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(_formatDate(_selectedDate)),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _FinanceScreenState.green,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: const Text('Guardar movimiento'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (selected != null) setState(() => _selectedDate = selected);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      FinanceEntryInput(
        type: widget.type,
        amount: double.parse(_amountController.text.replaceAll(',', '.')),
        date: _selectedDate,
        category: _categoryController.text.trim(),
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    tileColor: color.withValues(alpha: 0.08),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    leading: CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.15),
      foregroundColor: color,
      child: Icon(icon),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter, required this.onAdd});

  final _EntryFilter filter;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: const Color(0xFFF9F7F4),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.receipt_long_outlined,
          size: 42,
          color: Color(0xFFA99B96),
        ),
        const SizedBox(height: 10),
        Text(
          filter == _EntryFilter.all
              ? 'Aún no hay movimientos'
              : 'No hay movimientos en este filtro',
          style: const TextStyle(
            color: _FinanceScreenState.brown,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Registra ingresos y egresos para conocer el balance de la finca.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF817570)),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Registrar movimiento'),
        ),
      ],
    ),
  );
}

class _NoFarmState extends StatelessWidget {
  const _NoFarmState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'Selecciona o registra una finca para administrar sus finanzas.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF817570), fontSize: 16),
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off_outlined, size: 42),
        const SizedBox(height: 10),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      ],
    ),
  );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFECE8),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: _FinanceScreenState.red),
        const SizedBox(width: 8),
        Expanded(child: Text(message)),
      ],
    ),
  );
}

String _money(double value) {
  final absolute = value.abs();
  final raw = absolute == absolute.roundToDouble()
      ? absolute.toStringAsFixed(0)
      : absolute.toStringAsFixed(2);
  final parts = raw.split('.');
  final grouped = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  final decimals = parts.length == 2 ? '.${parts.last}' : '';
  return '$_currencySymbol $grouped$decimals';
}

String _signedMoney(double value) {
  final sign = value < 0 ? '-' : '';
  return '$sign${_money(value)}';
}

String _compactMoney(double value) {
  final absolute = value.abs();
  if (absolute < 1000) return _signedMoney(value);
  final divisor = absolute >= 1000000 ? 1000000 : 1000;
  final suffix = absolute >= 1000000 ? 'M' : ' mil';
  final compact = _decimal(absolute / divisor);
  return '${value < 0 ? '-' : ''}$_currencySymbol $compact$suffix';
}

String _signedPercentage(double value) => '${_signedDecimal(value)}%';

String _signedDecimal(double value) {
  if (value == 0) return '0';
  return '${value > 0 ? '+' : '-'}${_decimal(value.abs())}';
}

String _decimal(double value) {
  final fixed = value.toStringAsFixed(1);
  return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
}

String _monthName(int month) {
  const months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  return months[month - 1];
}

String _shortMonth(int month) {
  const months = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];
  return months[month - 1];
}

double _niceAxisMaximum(double value) {
  if (value <= 0) return 1000;
  const gridSections = 4;
  final roughInterval = value * 1.1 / gridSections;
  final magnitude = math.pow(
    10,
    (math.log(roughInterval) / math.ln10).floor(),
  );
  final interval = (roughInterval / magnitude).ceil() * magnitude;
  return (interval * gridSections).toDouble();
}

String _compactAxisMoney(double value) {
  if (value == 0) return r'C$0';
  if (value >= 1000000) return 'C\$${_decimal(value / 1000000)}M';
  if (value >= 1000) return 'C\$${_decimal(value / 1000)}k';
  return 'C\$${_decimal(value)}';
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

String _shortDate(DateTime value) {
  const months = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];
  final day = value.day.toString().padLeft(2, '0');
  return '$day ${months[value.month - 1]}';
}
