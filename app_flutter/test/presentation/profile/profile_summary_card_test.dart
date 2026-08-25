import 'package:app_flutter/domain/entities/farm.dart';
import 'package:app_flutter/presentation/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows account and real agricultural summary', (tester) async {
    var shared = false;
    var edited = false;
    final farm = Farm(
      id: 'farm-1',
      userId: 'user-1',
      name: 'Finca El Edén',
      areaHectares: 12.5,
      latitude: 12.1,
      longitude: -86.3,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProfileSummaryCard(
              name: 'Roberto Suárez',
              role: 'Productor',
              farm: farm,
              parcelCount: 3,
              cropCount: 2,
              onShareProfile: () => shared = true,
              onEditProfile: () => edited = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Roberto Suárez'), findsOneWidget);
    expect(find.text('Productor · Finca El Edén'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('12.5'), findsOneWidget);

    await tester.tap(find.text('Compartir perfil'));
    await tester.tap(find.text('Editar perfil'));
    expect(shared, isTrue);
    expect(edited, isTrue);
  });

  testWidgets('uses zero values when there is no farm', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileSummaryCard(
            name: 'Ana López',
            role: 'Productor',
            farm: null,
            parcelCount: 0,
            cropCount: 0,
          ),
        ),
      ),
    );

    expect(find.text('Productor'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(3));
  });
}
