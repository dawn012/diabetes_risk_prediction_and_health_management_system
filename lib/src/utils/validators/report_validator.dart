import '../constants/enums.dart';

class ReportValidator {
  ReportValidator._();

  /// Validate report reason
  static String? validateReason(ReportReason? reason) {
    if (reason == null) {
      return 'Please select a reason';
    }
    return null;
  }

  /// Validate additional note (only required for "Other" reason)
  static String? validateAdditionalNote(String? value, ReportReason? reason) {
    // Additional note is only required for "Other" reason
    if (reason == ReportReason.other) {
      if (value == null || value.trim().isEmpty) {
        return 'Please provide details about the issue';
      }

      final trimmedContent = value.trim();

      if (trimmedContent.length < 10) {
        return 'Please provide at least 10 characters';
      }

      if (trimmedContent.length > 500) {
        return 'Please limit your note to 500 characters';
      }
    }

    return null;
  }

  /// Check if content has only whitespace
  static bool isOnlyWhitespace(String? value) {
    if (value == null) return true;
    return value.trim().isEmpty;
  }

  /// Get remaining characters count
  static int getRemainingCharacters(String? value, int maxLength) {
    if (value == null) return maxLength;
    return maxLength - value.length;
  }

  /// Validate and get sanitized additional note
  static String? getSanitizedNote(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}