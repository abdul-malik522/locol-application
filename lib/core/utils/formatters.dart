import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class Formatters {
  const Formatters._();

  static final _currencyFormat = NumberFormat.currency(symbol: '\$');
  static final _dateFormat = DateFormat.yMMMd();
  static final _timeFormat = DateFormat.jm();

  static String formatCurrency(double amount) {
    return _currencyFormat.format(amount);
  }

  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      final meters = (distanceKm * 1000).round();
      return '$meters m';
    }
    return '${distanceKm.toStringAsFixed(distanceKm >= 10 ? 0 : 1)} km';
  }

  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  static String formatTime(DateTime time) {
    return _timeFormat.format(time);
  }

  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} · ${formatTime(dateTime)}';
  }

  static String formatRelativeTime(DateTime dateTime) {
    return timeago.format(dateTime);
  }

  static String formatPhoneNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.length == 10) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    }
    return phone;
  }

  static String formatQuantity(int quantity, String unit) {
    return '$quantity $unit';
  }

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength - 3)}...';
  }
}

