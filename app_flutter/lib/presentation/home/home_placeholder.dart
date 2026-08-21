import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import '../sensor/sensor_screen.dart';
import 'widgets/panel_header.dart';

/// Temporary stand-in until the real Home screen exists.
class HomePlaceholder extends StatelessWidget {
  const HomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PanelHeader(
                userName: auth.user?.name ?? auth.user?.email,
                onNotificationsTap: () {},
                onProfileTap: () {},
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Sesión iniciada como ${auth.user?.email}'),
                      TextButton(
                        onPressed: () => context.read<AuthProvider>().signOut(),
                        child: const Text('Cerrar sesión'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SensorScreen()),
                        ),
                        child: const Text('Ver sensor'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}