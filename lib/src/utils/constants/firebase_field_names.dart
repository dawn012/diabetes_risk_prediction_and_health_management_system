class FirebaseFieldNames {
  FirebaseFieldNames._();

  ///-- Users
  static const String username = 'username';
  static const String email = 'email';
  static const String phoneNumber = 'phone_number';
  static const String birthDay = 'birth_day';
  static const String gender = 'gender';
  static const String password = 'password';
  static const String friends = 'friends';
  static const String sentRequests = 'sent_requests';
  static const String receivedRequests = 'receivedRequests';
  static const String uid = 'uid';
  static const String profilePicture = 'profile_picture';

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
}
