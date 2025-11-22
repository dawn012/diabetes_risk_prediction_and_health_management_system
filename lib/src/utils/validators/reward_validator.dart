import '../constants/enums.dart';

class RewardValidator {
  RewardValidator._();

  // ==================== Reward Validation ====================

  /// Validate reward title
  static String? validateRewardTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the reward title.';
    }
    if (value.trim().length < 3) {
      return 'Title must be at least 3 characters.';
    }
    if (value.trim().length > 15) {
      return 'Title must not exceed 15 characters.';
    }
    return null;
  }

  /// Validate reward description
  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the reward description.';
    }
    if (value.trim().length < 10) {
      return 'Description must be at least 10 characters.';
    }
    if (value.trim().length > 500) {
      return 'Description must not exceed 500 characters.';
    }
    return null;
  }

  /// Validate reward type
  static String? validateRewardType(RewardType? type) {
    if (type == null) {
      return 'Please select the reward type.';
    }
    return null;
  }

  /// Validate cost points
  static String? validateCostPoints(int? points) {
    if (points == null) {
      return 'Please enter the cost points.';
    }
    if (points < 1) {
      return 'Cost points must be at least 1.';
    }
    if (points > 1000000) {
      return 'Cost points cannot exceed 1,000,000.';
    }
    return null;
  }

  /// Validate available quantity
  static String? validateAvailableQuantity(int? quantity) {
    if (quantity != null) {
      if (quantity < 0) {
        return 'Quantity cannot be negative.';
      }
      if (quantity > 1000000) {
        return 'Quantity cannot exceed 1,000,000.';
      }
    }
    return null;
  }

  /// Validate reward icon/image
  static String? validateIcon(String? icon) {
    if (icon == null || icon.trim().isEmpty) {
      return 'Please upload a reward image.';
    }
    return null;
  }

  /// Validate image bytes
  static String? validateImageBytes(dynamic bytes) {
    if (bytes == null) {
      return 'Please select an image.';
    }
    return null;
  }

  // ==================== Complete Form Validation ====================

  /// Validate complete reward form
  static Map<String, String> validateRewardForm({
    required String? title,
    required String? description,
    required RewardType? type,
    required int? costPoints,
    int? availableQuantity,
    required String? icon,
  }) {
    final errors = <String, String>{};

    final titleError = validateRewardTitle(title);
    if (titleError != null) errors['title'] = titleError;

    final descError = validateDescription(description);
    if (descError != null) errors['description'] = descError;

    final typeError = validateRewardType(type);
    if (typeError != null) errors['type'] = typeError;

    final pointsError = validateCostPoints(costPoints);
    if (pointsError != null) errors['costPoints'] = pointsError;

    final quantityError = validateAvailableQuantity(availableQuantity);
    if (quantityError != null) errors['availableQuantity'] = quantityError;

    final iconError = validateIcon(icon);
    if (iconError != null) errors['icon'] = iconError;

    return errors;
  }
}
