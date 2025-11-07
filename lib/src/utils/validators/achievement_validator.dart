import '../constants/enums.dart';

class AchievementValidator {
  AchievementValidator._();

  // ==================== Achievement Validation ====================

  /// Validate achievement title
  static String? validateAchievementTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the achievement title.';
    }
    if (value.trim().length < 3) {
      return 'Title must be at least 3 characters';
    }
    if (value.trim().length > 100) {
      return 'Title must not exceed 100 characters';
    }
    return null;
  }

  /// Validate achievement description
  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the achievement description.';
    }
    if (value.trim().length < 10) {
      return 'Description must be at least 10 characters';
    }
    if (value.trim().length > 500) {
      return 'Description must not exceed 500 characters';
    }
    return null;
  }

  /// Validate achievement type
  static String? validateAchievementType(AchievementType? type) {
    if (type == null) {
      return 'Please select the achievement type.';
    }
    return null;
  }

  /// Validate achievement levels list
  static String? validateLevels(List<dynamic>? levels) {
    if (levels == null || levels.isEmpty) {
      return 'Achievement must have at least one level';
    }
    if (levels.length > 3) {
      return 'Achievement cannot have more than 3 levels (Bronze, Silver, Gold)';
    }
    return null;
  }

  // ==================== Achievement Level Validation ====================

  /// Validate level enum
  static String? validateLevel(AchievementLevel? level) {
    if (level == null) {
      return 'Please select the achievement level.';
    }
    return null;
  }

  /// Validate level criteria
  static String? validateCriteria(int? criteria) {
    if (criteria == null) {
      return 'Please enter the criteria value.';
    }
    if (criteria < 1) {
      return 'Criteria must be at least 1';
    }
    if (criteria > 1000000) {
      return 'Criteria cannot exceed 1,000,000';
    }
    return null;
  }

  /// Validate criteria unit
  static String? validateCriteriaUnit(String? unit) {
    if (unit == null || unit.trim().isEmpty) {
      return 'Please enter the criteria unit.';
    }
    if (unit.trim().length > 50) {
      return 'Unit must not exceed 50 characters';
    }
    return null;
  }

  /// Validate level points
  static String? validatePoints(int? points) {
    if (points == null) {
      return 'Please enter the points value.';
    }
    if (points < 0) {
      return 'Points cannot be negative';
    }
    if (points > 100000) {
      return 'Points cannot exceed 100,000';
    }
    return null;
  }

  /// Validate that levels are in ascending order of criteria
  static String? validateLevelsProgression(List<dynamic> levels) {
    if (levels.length < 2) return null;

    for (int i = 0; i < levels.length - 1; i++) {
      final currentCriteria = levels[i]['criteria'] as int?;
      final nextCriteria = levels[i + 1]['criteria'] as int?;

      if (currentCriteria == null || nextCriteria == null) {
        return 'All levels must have valid criteria values';
      }

      if (currentCriteria >= nextCriteria) {
        return 'Each level must require more than the previous level';
      }
    }
    return null;
  }

  /// Validate that permanent achievements have 0 points
  static String? validatePermanentPoints(
      AchievementType type, List<dynamic> levels) {
    if (type == AchievementType.permanent) {
      for (final level in levels) {
        final points = level['points'] as int?;
        if (points != null && points != 0) {
          return 'Permanent achievements must have 0 points for all levels';
        }
      }
    }
    return null;
  }

  // ==================== User Achievement Validation ====================

  /// Validate user achievement ID
  static String? validateUserAchievementId(String? id) {
    if (id == null || id.trim().isEmpty) {
      return 'User achievement ID is required';
    }
    return null;
  }

  /// Validate achievement ID reference
  static String? validateAchievementId(String? id) {
    if (id == null || id.trim().isEmpty) {
      return 'Achievement ID is required';
    }
    return null;
  }

  /// Validate current level
  static String? validateCurrentLevel(UserAchievementLevel? level) {
    if (level == null) {
      return 'Current level is required';
    }
    return null;
  }

  /// Validate current count
  static String? validateCurrentCount(int? count) {
    if (count == null) {
      return 'Current count is required';
    }
    if (count < 0) {
      return 'Current count cannot be negative';
    }
    return null;
  }

  /// Validate achievement status
  static String? validateStatus(AchievementStatus? status) {
    if (status == null) {
      return 'Status is required';
    }
    return null;
  }

  /// Validate started date
  static String? validateStartedAt(DateTime? date) {
    if (date == null) {
      return 'Started date is required';
    }
    final now = DateTime.now();
    if (date.isAfter(now)) {
      return 'Started date cannot be in the future';
    }
    return null;
  }

  /// Validate completed date
  static String? validateCompletedAt(
      DateTime? completedAt, DateTime? startedAt, AchievementStatus? status) {
    if (status == AchievementStatus.completed) {
      if (completedAt == null) {
        return 'Completed date is required for completed achievements';
      }
      if (startedAt != null && completedAt.isBefore(startedAt)) {
        return 'Completed date must be after started date';
      }
      final now = DateTime.now();
      if (completedAt.isAfter(now)) {
        return 'Completed date cannot be in the future';
      }
    }
    return null;
  }

  /// Validate that current level matches current count
  static String? validateLevelCountMatch(
      UserAchievementLevel currentLevel,
      int currentCount,
      List<dynamic> achievementLevels) {
    if (currentLevel == UserAchievementLevel.none) {
      if (achievementLevels.isNotEmpty) {
        final firstLevelCriteria = achievementLevels[0]['criteria'] as int?;
        if (firstLevelCriteria != null && currentCount >= firstLevelCriteria) {
          return 'Count meets criteria but level is still "none"';
        }
      }
      return null;
    }

    // Find the matching level in achievement levels
    final matchingLevel = achievementLevels.firstWhere(
          (level) => level['level'] == currentLevel.value,
      orElse: () => null,
    );

    if (matchingLevel == null) {
      return 'Current level does not exist in achievement levels';
    }

    final criteria = matchingLevel['criteria'] as int?;
    if (criteria != null && currentCount < criteria) {
      return 'Count is less than required criteria for current level';
    }

    return null;
  }

  // ==================== Complete Form Validation ====================

  /// Validate complete achievement form
  static Map<String, String> validateAchievementForm({
    required String? title,
    required String? description,
    required AchievementType? type,
    required List<dynamic>? levels,
  }) {
    final errors = <String, String>{};

    final titleError = validateAchievementTitle(title);
    if (titleError != null) errors['title'] = titleError;

    final descError = validateDescription(description);
    if (descError != null) errors['description'] = descError;

    final typeError = validateAchievementType(type);
    if (typeError != null) errors['type'] = typeError;

    final levelsError = validateLevels(levels);
    if (levelsError != null) {
      errors['levels'] = levelsError;
    } else if (levels != null && levels.isNotEmpty) {
      final progressionError = validateLevelsProgression(levels);
      if (progressionError != null) errors['levelsProgression'] = progressionError;

      if (type != null) {
        final permanentError = validatePermanentPoints(type, levels);
        if (permanentError != null) errors['permanentPoints'] = permanentError;
      }
    }

    return errors;
  }
}