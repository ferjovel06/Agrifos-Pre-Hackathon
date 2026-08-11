import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';

/// Temporary stand-in until the real Home screen exists.
class HomePlaceholder extends StatelessWidget {
  const HomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Agrifos')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Sesión iniciada como ${auth.user?.email}'),
            TextButton(
              onPressed: () => context.read<AuthProvider>().signOut(),
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}