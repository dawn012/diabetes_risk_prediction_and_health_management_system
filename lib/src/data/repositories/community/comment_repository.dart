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
        FirebaseFieldNames.postId: postId,
      });

      await _db
          .collection(FirebaseCollectionNames.posts)
          .doc(postId)
          .update({
        FirebaseFieldNames.commentCount: FieldValue.increment(1),
        FirebaseFieldNames.updatedAt: now.millisecondsSinceEpoch,
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
      // 1. First get the comment document to retrieve the postId
      final commentDoc = await _db
          .collection(FirebaseCollectionNames.comments)
          .doc(commentId)
          .get();

      if (!commentDoc.exists) {
        throw 'Comment not found';
      }

      final commentData = commentDoc.data();
      final postId = commentData?[FirebaseFieldNames.postId] as String?;

      if (postId == null || postId.isEmpty) {
        throw 'Post ID not found in comment';
      }

      // 2. Use batch operation to ensure atomicity
      final batch = _db.batch();

      // Delete comment document
      final commentRef = _db
          .collection(FirebaseCollectionNames.comments)
          .doc(commentId);
      batch.delete(commentRef);

      // Update post's comment count (-1)
      final postRef = _db
          .collection(FirebaseCollectionNames.posts)
          .doc(postId);
      batch.update(postRef, {
        FirebaseFieldNames.commentCount: FieldValue.increment(-1),
        FirebaseFieldNames.updatedAt: DateTime.now().millisecondsSinceEpoch,
      });

      // Commit the batch operation
      await batch.commit();

      print('✅ Comment deleted and post comment count decremented');
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

  /// Delete all comments for a post
  Future<void> deleteCommentsByPostId(String postId) async {
    try {
      // Get all comments for this post
      final commentsSnapshot = await _db
          .collection(FirebaseCollectionNames.comments)
          .where(FirebaseFieldNames.postId, isEqualTo: postId)
          .get();

      // Delete all comments in batch
      final batch = _db.batch();
      for (final doc in commentsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      print('Deleted ${commentsSnapshot.docs.length} comments for post $postId');
    } catch (e) {
      print('Error deleting comments for post $postId: $e');
      // Don't throw here to allow caller to handle gracefully
    }
  }

  /// Delete all comments for a post (recursive batch version for large datasets)
  Future<void> deleteCommentsByPostIdRecursive(String postId) async {
    try {
      await _deleteCommentsBatch(postId);
    } catch (e) {
      print('Error deleting comments for post $postId: $e');
    }
  }

  /// Recursively delete comments in batches
  Future<void> _deleteCommentsBatch(String postId, {DocumentSnapshot? startAfter}) async {
    Query<Map<String, dynamic>> query = _db
        .collection(FirebaseCollectionNames.comments)
        .where(FirebaseFieldNames.postId, isEqualTo: postId)
        .limit(500); // Firestore batch limit

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isEmpty) return;

    // Delete this batch
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    print('Deleted batch of ${snapshot.docs.length} comments for post $postId');

    // If there are more comments, delete next batch
    if (snapshot.docs.length == 500) {
      final lastDoc = snapshot.docs.last;
      await _deleteCommentsBatch(postId, startAfter: lastDoc);
    }
  }
}