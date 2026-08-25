import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared header displayed above every tab in [MainShell].
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.userName,
    this.avatarUrl,
    this.onNotificationsTap,
    this.onProfileTap,
    this.date,
    this.accentColor = _brandGreen,
  });

  final String title;
  final String subtitle;
  final String? userName;
  final String? avatarUrl;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;
  final DateTime? date;
  final Color accentColor;

  static const _brandGreen = Color(0xFF2E4A2E);
  static const _logoColor = Color(0xFF31543B);
  static const _titleColor = Color(0xFF472319);
  static const _monthAbbreviations = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
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
        const SizedBox(height: 6),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.josefinSans(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _titleColor,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      subtitle.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _DateBadge(label: monthLabel, color: accentColor),
          ],
        ),
        const SizedBox(height: 9),
        Container(
          height: 2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              colors: [
                accentColor,
                accentColor.withValues(alpha: 0.45),
                accentColor.withValues(alpha: 0.08),
              ],
              stops: const [0, 0.58, 1],
            ),
          ),
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
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SvgPicture.asset(
            'assets/images/agrifos_isotype.svg',
            height: 16,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
        const SizedBox(width: 8),
        SvgPicture.asset(
          'assets/images/agrifos_logotype.svg',
          height: 18,
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
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F5F1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, size: 18, color: Colors.grey.shade700),
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
        width: 34,
        height: 34,
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
  const _DateBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
