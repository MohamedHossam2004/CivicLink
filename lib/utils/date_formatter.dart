import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DateFormatter {
  static String format(dynamic date) {
    if (date is Timestamp) {
      return DateFormat('dd/MM/yyyy').format(date.toDate());
    } else if (date is DateTime) {
      return DateFormat('dd/MM/yyyy').format(date);
    } else if (date is String) {
      try {
        return DateFormat('dd/MM/yyyy').format(DateTime.parse(date));
      } catch (e) {
        return 'Invalid date';
      }
    }
    return 'No date set';
  }

  static String formatWithTime(dynamic date) {
    if (date is Timestamp) {
      return DateFormat('dd/MM/yyyy HH:mm').format(date.toDate());
    } else if (date is DateTime) {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } else if (date is String) {
      try {
        return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(date));
      } catch (e) {
        return 'Invalid date';
      }
    }
    return 'No date set';
  }

  static String formatTime(dynamic date) {
    if (date is Timestamp) {
      return DateFormat('HH:mm').format(date.toDate());
    } else if (date is DateTime) {
      return DateFormat('HH:mm').format(date);
    } else if (date is String) {
      try {
        return DateFormat('HH:mm').format(DateTime.parse(date));
      } catch (e) {
        return 'Invalid time';
      }
    }
    return 'No time set';
  }
}
