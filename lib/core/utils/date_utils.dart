import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _dateShort = DateFormat('dd MMM yyyy', 'id_ID');
  static final DateFormat _dateLong = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
  static final DateFormat _dateTime = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  static final DateFormat _timeOnly = DateFormat('HH:mm', 'id_ID');

  static String formatShort(DateTime date) => _dateShort.format(date);
  static String formatLong(DateTime date) => _dateLong.format(date);
  static String formatDateTime(DateTime date) => _dateTime.format(date);
  static String formatTime(DateTime date) => _timeOnly.format(date);

  /// Kembalikan label relatif: "Baru saja", "2 jam lalu", "3 hari lalu"
  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return formatShort(date);
  }
}
