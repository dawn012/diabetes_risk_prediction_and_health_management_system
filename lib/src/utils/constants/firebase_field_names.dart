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
  static const String isVerify = 'isVerify';
  static const String loginAttempt = 'loginAttempt';
  static const String lastAttemptTime = 'lastAttemptTime';
  static const String accountAvailable = 'accountAvailable';

  static const String birthDay = 'birth_day';
  static const String gender = 'gender';
  static const String friends = 'friends';
  static const String sentRequests = 'sent_requests';
  static const String receivedRequests = 'receivedRequests';

  ///-- Posts
  static const String postId = 'post_id';
  static const String posterId = 'poster_id';
  static const String content = 'content';
  static const String fileUrl = 'file_url';
  static const String datePublished = 'date_published';
  static const String postType = 'post_type';
  static const String likes = 'likes';

  ///-- Comments
  static const String commentId = 'comment_id';
  static const String authorId = 'author_id';
  static const String createdAt = 'created_at';
  static const String text = 'text';

  ///-- Replies
  static const String parentCommentId = 'parent_comment_id';
  static const String mentions = 'mentions';
  static const String replyCount = 'reply_count';

  ///-- Story
  static const String imageUrl = 'image_url';
  static const String storyId = 'story_id';
  static const String views = 'views';

  ///-- Video
  static const String videoUrl = 'video_url';
  static const String videoId = 'video_id';

  ///-- Chat
  static const members = 'members';
  static const chatroomId = 'chatroom_id';
  static const lastMessage = 'last_message';
  static const lastMessageTs = 'last_message_ts';
  static const message = 'message';
  static const senderId = 'sender_id';
  static const receiverId = 'receiver_id';
  static const seen = 'seen';
  static const timestamp = 'timestamp';
  static const messageId = 'message_id';
  static const messageType = 'message_type';

  ///-- Achievement
  static const String achievementId = 'achievementId';
  static const String achievementTitle = 'achievementTitle';
  static const String description = 'description';
  static const String achievementType = 'achievementType';
  static const String imagePath = 'imagePath';
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

  // User Subscription
  static const String subscriptionId = "subscriptionId";
  // static const String userId = "userId";
  static const String subscriptionPlan = "subscriptionPlan";
  static const String paymentTransaction = "paymentTransaction";
  static const String startDateTime = "startDateTime";
  static const String endDateTime = "endDateTime";
  static const String autoRenew = "autoRenew";
  // static const String status = "status";

  // Subscription Plan
  static const String subscriptionPlanId = "subscriptionPlanId";
  static const String planName = "planName";
  static const String price = "price";
  static const String durationDays = "durationDays";
  static const String features = "features";
  // static const String isActive = "isActive";

  // Payment Transaction
  static const String transactionId = "transactionId";
  static const String amount = "amount";
  static const String currency = "currency";
  static const String paymentMethod = "paymentMethod";
  static const String transactionDateTime = "transactionDateTime";
}
