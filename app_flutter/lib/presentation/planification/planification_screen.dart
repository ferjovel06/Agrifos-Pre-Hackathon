import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/api/alerts_repository.dart';
import '../../data/api/weather_repository.dart';
import '../../domain/entities/climate_alert.dart';
import '../../domain/entities/weather_forecast.dart';
import '../auth/auth_provider.dart';
import '../farm/farm_provider.dart';

const _green = Color(0xFF31543B);
const _brown = Color(0xFF542E22);
const _months = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];
const _weekdays = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];
bool _sameDay(DateTime a, DateTime b) => DateUtils.isSameDay(a, b);
String _dateLabel(DateTime date) =>
    '${date.day} de ${_months[date.month - 1].toLowerCase()}';

class PlanificationScreen extends StatefulWidget {
  const PlanificationScreen({
    super.key,
    this.weatherRepository,
    this.alertsRepository,
  });
  final WeatherRepository? weatherRepository;
  final AlertsRepository? alertsRepository;

  @override
  State<PlanificationScreen> createState() => _PlanificationScreenState();
}

class _PlanificationScreenState extends State<PlanificationScreen> {
  late final _weather = widget.weatherRepository ?? WeatherRepository();
  late final _alertsRepository = widget.alertsRepository ?? AlertsRepository();
  DateTime _selected = DateUtils.dateOnly(DateTime.now());
  bool _week = false;
  String? _farmId;
  int _request = 0;
  bool _loading = false;
  WeatherForecast? _forecast;
  List<ClimateAlert> _alerts = [];
  String? _weatherError;
  String? _alertsError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final farmId = context.watch<FarmProvider>().selectedFarmId;
    if (_farmId != farmId) {
      _farmId = farmId;
      _request++;
      _forecast = null;
      _alerts = [];
      _weatherError = null;
      _alertsError = null;
      _loading = farmId != null;
      if (farmId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _farmId == farmId) _load();
        });
      }
    }
  }

  Future<void> _load() async {
    final farmId = _farmId;
    if (farmId == null) return;
    final request = ++_request;
    final evaluate = context.read<AuthProvider>().user?.role != 'auditor';
    setState(() {
      _loading = true;
      _weatherError = null;
      _alertsError = null;
    });
    await Future.wait([
      () async {
        try {
          final forecast = await _weather.getForecast(farmId, days: 7);
          if (mounted && request == _request) {
            setState(() => _forecast = forecast);
          }
        } catch (_) {
          if (mounted && request == _request) {
            setState(() {
              _forecast = null;
              _weatherError = 'No se pudo actualizar el pronóstico.';
            });
          }
        }
      }(),
      () async {
        try {
          final alerts = await _alertsRepository.load(
            farmId,
            evaluate: evaluate,
          );
          if (mounted && request == _request) setState(() => _alerts = alerts);
        } catch (_) {
          if (mounted && request == _request) {
            setState(() {
              _alerts = [];
              _alertsError = 'No se pudieron actualizar las alertas.';
            });
          }
        }
      }(),
    ]);
    if (mounted && request == _request) setState(() => _loading = false);
  }

  DailyWeather? _weatherOn(DateTime date) {
    for (final day in _forecast?.daily ?? <DailyWeather>[]) {
      if (_sameDay(day.date, date)) return day;
    }
    return null;
  }

  List<ClimateAlert> _alertsOn(DateTime date) => _alerts
      .where((alert) => alert.date != null && _sameDay(alert.date!, date))
      .toList();

  void _move(int direction) => setState(() {
    _selected = _week
        ? _selected.add(Duration(days: 7 * direction))
        : DateTime(_selected.year, _selected.month + direction, 1);
  });

  @override
  Widget build(BuildContext context) {
    final farms = context.watch<FarmProvider>();
    if (farms.status == FarmStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (farms.currentFarm == null) {
      return Center(
        child: Text(
          farms.errorMessage ??
              'Registra una finca desde el Panel para consultar su calendario climático.',
          textAlign: TextAlign.center,
        ),
      );
    }
    final first = _week
        ? _selected.subtract(Duration(days: _selected.weekday - 1))
        : DateTime(_selected.year, _selected.month, 1);
    final start = _week
        ? first
        : first.subtract(Duration(days: first.weekday - 1));
    final daysInMonth = DateTime(_selected.year, _selected.month + 1, 0).day;
    final count = _week
        ? 7
        : ((first.weekday - 1 + daysInMonth) / 7).ceil() * 7;
    final days = List.generate(count, (i) => start.add(Duration(days: i)));
    final selectedWeather = _weatherOn(_selected);
    final selectedAlerts = _alertsOn(_selected);
    final upcoming = [..._alerts]
      ..sort(
        (a, b) =>
            (a.date ?? DateTime(9999)).compareTo(b.date ?? DateTime(9999)),
      );

    return ColoredBox(
      color: const Color(0xFFFAF6F1),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          children: [
            DropdownButtonFormField<String>(
              key: ValueKey(_farmId),
              initialValue: _farmId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Finca activa',
                prefixIcon: Icon(Icons.eco_outlined),
              ),
              items: farms.farms
                  .map(
                    (farm) => DropdownMenuItem(
                      value: farm.id,
                      child: Text(farm.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (id) {
                if (id != null) farms.selectFarm(id);
              },
            ),
            const SizedBox(height: 12),
            _card(
              Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Período anterior',
                        onPressed: () => _move(-1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Text(
                          '${_months[_selected.month - 1]} ${_selected.year}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _brown,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Período siguiente',
                        onPressed: () => _move(1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => setState(
                          () => _selected = DateUtils.dateOnly(DateTime.now()),
                        ),
                        child: const Text('HOY'),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text('Mes'),
                          showCheckmark: false,
                          labelStyle: const TextStyle(fontSize: 12),
                          visualDensity: VisualDensity.compact,
                          selected: !_week,
                          onSelected: (_) => setState(() => _week = false),
                        ),
                      ),
                      ChoiceChip(
                        label: const Text('Semana'),
                        showCheckmark: false,
                        labelStyle: const TextStyle(fontSize: 12),
                        visualDensity: VisualDensity.compact,
                        selected: _week,
                        onSelected: (_) => setState(() => _week = true),
                      ),
                    ],
                  ),
                  if (_loading) const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _summaryBadge(
                          Icons.water_drop_outlined,
                          '${_forecast == null ? "—" : _forecast!.daily.where((d) => d.precipitationMm > 0).length} días con lluvia',
                          const Color(0xFF4C8AC9),
                          const Color(0xFFF2F7FE),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _summaryBadge(
                          Icons.warning_amber_rounded,
                          '${_alertsError != null || _loading ? "—" : _alerts.length} alertas',
                          const Color(0xFFC94C45),
                          const Color(0xFFFFF3F1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _card(
              Column(
                children: [
                  Row(
                    children: _weekdays
                        .map(
                          (day) => Expanded(
                            child: Center(
                              child: Text(
                                day,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: _brown,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  for (var row = 0; row < count ~/ 7; row++)
                    Row(
                      children: days
                          .skip(row * 7)
                          .take(7)
                          .map((date) => Expanded(child: _day(date)))
                          .toList(),
                    ),
                  const SizedBox(height: 12),
                  const Text(
                    'Toca un día para ver detalles. El clima se muestra solo dentro del pronóstico disponible.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            if (_weatherError != null) _error(_weatherError!),
            if (_alertsError != null) _error(_alertsError!),
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _heading(_dateLabel(_selected)),
                  const SizedBox(height: 12),
                  if (selectedWeather != null)
                    _weatherRow(selectedWeather)
                  else
                    Text(
                      _loading
                          ? 'Consultando clima…'
                          : 'Sin pronóstico disponible para esta fecha.',
                    ),
                  const SizedBox(height: 8),
                  if (selectedAlerts.isEmpty)
                    Text(
                      _loading
                          ? 'Consultando alertas…'
                          : _alertsError != null
                          ? 'Alertas no disponibles.'
                          : 'Sin alertas activas para esta fecha.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ...selectedAlerts.map(_alert),
                ],
              ),
            ),
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _heading('Alertas climáticas activas'),
                  if (upcoming.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _loading
                            ? 'Consultando alertas…'
                            : _alertsError != null
                            ? 'Alertas no disponibles.'
                            : 'No hay alertas climáticas activas.',
                      ),
                    ),
                  ...upcoming.map(_alert),
                ],
              ),
            ),
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud_outlined, size: 18, color: _brown),
                      const SizedBox(width: 8),
                      _heading('Pronóstico 7 Días'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_forecast == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _loading
                            ? 'Consultando pronóstico…'
                            : 'Pronóstico no disponible.',
                      ),
                    ),
                  for (final (index, day)
                      in (_forecast?.daily ?? <DailyWeather>[]).indexed) ...[
                    if (index > 0)
                      const Divider(height: 1, color: Color(0xFFF2EEEA)),
                    _forecastRow(day),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _day(DateTime date) {
    final weather = _weatherOn(date);
    final alerts = _alertsOn(date);
    final selected = _sameDay(date, _selected);
    final today = _sameDay(date, DateTime.now());
    return Semantics(
      label:
          '${_dateLabel(date)} ${date.year}${today ? ", hoy" : ""}, ${alerts.length} alertas',
      selected: selected,
      button: true,
      child: InkWell(
        onTap: () => setState(() => _selected = date),
        child: Container(
          height: 82,
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFE8F0E8)
                : alerts.isNotEmpty
                ? const Color(0xFFFFF0F0)
                : Colors.white,
            border: Border.all(
              color: selected ? _green : const Color(0xFFF1ECE7),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: today
                      ? _green
                      : date.month == _selected.month
                      ? _brown
                      : Colors.grey,
                ),
              ),
              if (weather != null)
                Icon(
                  _weatherIcon(weather),
                  size: 17,
                  color: weather.precipitationMm > 0
                      ? Colors.blue
                      : Colors.amber.shade700,
                )
              else
                const SizedBox(height: 17),
              if (alerts.isNotEmpty)
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: Colors.red,
                )
              else
                const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _alert(ClimateAlert alert) => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1EF),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${alert.severity == "critical" ? "Alerta crítica" : "Advertencia"} · ${alert.title}',
          style: const TextStyle(
            color: Color(0xFFB3261E),
            fontWeight: FontWeight.w800,
          ),
        ),
        if (alert.date != null)
          Text(_dateLabel(alert.date!), style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 6),
        Text(alert.message),
        if (alert.riskScore != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Índice de riesgo: ${alert.riskScore!.toStringAsFixed(2)} / 1',
              style: const TextStyle(fontSize: 12),
            ),
          ),
      ],
    ),
  );

  Widget _error(String message) => _card(
    Column(
      children: [
        Text(message),
        TextButton(
          onPressed: _loading ? null : _load,
          child: const Text('Reintentar'),
        ),
      ],
    ),
  );
  Widget _heading(String title) => Text(
    title,
    style: const TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w800,
      color: _brown,
    ),
  );
  Widget _summaryBadge(
    IconData icon,
    String text,
    Color color,
    Color background,
  ) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(text, style: TextStyle(fontSize: 11, color: color)),
        ),
      ],
    ),
  );
  Widget _card(Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
    ),
    child: child,
  );
  Widget _weatherRow(DailyWeather day) => Row(
    children: [
      Icon(
        _weatherIcon(day),
        color: day.precipitationMm > 0 ? Colors.blue : Colors.amber.shade700,
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          '${day.condition ?? "Clima previsto"}\n${day.temperatureMinC == null ? "" : "${day.temperatureMinC!.round()}° / "}${day.temperatureMaxC.round()}°C · ${day.precipitationMm.toStringAsFixed(1)} mm',
        ),
      ),
    ],
  );
  Widget _forecastRow(DailyWeather day) => Semantics(
    label:
        '${_dateLabel(day.date)}, ${day.condition ?? "Clima previsto"}, máxima ${day.temperatureMaxC.round()} grados',
    button: true,
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        setState(() => _selected = day.date);
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (_) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _heading(_dateLabel(day.date)),
                  const SizedBox(height: 18),
                  _weatherRow(day),
                  ..._alertsOn(day.date).map(_alert),
                ],
              ),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 2),
        child: Row(
          children: [
            SizedBox(
              width: 38,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    const [
                      'Lun',
                      'Mar',
                      'Mié',
                      'Jue',
                      'Vie',
                      'Sáb',
                      'Dom',
                    ][day.date.weekday - 1],
                    style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: 1,
                      color: Color(0xFFA99B94),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${day.date.day}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _brown,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              _weatherIcon(day),
              size: 20,
              color: day.precipitationMm > 0
                  ? const Color(0xFF74ACD1)
                  : Colors.amber.shade700,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${day.temperatureMaxC.round()}°C',
                style: const TextStyle(fontSize: 14, color: _brown),
              ),
            ),
            if (_alertsOn(day.date).isNotEmpty)
              const Icon(
                Icons.warning_amber_rounded,
                size: 17,
                color: Color(0xFFD78B39),
              ),
          ],
        ),
      ),
    ),
  );
  IconData _weatherIcon(DailyWeather day) {
    final code = day.weatherCode;
    if (code != null && code >= 95) return Icons.thunderstorm_outlined;
    if (day.precipitationMm > 0) return Icons.water_drop_outlined;
    if (code == null) return Icons.cloud_outlined;
    if (code == 0) return Icons.wb_sunny_outlined;
    return Icons.cloud_outlined;
  }
}
