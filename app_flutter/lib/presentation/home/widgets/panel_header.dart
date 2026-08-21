import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

/// Header shown at the top of the Panel General screen.
class PanelHeader extends StatelessWidget {
  const PanelHeader({
    super.key,
    this.userName,
    this.avatarUrl,
    this.onNotificationsTap,
    this.onProfileTap,
    this.date,
  });

  /// Name used to build the avatar fallback initial.
  final String? userName;

  /// Optional avatar image URL. Falls back to an icon when null.
  final String? avatarUrl;

  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;

  /// Date shown in the top-right badge. Defaults to now.
  final DateTime? date;

  static const _brandGreen = Color(0xFF2E4A2E);
  static const _logoColor = Color(0xFF31543B);
  static const _titleColor = Color(0xFF472319);

  static const _monthAbbreviations = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];

  @override
  Widget build(BuildContext context) {
    final resolvedDate = date ?? DateTime.now();
    final monthLabel =
        '${_monthAbbreviations[resolvedDate.month - 1]} ${resolvedDate.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _Wordmark(color: _logoColor),
            Row(
              children: [
                _CircleIconButton(
                  icon: Icons.notifications_none_rounded,
                  onTap: onNotificationsTap,
                ),
                const SizedBox(width: 10),
                _Avatar(
                  userName: userName,
                  avatarUrl: avatarUrl,
                  onTap: onProfileTap,
                  color: _brandGreen,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Panel General',
                    style: GoogleFonts.josefinSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: _titleColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'RESUMEN OPERATIVO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _DateBadge(label: monthLabel),
          ],
        ),
      ],
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SvgPicture.asset(
            'assets/images/agrifos_isotype.svg',
            height: 18,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
        const SizedBox(width: 8),
        SvgPicture.asset(
          'assets/images/agrifos_logotype.svg',
          height: 20,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F5F1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, size: 20, color: Colors.grey.shade700),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.userName,
    required this.avatarUrl,
    required this.color,
    this.onTap,
  });

  final String? userName;
  final String? avatarUrl;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final initial = (userName?.trim().isNotEmpty ?? false)
        ? userName!.trim()[0].toUpperCase()
        : null;

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.5),
          color: color.withValues(alpha: 0.1),
          image: avatarUrl != null
              ? DecorationImage(
            image: NetworkImage(avatarUrl!),
            fit: BoxFit.cover,
          )
              : null,
        ),
        alignment: Alignment.center,
        child: avatarUrl == null
            ? Text(
          initial ?? '',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        )
            : null,
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5F1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF2E4A2E),
        ),
      ),
    );
  }
}