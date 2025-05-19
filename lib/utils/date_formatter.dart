import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DateFormatter {
  static String format(dynamic date) {
    try {
      if (date is Timestamp) {
        date = date.toDate();
      }
      if (date is DateTime) {
        return '${date.day}/${date.month}/${date.year}';
      }
      if (date is String) {
        // Try to parse the string as a date
        try {
          final parsedDate = DateTime.parse(date);
          return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
        } catch (e) {
          print('Warning: Could not parse date string: $date');
        }
      }
      print('Warning: Invalid date type: ${date.runtimeType}');
      return 'Invalid Date';
    } catch (e) {
      print('Error formatting date: $e');
      return 'Invalid Date';
    }
  }

  static String formatWithTime(dynamic date) {
    try {
      if (date is Timestamp) {
        date = date.toDate();
      }
      if (date is DateTime) {
        return '${format(date)} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      }
      if (date is String) {
        // Try to parse the string as a date
        try {
          final parsedDate = DateTime.parse(date);
          return '${format(parsedDate)} ${parsedDate.hour}:${parsedDate.minute.toString().padLeft(2, '0')}';
        } catch (e) {
          print('Warning: Could not parse date string: $date');
        }
      }
      print('Warning: Invalid date type: ${date.runtimeType}');
      return 'Invalid Date';
    } catch (e) {
      print('Error formatting date with time: $e');
      return 'Invalid Date';
    }
  }
} 