/// Formatting helpers for money, dates and names.
library;

String naira(num amount) {
  final s = amount.round().abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return '${amount < 0 ? '−' : ''}₦$b';
}

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _two(int n) => n.toString().padLeft(2, '0');

/// 06:30
String fmtTime(DateTime? d) =>
    d == null ? '' : '${_two(d.hour)}:${_two(d.minute)}';

/// Sat 10 Oct
String fmtDay(DateTime? d) =>
    d == null ? '' : '${_days[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

/// Sat 10 Oct, 06:30
String fmtDayTime(DateTime? d) =>
    d == null ? '' : '${fmtDay(d)}, ${fmtTime(d)}';

/// 10 Oct 2026
String fmtDate(DateTime? d) =>
    d == null ? '' : '${d.day} ${_months[d.month - 1]} ${d.year}';

String weekdayShort(DateTime d) => _days[d.weekday - 1];

/// "5 min ago", "Yesterday", "Mon", "10 Oct".
String timeAgo(DateTime? d) {
  if (d == null) return '';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return _days[d.weekday - 1];
  return '${d.day} ${_months[d.month - 1]}';
}

/// 240 → "4 hours", 90 → "1 h 30 min".
String fmtDuration(int minutes) {
  final h = minutes ~/ 60, m = minutes % 60;
  if (h == 0) return '$m min';
  if (m == 0) return h == 1 ? '1 hour' : '$h hours';
  return '$h h $m min';
}

/// pending_review → Pending review
String humanize(String? value) {
  if (value == null || value.isEmpty) return '';
  final s = value.replaceAll('_', ' ');
  return s[0].toUpperCase() + s.substring(1);
}

/// "Tunde Bakare" → "TB"
String initials(String? name) {
  final parts = (name ?? '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  return parts.take(2).map((p) => p[0].toUpperCase()).join();
}

/// 2300 → "2.3k"
String compact(int n) => n >= 1000
    ? '${(n / 1000).toStringAsFixed(n % 1000 >= 100 ? 1 : 0)}k'
    : '$n';

String plural(int n, String one, [String? many]) =>
    '$n ${n == 1 ? one : (many ?? '${one}s')}';

const paymentLabels = {
  'card': 'Card',
  'wallet': 'Cabo Wallet',
  'bank_transfer': 'Bank transfer',
  'cash': 'Cash',
};
