import 'dart:async';
import 'package:app_flutter/data/api/alerts_repository.dart';
import 'package:app_flutter/data/api/farm_repository.dart';
import 'package:app_flutter/data/api/weather_repository.dart';
import 'package:app_flutter/domain/entities/app_user.dart';
import 'package:app_flutter/domain/entities/climate_alert.dart';
import 'package:app_flutter/domain/entities/farm.dart';
import 'package:app_flutter/domain/entities/weather_forecast.dart';
import 'package:app_flutter/presentation/auth/auth_provider.dart';
import 'package:app_flutter/presentation/farm/farm_provider.dart';
import 'package:app_flutter/presentation/planification/planification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shows forecast and alert details for the selected day', (
    tester,
  ) async {
    final farms = FarmProvider(farmRepository: _Farms());
    await farms.loadFarms(userId: 'user');
    final alerts = _Alerts()
      ..result = [
        ClimateAlert(
          id: 'rain',
          title: 'Posponer fertilización',
          message: 'Lluvia en 48 horas',
          severity: 'critical',
          date: DateTime.now(),
          riskScore: 1,
        ),
      ];
    await tester.pumpWidget(_app(farms, _LoadedWeather(), alerts));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Icon &&
            widget.icon == Icons.warning_amber_rounded &&
            widget.size == 16,
      ),
      findsOneWidget,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Lluvia en 48 horas'), findsWidgets);
    expect(find.textContaining('18° / 28°C · 12.0 mm'), findsWidgets);
    expect(find.textContaining('Índice de riesgo: 1.00 / 1'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();
    expect(find.text('28°C'), findsOneWidget);
    await tester.tap(find.text('28°C'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.textContaining('18° / 28°C · 12.0 mm'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'calendar navigates, changes view and handles unavailable weather at phone width',
    (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final farms = FarmProvider(farmRepository: _Farms());
      await farms.loadFarms(userId: 'user');
      final alerts = _Alerts();
      await tester.pumpWidget(_app(farms, _Weather(), alerts));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(alerts.evaluated, isFalse);
      expect(find.text('No se pudo actualizar el pronóstico.'), findsOneWidget);
      await tester.tap(find.byTooltip('Período siguiente'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Semana'));
      await tester.pumpAndSettle();
      expect(find.byType(InkWell), findsWidgets);
      await tester.tap(find.text('HOY'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'late alert response from previous farm cannot overwrite current farm',
    (tester) async {
      final farms = FarmProvider(farmRepository: _Farms());
      await farms.loadFarms(userId: 'user');
      final alerts = _Alerts()..pending = Completer<List<ClimateAlert>>();
      await tester.pumpWidget(_app(farms, _Weather(), alerts));
      await tester.pump();
      farms.selectFarm('south');
      await tester.pump();
      await tester.pumpAndSettle();
      alerts.pending!.complete([
        const ClimateAlert(
          id: 'old',
          title: 'OLD FARM ALERT',
          message: 'Old farm',
          severity: 'critical',
        ),
      ]);
      await tester.pumpAndSettle();
      expect(find.textContaining('OLD FARM ALERT'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _app(
  FarmProvider farms,
  WeatherRepository weather,
  AlertsRepository alerts,
) => MultiProvider(
  providers: [
    ChangeNotifierProvider<FarmProvider>.value(value: farms),
    ChangeNotifierProvider<AuthProvider>(create: (_) => _Auth()),
  ],
  child: MaterialApp(
    home: Scaffold(
      body: PlanificationScreen(
        weatherRepository: weather,
        alertsRepository: alerts,
      ),
    ),
  ),
);

class _Auth extends ChangeNotifier implements AuthProvider {
  @override
  AppUser? get user =>
      const AppUser(id: 'user', email: 'user@example.com', role: 'auditor');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Weather extends WeatherRepository {
  @override
  Future<WeatherForecast> getForecast(String farmId, {int days = 3}) async =>
      throw Exception('offline');
}

class _Alerts extends AlertsRepository {
  List<ClimateAlert> result = [];
  bool? evaluated;
  Completer<List<ClimateAlert>>? pending;
  @override
  Future<List<ClimateAlert>> load(
    String farmId, {
    bool evaluate = false,
  }) async {
    evaluated = evaluate;
    if (farmId == 'north' && pending != null) return pending!.future;
    return result;
  }
}

class _LoadedWeather extends WeatherRepository {
  @override
  Future<WeatherForecast> getForecast(String farmId, {int days = 3}) async =>
      WeatherForecast(
        farmId: farmId,
        provider: 'Test',
        current: CurrentWeather(
          observedAt: DateTime.now(),
          temperatureC: 25,
          relativeHumidityPct: 70,
          precipitationMm: 0,
          weatherCode: 61,
          condition: 'Lluvia',
          windSpeedKmh: 5,
        ),
        daily: [
          DailyWeather.fromJson({
            'date': DateTime.now().toIso8601String().split('T').first,
            'temperature_max_c': 28,
            'temperature_min_c': 18,
            'precipitation_mm': 12,
            'condition': 'Lluvia',
            'weather_code': 61,
          }),
        ],
      );
}

class _Farms extends FarmRepository {
  @override
  Future<List<Farm>> getFarms() async => ['north', 'south']
      .map(
        (id) => Farm(
          id: id,
          userId: 'user',
          name: id,
          areaHectares: 10,
          latitude: 12,
          longitude: -86,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      )
      .toList();
}
