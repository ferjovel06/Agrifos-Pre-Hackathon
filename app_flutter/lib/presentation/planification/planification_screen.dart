import 'package:flutter/material.dart';

import '../../shared/section_placeholder.dart';

/// Temporary stand-in until the real Planification screen exists.
class PlanificationScreen extends StatelessWidget {
  const PlanificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionPlaceholder(
      icon: Icons.calendar_month_outlined,
      title: 'Planificación',
      message: 'Aquí podrás organizar tus labores y ciclos de cultivo.',
    );
  }
}