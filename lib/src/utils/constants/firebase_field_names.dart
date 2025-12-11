class FirebaseFieldNames {
  FirebaseFieldNames._();

  ///-- Users
  static const String userId = 'userId';
  static const String username = 'username';
  static const String userType = 'userType';
  static const String email = 'email';
  static const String password = 'password';
  static const String phoneNumber = 'phoneNumber';
  static const String profileImg = 'profileImg';
  static const String joinDate = 'joinDate';
  static const String totalScore = 'totalScore';
  static const String lastScoreUpdateTime = 'lastScoreUpdateTime';
  static const String isVerify = 'isVerify';
  static const String rewardPoints = 'rewardPoints';
  static const String currentAvatarFrame = 'currentAvatarFrame';
  static const String loginAttempt = 'loginAttempt';
  static const String lastAttemptTime = 'lastAttemptTime';
  static const String accountAvailable = 'accountAvailable';
  static const String isDeleted = 'isDeleted';
  static const String profile = 'profile';
  static const String lastActive = 'lastActive';

  ///-- Users Profile
  static const String gender = "gender";
  static const String dateOfBirth = "dateOfBirth";
  static const String weight = "weight";
  static const String height = "height";
  static const String allergies = "allergies";
  static const String isTakeMedication = "isTakeMedication";
  static const String medicationAdherence = "medicationAdherence";
  static const String sleepDuration = "sleepDuration";
  static const String stressLevel = "stressLevel";
  static const String waterIntake = "waterIntake";
  static const String dailyStepsGoal = "dailyStepsGoal";
  static const String weeklyExerciseTime = "weeklyExerciseTime";
  static const String hasChangedGender = "hasChangedGender";
  static const String hasChangedDateOfBirth = "hasChangedDateOfBirth";
  static const String updatedAt = "updatedAt";

  ///-- Meal Preferences
  static const String mealPreferences = 'mealPreferences';
  static const String dietPreference = 'dietPreference';
  static const String allergens = 'allergens';
  static const String preferredCookingMethods = 'preferredCookingMethods';
  static const String maxPreparationTime = 'maxPreparationTime';

  ///-- Meal Plan
  static const String mealPlanId = 'mealPlanId';
  static const String planType = 'planType';
  static const String adherence = 'adherence';
  static const String scheduledMeals = 'scheduledMeals';

  ///-- Meal Plan Meal
  static const String mealPlanMealId = 'mealPlanMealId';
  static const String meal = 'meal';
  static const String scheduledDate = 'scheduledDate';
  static const String mealTimeSlot = 'mealTimeSlot';

  ///-- Meal
  static const String mealId = 'mealId';
  static const String mealName = 'mealName';
  static const String mealDescription = 'mealDescription';
  static const String imageUrl = 'imageUrl';
  static const String ingredients = 'ingredients';
  static const String preparationTime = 'preparationTime';
  static const String cookingTime = 'cookingTime';
  static const String nutrient = 'nutrient';
  static const String instructions = 'instructions';
  static const String serves = 'serves';
  static const String dishType = 'dishType';
  static const String dietaryRestrictions = 'dietaryRestrictions';
  static const String dietType = 'dietType';
  static const String cookingMethod = 'cookingMethod';
  static const String authorName = 'authorName';
  static const String notes = 'notes';
  static const String sourceUrl = 'sourceUrl';

  ///-- Nutrient
  static const String calories = 'calories';
  static const String protein = 'protein';
  static const String fat = 'fat';
  static const String saturatedFat = 'saturatedFat';
  static const String carbohydrates = 'carbohydrates';
  static const String fiber = 'fiber';
  static const String sugar = 'sugar';
  static const String sodium = 'sodium';
  static const String cholesterol = 'cholesterol';

  ///-- Reward
  static const String rewardId = 'rewardId';
  static const String rewardType = 'rewardType';
  static const String icon = 'icon';
  static const String costPoints = 'costPoints';
  static const String availableQuantity = 'availableQuantity';

  ///-- User Reward
  static const String pointsSpent = 'pointsSpent';
  static const String redeemedAt = 'redeemedAt';

  ///-- Health Data
  static const String logId = 'logId';
  static const String logDateTime = 'logDateTime';
  static const String physiologicalTimePeriod = 'physiologicalTimePeriod';
  static const String steps = 'steps';

  // Nested objects
  static const String bloodPressure = 'bloodPressure';
  static const String bloodGlucose = 'bloodGlucose';
  static const String bodyComposition = 'bodyComposition';
  static const String physicalActivity = 'physicalActivity';

  // blood pressure
  static const systolic = 'systolic';
  static const diastolic = 'diastolic';
  static const pulse = 'pulse';

  // blood glucose
  static const glucoseLevel = 'glucoseLevel';

  // body composition
  // static const weight = 'weight';
  static const bodyFat = 'bodyFat';

  // physical activity
  static const activityType = 'activityType';
  static const duration = 'duration';
  static const intensityLevel = 'intensityLevel';

  ///-- Posts
  static const String postId = 'postId';
  static const String posterId = 'posterId';
  static const String postType = 'postType';
  static const String postContent = 'postContent';
  static const String mediaUrls = 'mediaUrls';
  static const String likes = 'likes';
  static const String commentCount = 'commentCount';
  static const String createdAt = 'createdAt';
  static const String isDisable = 'isDisable';
  static const String pendingReportCount = 'pendingReportCount';
  static const String latestReportTime = 'latestReportTime';

  ///-- Comments
  static const String commentId = 'commentId';
  static const String authorId = 'authorId';
  // static const String createdAt = 'createdAt';
  static const String content = 'content';

  ///-- Replies
  static const String replyId = 'replyId';
  static const String parentCommentId = 'parentCommentId';
  static const String mentions = 'mentions';
  static const String replyCount = 'replyCount';

  ///-- Report
  static const String reportId = 'reportId';
  static const String reporterId = 'reporterId';
  static const String reason = 'reason';
  static const String additionalNote = 'additionalNote';
  static const String resolvedAt = 'resolvedAt';

  ///-- Story
  static const String storyId = 'storyId';
  static const String views = 'views';

  ///-- Video
  static const String videoUrl = 'videoUrl';
  static const String videoId = 'videoId';

  /// Diabetes Prediction
  static const String predictionId = 'predictionId';
  static const String predictionDateTime = 'predictionDateTime';
  static const String riskLevel = 'riskLevel';
  static const String riskScore = 'riskScore';
  static const String recommendations = 'recommendations';

  ///-- Achievement
  static const String achievementId = 'achievementId';
  static const String achievementTitle = 'achievementTitle';
  static const String description = 'description';
  static const String achievementType = 'achievementType';
  static const String iconCodePoint = 'iconCodePoint';
  static const String levels = 'levels';
  static const String isActive = 'isActive';
  // static const String createdAt = 'createdAt';

  ///-- Achievement Level
  static const String level = 'level';
  static const String criteria = 'criteria';
  static const String criteriaUnit = 'criteriaUnit';
  static const String points = 'points';

  ///-- User Achievement
  static const String userAchievementId = 'userAchievementId';
  static const String currentLevel = 'currentLevel';
  static const String currentCount = 'currentCount';
  static const String status = 'status';
  static const String startedAt = 'startedAt';
  static const String completedAt = 'completedAt';

  ///-- Reminder
  static const String reminderId = 'reminderId';
  static const String reminderTitle = 'reminderTitle';
  static const String baseTime = 'baseTime';
  static const String repeatType = 'repeatType';
  static const String customDays = 'customDays';
  static const String intervalTime = 'intervalTime';
  static const String endDate = 'endDate';
  static const String nextTriggerTime = 'nextTriggerTime';
  static const String snoozeDuration = 'snoozeDuration';
  static const String isMealReminder = 'isMealReminder';
  // static const String isActive = 'isActive';

  /// -- ReminderSchedule
  static const String scheduleId = 'scheduleId';
  static const String triggerTime = 'triggerTime';
  static const String originalTime = 'originalTime';
  static const String snoozeCount = 'snoozeCount';
  // static const String status = 'status';

  ///-- User Subscription
  static const String subscriptionId = "subscriptionId";
  // static const String userId = "userId";
  static const String subscriptionPlan = "subscriptionPlan";
  static const String paymentTransaction = "paymentTransaction";
  static const String startDateTime = "startDateTime";
  static const String endDateTime = "endDateTime";
  static const String autoRenew = "autoRenew";
  static const String cancelAt = "cancelAt";
  // static const String status = "status";

  ///-- Subscription Plan
  static const String subscriptionPlanId = "subscriptionPlanId";
  static const String planName = "planName";
  static const String price = "price";
  static const String durationDays = "durationDays";
  static const String features = "features";
  // static const String isActive = "isActive";

  ///-- Payment Transaction
  static const String transactionId = "transactionId";
  static const String amount = "amount";
  static const String currency = "currency";
  static const String paymentMethod = "paymentMethod";
  static const String transactionDateTime = "transactionDateTime";

  ///-- Notification fields
  static const String notificationId = 'notificationId';
  static const String notificationTitle = 'notificationTitle';
  static const String message = 'message';
  static const String notificationType = 'notificationType';
  static const String title = 'title';
  static const String isRead = 'isRead';

  static const String requestId = 'requestId';
  static const String requesterId = 'requesterId';
  static const String requestStatus = 'requestStatus';
  static const String responderId = 'responderId';
  static const String expiresAt = 'expiresAt';
  static const String responseMessage = 'responseMessage';
}
