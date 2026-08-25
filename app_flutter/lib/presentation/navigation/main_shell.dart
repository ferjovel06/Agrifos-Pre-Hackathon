import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import '../home/home_screen.dart';
import '../sensor/sensor_screen.dart';
import '../planification/planification_screen.dart';
import '../finance/finance_screen.dart';
import '../profile/profile_screen.dart';
import 'widgets/app_header.dart';
import 'widgets/app_bottom_nav.dart';

/// Root shell shown after authentication.
///
/// Owns the bottom navigation and keeps every section alive via
/// [IndexedStack] so switching tabs preserves each screen's state
/// (scroll position, form input, etc.)
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _items = [
    AppNavItem(
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      label: 'Panel',
    ),
    AppNavItem(
      icon: Icons.monitor_heart_outlined,
      activeIcon: Icons.monitor_heart,
      label: 'Diagnóstico',
    ),
    AppNavItem(
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month,
      label: 'Planificación',
    ),
    AppNavItem(
      icon: Icons.show_chart,
      activeIcon: Icons.show_chart,
      label: 'Finanzas',
    ),
    AppNavItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Perfil',
    ),
  ];

  // Kept in the same order as `_items` so index i maps to screen i.
  static const _screens = [
    HomeScreen(),
    SensorScreen(),
    PlanificationScreen(),
    FinanceScreen(),
    ProfileScreen(),
  ];

  static const _headerTitles = [
    'Panel General',
    'Diagnóstico Agronómico',
    'Planificación',
    'Finanzas',
    'Configuración y Equipo',
  ];

  static const _headerSubtitles = [
    'Resumen operativo',
    'Análisis de suelo',
    'Labores y ciclos',
    'Ingresos y gastos',
    'Administración de cuenta',
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppHeader(
                title: _headerTitles[_currentIndex],
                subtitle: _headerSubtitles[_currentIndex],
                accentColor: _currentIndex == 1
                    ? const Color(0xFF4D8DFF)
                    : _currentIndex == 4
                    ? const Color(0xFF5A2D22)
                    : const Color(0xFF31543B),
                userName: user?.name ?? user?.email,
                onNotificationsTap: () {},
                onProfileTap: () => setState(() => _currentIndex = 4),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: IndexedStack(index: _currentIndex, children: _screens),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        items: _items,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
