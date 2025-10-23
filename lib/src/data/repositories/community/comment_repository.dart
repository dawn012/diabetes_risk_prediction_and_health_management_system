import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../features/community/models/comment_model.dart';
import '../../../utils/constants/firebase_collection_names.dart';
import '../../../utils/constants/firebase_field_names.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/exceptions/firebase_exceptions.dart';
import '../../../utils/exceptions/format_exceptions.dart';
import '../../../utils/exceptions/platform_exceptions.dart';

class CommentRepository extends GetxController {
  static CommentRepository get instance => Get.find();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Create a new comment
  Future<String?> createComment({
    required String content,
    required String postId,
  }) async {
    try {
      final commentId = const Uuid().v1();
      final authorId = _auth.currentUser!.uid;
      final now = DateTime.now();

      CommentModel comment = CommentModel(
        commentId: commentId,
        authorId: authorId,
        content: content,
        likes: const [],
        replyCount: 0,
        createdAt: now,
        updatedAt: now,
      );

      // Store in comments collection with postId
      await _db
          .collection(FirebaseCollectionNames.comments)
          .doc(commentId)
          .set({
        ...comment.toJson(),
        FirebaseFieldNames.postId: postId, // Add postId for Firestore querying
      });

      return null;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Fetch comments for a post with pagination
  Stream<List<CommentModel>> fetchComments({
    required String postId,
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection(FirebaseCollectionNames.comments)
        .where(FirebaseFieldNames.postId, isEqualTo: postId)
        .orderBy(FirebaseFieldNames.createdAt, descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CommentModel.fromSnapshot(doc))
          .toList();
    });
  }

  /// Get comment count for a post
  Future<int> getCommentCount(String postId) async {
    try {
      final snapshot = await _db
          .collection(FirebaseCollectionNames.comments)
          .where(FirebaseFieldNames.postId, isEqualTo: postId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Like/unlike a comment
  Future<String?> toggleCommentLike({
    required String commentId,
    required List<String> currentLikes,
  }) async {
    try {
      final userId = _auth.currentUser!.uid;
      final commentRef = _db.collection(FirebaseCollectionNames.comments).doc(commentId);

      if (currentLikes.contains(userId)) {
        // Remove like
        await commentRef.update({
          FirebaseFieldNames.likes: FieldValue.arrayRemove([userId]),
          FirebaseFieldNames.updatedAt: DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        // Add like
        await commentRef.update({
          FirebaseFieldNames.likes: FieldValue.arrayUnion([userId]),
          FirebaseFieldNames.updatedAt: DateTime.now().millisecondsSinceEpoch,
        });
      }

      return null;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Update comment content
  Future<String?> updateComment({
    required String commentId,
    required String content,
  }) async {
    try {
      await _db
          .collection(FirebaseCollectionNames.comments)
          .doc(commentId)
          .update({
        FirebaseFieldNames.content: content,
        FirebaseFieldNames.updatedAt: DateTime.now().millisecondsSinceEpoch,
      });

      return null;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Delete comment
  Future<String?> deleteComment(String commentId) async {
    try {
      // Delete the comment document
      await _db.collection(FirebaseCollectionNames.comments).doc(commentId).delete();

      return null;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Get comments sorted by likes (top comments)
  Stream<List<CommentModel>> fetchTopComments({
    required String postId,
    int limit = 20,
  }) {
    return _db
        .collection(FirebaseCollectionNames.comments)
        .where(FirebaseFieldNames.postId, isEqualTo: postId)
        .snapshots()
        .map((snapshot) {
      final comments = snapshot.docs
          .map((doc) => CommentModel.fromSnapshot(doc))
          .toList();

      // Sort by likes count in descending order
      comments.sort((a, b) => b.likes.length.compareTo(a.likes.length));

      return comments.take(limit).toList();
    });
  }

  /// Update reply count for a comment
  Future<void> updateReplyCount(String commentId, int increment) async {
    try {
      await _db.collection(FirebaseCollectionNames.comments).doc(commentId).update({
        FirebaseFieldNames.replyCount: FieldValue.increment(increment),
        FirebaseFieldNames.updatedAt: DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      // Silently handle error to avoid UI disruption
    }
  }
}