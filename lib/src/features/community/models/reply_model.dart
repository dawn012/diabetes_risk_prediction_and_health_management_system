import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/constants/firebase_field_names.dart';

class ReplyModel {
  final String replyId;
  final String authorId;
  final String content;
  final List<String> likes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String>? mentions; // Optional: for @username mentions

  const ReplyModel({
    required this.replyId,
    required this.authorId,
    required this.content,
    required this.likes,
    required this.createdAt,
    required this.updatedAt,
    this.mentions,
  });

  /// Empty constructor
  factory ReplyModel.empty() => ReplyModel(
    replyId: '',
    authorId: '',
    content: '',
    likes: const [],
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    mentions: const [],
  );

  /// Create a copy with updated fields
  ReplyModel copyWith({
    String? replyId,
    String? authorId,
    String? content,
    List<String>? likes,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? mentions,
  }) {
    return ReplyModel(
      replyId: replyId ?? this.replyId,
      authorId: authorId ?? this.authorId,
      content: content ?? this.content,
      likes: likes ?? this.likes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mentions: mentions ?? this.mentions,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.replyId: replyId,
      FirebaseFieldNames.authorId: authorId,
      FirebaseFieldNames.content: content,
      FirebaseFieldNames.likes: likes,
      FirebaseFieldNames.createdAt: createdAt.millisecondsSinceEpoch,
      FirebaseFieldNames.updatedAt: updatedAt.millisecondsSinceEpoch,
      if (mentions != null) FirebaseFieldNames.mentions: mentions,
    };
  }

  /// Create from Firestore document
  factory ReplyModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? {};
    return ReplyModel(
      replyId: data[FirebaseFieldNames.replyId] ?? document.id,
      authorId: data[FirebaseFieldNames.authorId] ?? '',
      content: data[FirebaseFieldNames.content] ?? '',
      likes: List<String>.from(data[FirebaseFieldNames.likes] ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          data[FirebaseFieldNames.createdAt] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
          data[FirebaseFieldNames.updatedAt] ?? 0),
      mentions: data.containsKey(FirebaseFieldNames.mentions)
          ? List<String>.from(data[FirebaseFieldNames.mentions])
          : null,
    );
  }

  @override
  String toString() {
    return 'ReplyModel{replyId: $replyId, authorId: $authorId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReplyModel && other.replyId == replyId;
  }

  @override
  int get hashCode => replyId.hashCode;
}