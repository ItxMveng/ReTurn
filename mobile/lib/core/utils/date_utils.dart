import 'package:intl/intl.dart';

final class AppDateUtils {
  AppDateUtils._();

  static final _dateFmt = DateFormat('dd/MM/yyyy', 'fr');
  static final _timeFmt = DateFormat('HH:mm', 'fr');
  static final _dateTimeFmt = DateFormat('dd MMM yyyy à HH:mm', 'fr');
  static final _relFmt = DateFormat('dd MMM', 'fr');

  static String formatDate(DateTime d) => _dateFmt.format(d.toLocal());
  static String formatTime(DateTime d) => _timeFmt.format(d.toLocal());
  static String formatDateTime(DateTime d) => _dateTimeFmt.format(d.toLocal());

  static String relative(DateTime d) {
    final diff = DateTime.now().difference(d.toLocal());
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    return _relFmt.format(d.toLocal());
  }

  static DateTime? tryParse(String? s) {
    if (s == null) return null;
    return DateTime.tryParse(s);
  }
}
