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
  static const String loginAttempt = 'loginAttempt';
  static const String lastAttemptTime = 'lastAttemptTime';
  static const String accountAvailable = 'accountAvailable';
  static const String profile = 'profile';

  ///-- Users Profile
  static const String gender = "gender";
  static const String dateOfBirth = "dateOfBirth";
  static const String weight = "weight";
  static const String height = "height";
  static const String dietPreference = "dietPreference";
  static const String allergies = "allergies";
  static const String isTakeMedication = "isTakeMedication";
  static const String medicationAdherence = "medicationAdherence";
  static const String sleepDuration = "sleepDuration";
  static const String stressLevel = "stressLevel";
  static const String waterIntake = "waterIntake";
  static const String dailyStepsGoal = "dailyStepsGoal";
  static const String weeklyExerciseTime = "weeklyExerciseTime";
  static const String updatedAt = "updatedAt";

  static const String friends = 'friends';
  static const String sentRequests = 'sentRequests';
  static const String receivedRequests = 'receivedRequests';

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

  ///-- Story
  static const String imageUrl = 'imageUrl';
  static const String storyId = 'storyId';
  static const String views = 'views';

  ///-- Video
  static const String videoUrl = 'videoUrl';
  static const String videoId = 'videoId';

  ///-- Chat
  static const members = 'members';
  static const chatroomId = 'chatroomId';
  static const lastMessage = 'lastMessage';
  static const lastMessageTs = 'lastMessageTs';
  static const message = 'message';
  static const senderId = 'senderId';
  static const receiverId = 'receiverId';
  static const seen = 'seen';
  static const timestamp = 'timestamp';
  static const messageId = 'messageId';
  static const messageType = 'messageType';

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
  static const String notificationType = 'notificationType';
  static const String title = 'title';
  static const String isRead = 'isRead';
}
