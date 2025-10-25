import '../constants/enums.dart';

class CommunityValidator {
  CommunityValidator._();

  /// Validate post content
  static String? validatePostContent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your post content';
    }

    final trimmedContent = value.trim();

    if (trimmedContent.length < 1) {
      return 'Please enter at least 1 character';
    }

    if (trimmedContent.length > 5000) {
      return 'Please limit your post to 5000 characters';
    }

    return null;
  }

  /// Validate post type
  static String? validatePostType(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select a post type';
    }

    // 使用 PostType enum 的 displayName 来验证
    final validTypes = PostType.values.map((type) => type.displayName).toList();

    if (!validTypes.contains(value)) {
      return 'Please select a valid post type';
    }

    return null;
  }

  /// Validate comment content
  static String? validateCommentContent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your comment';
    }

    final trimmedContent = value.trim();

    if (trimmedContent.length < 1) {
      return 'Please enter at least 1 character';
    }

    if (trimmedContent.length > 250) {
      return 'Please limit your comment to 250 characters';
    }

    return null;
  }

  /// Validate reply content
  static String? validateReplyContent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your reply';
    }

    final trimmedContent = value.trim();

    if (trimmedContent.length < 1) {
      return 'Please enter at least 1 character';
    }

    if (trimmedContent.length > 250) {
      return 'Please limit your reply to 250 characters';
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

  /// Validate and get sanitized post content
  static String? getSanitizedPostContent(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Validate and get sanitized comment/reply content
  static String? getSanitizedCommentContent(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
