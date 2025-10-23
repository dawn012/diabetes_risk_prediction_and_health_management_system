import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/constants/firebase_field_names.dart';
import 'reply_model.dart';

class CommentModel {
  final String commentId;
  final String authorId;
  final String content;
  final List<String> likes;
  final List<ReplyModel>? replies; // Nested replies
  final int replyCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CommentModel({
    required this.commentId,
    required this.authorId,
    required this.content,
    required this.likes,
    this.replies,
    this.replyCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Empty constructor
  factory CommentModel.empty() => CommentModel(
    commentId: '',
    authorId: '',
    content: '',
    likes: const [],
    replies: const [],
    replyCount: 0,
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  /// Create a copy with updated fields
  CommentModel copyWith({
    String? commentId,
    String? authorId,
    String? content,
    List<String>? likes,
    List<ReplyModel>? replies,
    int? replyCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommentModel(
      commentId: commentId ?? this.commentId,
      authorId: authorId ?? this.authorId,
      content: content ?? this.content,
      likes: likes ?? this.likes,
      replies: replies ?? this.replies,
      replyCount: replyCount ?? this.replyCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.commentId: commentId,
      FirebaseFieldNames.authorId: authorId,
      FirebaseFieldNames.content: content,
      FirebaseFieldNames.likes: likes,
      FirebaseFieldNames.replyCount: replyCount,
      FirebaseFieldNames.createdAt: createdAt.millisecondsSinceEpoch,
      FirebaseFieldNames.updatedAt: updatedAt.millisecondsSinceEpoch,
      // Replies stored as subcollection
    };
  }

  /// Create from Firestore document
  factory CommentModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? {};
    return CommentModel(
      commentId: data[FirebaseFieldNames.commentId] ?? document.id, // Use document ID if commentId not stored
      authorId: data[FirebaseFieldNames.authorId] ?? '',
      content: data[FirebaseFieldNames.content] ?? '',
      likes: List<String>.from(data[FirebaseFieldNames.likes] ?? []),
      replyCount: data[FirebaseFieldNames.replyCount] ?? 0,
      replies: null, // Loaded separately from subcollection
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          data[FirebaseFieldNames.createdAt] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
          data[FirebaseFieldNames.updatedAt] ?? 0),
    );
  }

  @override
  String toString() {
    return 'CommentModel{commentId: $commentId, authorId: $authorId, replyCount: $replyCount}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommentModel && other.commentId == commentId;
  }

  @override
  int get hashCode => commentId.hashCode;
}