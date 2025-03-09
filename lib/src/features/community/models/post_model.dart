import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show immutable;

import '../../../utils/constants/firebase_field_names.dart';

@immutable
class PostModel {
  final String postId;
  final String posterId;
  final String content;
  final String postType;
  final String fileUrl;
  final DateTime createdAt;
  final List<String> likes;

  const PostModel({
    required this.postId,
    required this.posterId,
    required this.content,
    required this.postType,
    required this.fileUrl,
    required this.createdAt,
    required this.likes,
  });

  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.postId: postId,
      FirebaseFieldNames.posterId: posterId,
      FirebaseFieldNames.content: content,
      FirebaseFieldNames.fileUrl: fileUrl,
      FirebaseFieldNames.datePublished: createdAt.millisecondsSinceEpoch,
      FirebaseFieldNames.likes: likes,
      FirebaseFieldNames.postType: postType,
    };
  }

  factory PostModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? {}; // 确保 data 不为空
    return PostModel(
      postId: data[FirebaseFieldNames.postId] ?? '',
      posterId: data[FirebaseFieldNames.posterId] ?? '',
      content: data[FirebaseFieldNames.content] ?? '',
      postType: data[FirebaseFieldNames.postType] ?? '',
      fileUrl: data[FirebaseFieldNames.fileUrl] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        data[FirebaseFieldNames.datePublished] ?? 0,
      ),
      likes: List<String>.from(
        (data[FirebaseFieldNames.likes] ?? []),
      ),
    );
  }
}
