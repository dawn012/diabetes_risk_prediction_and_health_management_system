import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show immutable;

import '../../../utils/constants/firebase_field_names.dart';

@immutable
class CommentModel {
  final String commentId;
  final String authorId;
  final String? postId;
  final String text;
  final DateTime createdAt;
  final List<String> likes;
  final int replyCount;
  final String? parentCommentId; // ✅ reply 需要记录 parent commentId
  final List<String>? mentions; // 只有 reply 才有

  const CommentModel({
    required this.commentId,
    required this.authorId,
    this.postId,
    required this.text,
    required this.createdAt,
    required this.likes,
    this.replyCount = 0,
    this.parentCommentId,
    this.mentions,
  });

  // bool get isReply => parentCommentId != null;

  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.commentId: commentId,
      FirebaseFieldNames.authorId: authorId,
      if (postId != null) FirebaseFieldNames.postId: postId,  // ✅ 只有 comment 存
      FirebaseFieldNames.text: text,
      FirebaseFieldNames.createdAt: createdAt.millisecondsSinceEpoch,
      FirebaseFieldNames.likes: likes,
      FirebaseFieldNames.replyCount: replyCount,
      if (parentCommentId != null) FirebaseFieldNames.parentCommentId: parentCommentId,  // ✅ 只有 reply 存
      if (mentions != null) FirebaseFieldNames.mentions: mentions,  // ✅ 只有 reply 存
    };
  }

  factory CommentModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? {};
    return CommentModel(
      commentId: data[FirebaseFieldNames.commentId] ?? '',
      authorId: data[FirebaseFieldNames.authorId] ?? '',
      postId: data[FirebaseFieldNames.postId],
      text: data[FirebaseFieldNames.text] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        data[FirebaseFieldNames.createdAt] ?? 0,
      ),
      likes: List<String>.from(
        (data[FirebaseFieldNames.likes] ?? []),
      ),
      replyCount: (data[FirebaseFieldNames.replyCount] ?? 0) as int,
      parentCommentId: data[FirebaseFieldNames.parentCommentId],
      mentions: data.containsKey(FirebaseFieldNames.mentions)
          ? List<String>.from(data[FirebaseFieldNames.mentions])
          : null,
    );
  }
}
