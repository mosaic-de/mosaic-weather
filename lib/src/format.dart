String formatTemp(double celsius) => '${celsius.round()}°';

String formatTempRange(double minC, double maxC) =>
    '${minC.round()}° / ${maxC.round()}°';

String formatHour(DateTime t) {
  final h = t.hour;
  final ampm = h < 12 ? 'AM' : 'PM';
  final hh = h % 12 == 0 ? 12 : h % 12;
  return '$hh $ampm';
}

String formatTimeOfDay(DateTime t) {
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String formatRelativeFromNow(DateTime t) {
  final diff = DateTime.now().difference(t).abs();
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

const _weekdayShort = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String formatWeekdayShort(DateTime date) =>
    _weekdayShort[(date.weekday - 1).clamp(0, 6)];
