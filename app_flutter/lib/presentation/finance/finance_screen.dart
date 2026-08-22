import 'package:flutter/material.dart';

import '../../shared/section_placeholder.dart';

/// Temporary stand-in until the real Finance screen exists.
class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionPlaceholder(
      icon: Icons.show_chart,
      title: 'Finanzas',
      message: 'Aquí verás el resumen de ingresos y gastos de tu finca.',
    );
  }
}