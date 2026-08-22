import 'package:flutter/material.dart';

import '../../shared/section_placeholder.dart';

/// Temporary stand-in until the real Profile screen exists.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionPlaceholder(
      icon: Icons.people_outline,
      title: 'Perfil',
      message: 'Aquí podrás administrar tu cuenta y preferencias.',
    );
  }
}