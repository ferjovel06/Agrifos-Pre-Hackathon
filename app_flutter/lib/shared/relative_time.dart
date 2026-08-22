/// Formats [dateTime] as a short Spanish relative-time label, e.g.
/// "Hace 2 horas", "Hace 5 min", "Hace 3 días".
String formatRelativeTime(DateTime dateTime, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final diff = reference.difference(dateTime);

  if (diff.isNegative || diff.inSeconds < 60) {
    return 'Hace un momento';
  }
  if (diff.inMinutes < 60) {
    final minutes = diff.inMinutes;
    return 'Hace $minutes min';
  }
  if (diff.inHours < 24) {
    final hours = diff.inHours;
    return 'Hace $hours ${hours == 1 ? 'hora' : 'horas'}';
  }
  final days = diff.inDays;
  return 'Hace $days ${days == 1 ? 'día' : 'días'}';
}