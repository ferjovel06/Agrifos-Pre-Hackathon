import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Empty-state shown on the Panel General screen when the user has not
/// registered a farm yet. Prompts them to register their first farm before
/// any dashboard data (crops, sensors, finances) can be shown.
class NoFarmState extends StatelessWidget {
  const NoFarmState({super.key, required this.onRegisterTap});

  final VoidCallback onRegisterTap;

  static const _titleColor = Color(0xFF472319);
  static const _brandGreen = Color(0xFF31543B);
  static const _cardBg = Color(0xFFF9F0E9);
  static const _circleBg = Color(0xFFE1DACF);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
        child: Column(
          children: [
            const _HomeIllustration(),
            const SizedBox(height: 28),
            Text(
              'Registra tu finca para empezar',
              textAlign: TextAlign.center,
              style: GoogleFonts.josefinSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _titleColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Agrega tu primera finca y parcelas para comenzar a '
                  'monitorear cultivos, sensores y datos financieros.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            const Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _FeaturePill(icon: Icons.eco_outlined, label: 'Cultivos', color: Color(0xFF6B9B37)),
                _FeaturePill(icon: Icons.sensors, label: 'Sensores IoT', color: Color(0xFF3E6B52)),
                _FeaturePill(icon: Icons.attach_money, label: 'Finanzas', color: Color(0xFFC79A3D)),
                _FeaturePill(icon: Icons.calendar_today_outlined, label: 'Planificación', color: Color(0xFFB05A54)),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _brandGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: onRegisterTap,
                child: const Text(
                  '+  Registrar mi Finca',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeIllustration extends StatelessWidget {
  const _HomeIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: const BoxDecoration(
              color: NoFarmState._circleBg,
              shape: BoxShape.circle,
            ),
          ),
          const Icon(
            Icons.home_outlined,
            size: 56,
            color: NoFarmState._brandGreen,
          ),
          Positioned(
            top: 6,
            right: 6,
            child: _Badge(
              color: const Color(0xFFDCE7B7),
              icon: Icons.eco,
              iconColor: const Color(0xFF6B9B37),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 0,
            child: _Badge(
              color: Colors.white,
              icon: Icons.location_on,
              iconColor: const Color(0xFFC0575C),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.color, required this.icon, required this.iconColor});

  final Color color;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: 16, color: iconColor),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7DFD3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: NoFarmState._titleColor,
            ),
          ),
        ],
      ),
    );
  }
}