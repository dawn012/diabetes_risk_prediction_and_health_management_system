import 'package:intl/intl.dart';

class TFormatter {
  TFormatter._();

  /// Format date with relative time (Today, Yesterday, X days ago)
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today, ${_formatTime(date)}';
    } else if (difference == 1) {
      return 'Yesterday, ${_formatTime(date)}';
    } else if (difference < 7) {
      return '${difference}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Smart formatter for record time display
  /// Today → "Today, HH:mm"
  /// Yesterday → "Yesterday, HH:mm"
  /// 2–6 days ago → "3 days ago"
  /// 7–29 days ago → "on 10 days ago"
  /// >=30 days → "on MMM d, yyyy"
  static String formatLastRecordDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(recordDate).inDays;

    if (difference == 0) {
      // Same day
      return 'Today, ${DateFormat('HH:mm').format(date)}';
    } else if (difference == 1) {
      return 'Yesterday, ${DateFormat('HH:mm').format(date)}';
    } else if (difference >= 2 && difference <= 6) {
      return '${difference} days ago';
    } else if (difference >= 7 && difference < 30) {
      return 'on ${difference} days ago';
    } else {
      return 'on ${DateFormat('MMM d, yyyy').format(date)}';
    }
  }

  static String formatElapsedTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${_formatTime(date)}';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    }
  }

  /// Format time in HH:mm format
  static String formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Private helper method for time formatting
  static String _formatTime(DateTime date) {
    return formatTime(date);
  }

  static String formatDate(DateTime? date) {
    date ??= DateTime.now();
    return DateFormat('dd-MMM-yyyy').format(date);
  }

  static String formatDateTime(DateTime? date) {
    date ??= DateTime.now();
    return DateFormat('dd MMM yyyy HH:mm').format(date);
  }

  static String formatHistoryDateTime(DateTime? date) {
    date ??= DateTime.now();
    return DateFormat('MMM dd, yyyy hh:mm a').format(date);
  }

  static String formatFullDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final month = months[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$month $day, $year at $hour:$minute';
  }

  static String formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'ms_MY', symbol: 'RM').format(amount);
  }

  static String formatPhoneNumber(String phoneNumber) {
    // Remove all non-numeric characters
    phoneNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');

    // Ensure the phone number starts with "60" (Malaysia country code)
    if (phoneNumber.startsWith('0')) {
      phoneNumber = '60${phoneNumber.substring(1)}';
    } else if (!phoneNumber.startsWith('60')) {
      phoneNumber = '60$phoneNumber';
    }

    // Return the formatted phone number with +60
    return '+$phoneNumber';
  }

  // Not fully tested
  static String internationalFormatPhoneNumber(String phoneNumber) {
    // Remove all non-numeric characters
    var digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');

    // Extract the country code from the digitsOnly
    String countryCode = '+${digitsOnly.substring(0, 2)}';
    digitsOnly = digitsOnly.substring(2);
    
    // Add the remaining digits with proper formatting
    final formattedNumber = StringBuffer();
    formattedNumber.write('($countryCode)');
    
    int i = 0;
    while (i < digitsOnly.length) {
      int groupLength = 2;
      if (i == 0 && countryCode == '+1') {
        groupLength = 3;
      }
      
      int end = i + groupLength;
      formattedNumber.write(digitsOnly.substring(i, end));
      
      if (end < digitsOnly.length) {
        formattedNumber.write(' ');
      }

      i = end;
    }

    return formattedNumber.toString();
  }
}