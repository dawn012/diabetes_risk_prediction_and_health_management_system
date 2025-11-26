class MealValidator {
  MealValidator._();

  /// Validate diet preference selection
  static String? validateDietPreference(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select your dietary preference';
    }
    return null;
  }

  /// Validate cooking difficulty selection
  static String? validateCookingDifficulty(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select your cooking difficulty level';
    }
    return null;
  }

  /// Validate preparation time
  static String? validatePreparationTime(int? value) {
    if (value == null || value <= 0) {
      return 'Please set a valid preparation time';
    }
    if (value < 10) {
      return 'Preparation time must be at least 10 minutes';
    }
    if (value > 120) {
      return 'Preparation time cannot exceed 2 hours';
    }
    return null;
  }

  /// Validate meal plan type
  static String? validatePlanType(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a meal plan type';
    }
    return null;
  }

  /// Validate allergens selection (optional but with max limit)
  static String? validateAllergens(List<String> allergens) {
    if (allergens.length > 10) {
      return 'Please select a maximum of 10 allergens';
    }
    return null;
  }

  /// Validate cooking methods selection (optional but with max limit)
  static String? validateCookingMethods(List<String> methods) {
    if (methods.length > 5) {
      return 'Please select a maximum of 5 cooking methods';
    }
    return null;
  }

  /// Validate meal plan date range
  static String? validateDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null) {
      return 'Please select a start date';
    }
    if (endDate == null) {
      return 'Please select an end date';
    }
    if (endDate.isBefore(startDate)) {
      return 'End date must be after start date';
    }
    if (endDate.difference(startDate).inDays > 7) {
      return 'Date range cannot exceed 7 days';
    }
    return null;
  }

  /// Validate meal notes
  static String? validateMealNotes(String? value) {
    if (value != null && value.length > 500) {
      return 'Notes cannot exceed 500 characters';
    }
    return null;
  }

  /// Validate meal consumption status change
  static String? validateConsumptionStatusChange(
      String currentStatus,
      String newStatus,
      ) {
    if (currentStatus == 'consumed' && newStatus != 'consumed') {
      return 'Cannot change status after meal is consumed';
    }
    if (currentStatus == 'skipped' && newStatus == 'consumed') {
      return 'Cannot consume a skipped meal';
    }
    return null;
  }

  /// Validate meal replacement request
  static String? validateMealReplacement(String? mealId) {
    if (mealId == null || mealId.isEmpty) {
      return 'Invalid meal ID for replacement';
    }
    return null;
  }

  /// Validate adherence percentage
  static String? validateAdherence(int? adherence) {
    if (adherence == null) {
      return 'Adherence value is required';
    }
    if (adherence < 0 || adherence > 100) {
      return 'Adherence must be between 0 and 100';
    }
    return null;
  }
}