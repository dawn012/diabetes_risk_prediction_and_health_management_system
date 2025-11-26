import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/firebase_field_names.dart';
import 'comment_model.dart';

class PostModel {
  final String postId;
  final String posterId;
  final String postContent;
  final PostType postType;
  final List<String> mediaUrls; // Support multiple media files
  final List<String> likes;
  final List<CommentModel>? comments; // Nested comments
  final int commentCount;
  final bool isDisable;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int pendingReportCount; // Number of pending reports
  final DateTime? latestReportTime; // Time of most recent report

  const PostModel({
    required this.postId,
    required this.posterId,
    required this.postContent,
    required this.postType,
    required this.mediaUrls,
    required this.likes,
    this.comments,
    required this.commentCount,
    required this.isDisable,
    required this.createdAt,
    required this.updatedAt,
    this.pendingReportCount = 0,
    this.latestReportTime,
  });

  /// Empty constructor for initialization
  factory PostModel.empty() => PostModel(
    postId: '',
    posterId: '',
    postContent: '',
    postType: PostType.general, // 改为枚举默认值
    mediaUrls: const [],
    likes: const [],
    comments: const [],
    commentCount: 0,
    isDisable: false,
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    pendingReportCount: 0,
    latestReportTime: DateTime.fromMillisecondsSinceEpoch(0),
  );

  /// Create a copy of the model with updated fields
  PostModel copyWith({
    String? postId,
    String? posterId,
    String? postContent,
    PostType? postType, // 改为 PostType?
    List<String>? mediaUrls,
    List<String>? likes,
    List<CommentModel>? comments,
    int? commentCount,
    bool? isDisable,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? pendingReportCount,
    DateTime? latestReportTime
  }) {
    return PostModel(
      postId: postId ?? this.postId,
      posterId: posterId ?? this.posterId,
      postContent: postContent ?? this.postContent,
      postType: postType ?? this.postType, // 现在类型匹配
      mediaUrls: mediaUrls ?? this.mediaUrls,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      commentCount: commentCount ?? this.commentCount,
      isDisable: isDisable ?? this.isDisable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingReportCount: pendingReportCount ?? this.pendingReportCount,
      latestReportTime: latestReportTime ?? this.latestReportTime,
    );
  }

  /// Convert model to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.postId: postId,
      FirebaseFieldNames.posterId: posterId,
      FirebaseFieldNames.postContent: postContent,
      FirebaseFieldNames.postType: postType.name, // 存储枚举的 name
      FirebaseFieldNames.mediaUrls: mediaUrls,
      FirebaseFieldNames.likes: likes,
      FirebaseFieldNames.commentCount: commentCount,
      FirebaseFieldNames.isDisable: isDisable,
      FirebaseFieldNames.createdAt: createdAt.millisecondsSinceEpoch,
      FirebaseFieldNames.updatedAt: updatedAt.millisecondsSinceEpoch,
      FirebaseFieldNames.pendingReportCount: pendingReportCount,
      FirebaseFieldNames.latestReportTime: latestReportTime?.millisecondsSinceEpoch,
      // Comments are stored as subcollection, not included in main document
    };
  }

  /// Create model from Firestore document
  factory PostModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? {};
    return PostModel(
      postId: data[FirebaseFieldNames.postId] ?? '',
      posterId: data[FirebaseFieldNames.posterId] ?? '',
      postContent: data[FirebaseFieldNames.postContent] ?? '',
      postType: _parsePostType(data[FirebaseFieldNames.postType]), // 解析为枚举
      mediaUrls: List<String>.from(data[FirebaseFieldNames.mediaUrls] ?? []),
      likes: List<String>.from(data[FirebaseFieldNames.likes] ?? []),
      comments: const [], // Comments loaded separately from subcollection
      commentCount: data[FirebaseFieldNames.commentCount] ?? 0,
      isDisable: data[FirebaseFieldNames.isDisable] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          data[FirebaseFieldNames.createdAt] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
          data[FirebaseFieldNames.updatedAt] ?? 0),
      pendingReportCount: data[FirebaseFieldNames.pendingReportCount] ?? 0,
      latestReportTime: DateTime.fromMillisecondsSinceEpoch(
          data[FirebaseFieldNames.latestReportTime] ?? 0),
    );
  }

  /// Helper method to parse string to PostType enum
  static PostType _parsePostType(dynamic typeData) {
    if (typeData == null) return PostType.general;

    final typeString = typeData.toString();
    return PostType.values.firstWhere(
          (type) => type.name == typeString,
      orElse: () => PostType.general,
    );
  }

  /// Get display name for post type
  String get postTypeDisplayName => postType.displayName;

  @override
  String toString() {
    return 'PostModel{postId: $postId, postType: ${postType.displayName}, likesCount: ${likes.length}, commentsCount: ${comments?.length}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostModel && other.postId == postId;
  }

  @override
  int get hashCode => postId.hashCode;
}