import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show immutable;

import '../../../utils/constants/firebase_field_names.dart';

@immutable
class PostModel {
  final String postId;
  final String posterId;
  final String postContent;
  final String postType;
  final String mediaFiles;
  final DateTime createdAt;
  final List<String> likes;

  const PostModel({
    required this.postId,
    required this.posterId,
    required this.postContent,
    required this.postType,
    required this.mediaFiles,
    required this.createdAt,
    required this.likes,
  });

  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.postId: postId,
      FirebaseFieldNames.posterId: posterId,
      FirebaseFieldNames.postContent: postContent,
      FirebaseFieldNames.mediaFiles: mediaFiles,
      FirebaseFieldNames.createdAt: createdAt.millisecondsSinceEpoch,
      FirebaseFieldNames.likes: likes,
      FirebaseFieldNames.postType: postType,
    };
  }

  factory PostModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? {}; // 确保 data 不为空
    return PostModel(
      postId: data[FirebaseFieldNames.postId] ?? '',
      posterId: data[FirebaseFieldNames.posterId] ?? '',
      postContent: data[FirebaseFieldNames.postContent] ?? '',
      postType: data[FirebaseFieldNames.postType] ?? '',
      mediaFiles: data[FirebaseFieldNames.mediaFiles] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        data[FirebaseFieldNames.createdAt] ?? 0,
      ),
      likes: List<String>.from(
        (data[FirebaseFieldNames.likes] ?? []),
      ),
    );
  }
}
