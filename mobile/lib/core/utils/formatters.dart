import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

abstract class AppFormatters {
  static const Uuid _uuid = Uuid();

  /// Format amount in Bangladeshi Taka (৳)
  static String formatBdt(num amount) {
    final formatter = NumberFormat.currency(
      symbol: '৳',
      decimalDigits: amount is int || amount % 1 == 0 ? 0 : 2,
      locale: 'en_BD',
    );
    return formatter.format(amount);
  }

  /// Generate a unique UUID v4 for client-side offline idempotency
  static String generateUuid() {
    return _uuid.v4();
  }

  /// Format DateTime to readable string e.g. "12 Aug 2026, 10:30 AM"
  static String formatDateTime(DateTime dt) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  /// Format DateTime to short date e.g. "12 Aug 2026"
  static String formatDateShort(DateTime dt) {
    return DateFormat('dd MMM yyyy').format(dt);
  }
}
