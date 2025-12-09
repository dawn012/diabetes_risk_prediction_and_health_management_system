import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../features/community/models/reply_model.dart';
import '../../../utils/constants/firebase_collection_names.dart';
import '../../../utils/constants/firebase_field_names.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/exceptions/firebase_exceptions.dart';
import '../../../utils/exceptions/format_exceptions.dart';
import '../../../utils/exceptions/platform_exceptions.dart';

class ReplyRepository extends GetxController {
  static ReplyRepository get instance => Get.find();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Create a new reply in comments/{commentId}/replies subcollection
  Future<String> createReply({
    required String content,
    required String parentCommentId,
    List<String>? mentions,
  }) async {
    try {
      final replyId = const Uuid().v1();
      final authorId = _auth.currentUser!.uid;
      final now = DateTime.now();

      ReplyModel reply = ReplyModel(
        replyId: replyId,
        authorId: authorId,
        content: content,
        likes: const [],
        createdAt: now,
        updatedAt: now,
        mentions: mentions,
      );

      // Store reply in subcollection: comments/{parentCommentId}/replies/{replyId}
      await _db
          .collection(FirebaseCollectionNames.comments)
          .doc(parentCommentId)
          .collection(FirebaseCollectionNames.replies)
          .doc(replyId)
          .set(reply.toJson());

      // Increment reply count in parent comment
      await _db
          .collection(FirebaseCollectionNames.comments)
          .doc(parentCommentId)
          .update({
        FirebaseFieldNames.replyCount: FieldValue.increment(1),
      });

      return replyId;
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

  /// Fetch replies from comments/{parentCommentId}/replies subcollection
  Stream<List<ReplyModel>> fetchReplies({
    required String parentCommentId,
    int limit = 50,
  }) {
    return _db
        .collection(FirebaseCollectionNames.comments)
        .doc(parentCommentId)
        .collection(FirebaseCollectionNames.replies)
        // .orderBy(FirebaseFieldNames.createdAt, descending: false) // Replies show oldest first
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final replies = snapshot.docs
          .map((doc) => ReplyModel.fromSnapshot(doc))
          .toList();

      replies.sort((a, b) {
        final aTime = a.updatedAt.isAfter(a.createdAt) ? a.updatedAt : a.createdAt;
        final bTime = b.updatedAt.isAfter(b.createdAt) ? b.updatedAt : b.createdAt;
        return bTime.compareTo(aTime);
      });

      return replies;
    });
  }

  /// Like/unlike a reply in subcollection
  Future<void> toggleReplyLike({
    required String replyId,
    required String parentCommentId,
    required List<String> currentLikes,
  }) async {
    try {
      final userId = _auth.currentUser!.uid;
      final replyRef = _db
          .collection(FirebaseCollectionNames.comments)
          .doc(parentCommentId)
          .collection(FirebaseCollectionNames.replies)
          .doc(replyId);

      if (currentLikes.contains(userId)) {
        // Remove like
        await replyRef.update({
          FirebaseFieldNames.likes: FieldValue.arrayRemove([userId]),
        });
      } else {
        // Add like
        await replyRef.update({
          FirebaseFieldNames.likes: FieldValue.arrayUnion([userId]),
        });
      }
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

  /// Update reply content in subcollection
  Future<void> updateReply({
    required String replyId,
    required String parentCommentId,
    required String content,
  }) async {
    try {
      await _db
          .collection(FirebaseCollectionNames.comments)
          .doc(parentCommentId)
          .collection(FirebaseCollectionNames.replies)
          .doc(replyId)
          .update({
        FirebaseFieldNames.content: content,
        FirebaseFieldNames.updatedAt: DateTime.now().millisecondsSinceEpoch,
      });
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

  /// Delete reply from subcollection
  Future<void> deleteReply({
    required String replyId,
    required String parentCommentId,
  }) async {
    try {
      // Delete the reply document from subcollection
      await _db
          .collection(FirebaseCollectionNames.comments)
          .doc(parentCommentId)
          .collection(FirebaseCollectionNames.replies)
          .doc(replyId)
          .delete();

      // Decrement reply count in parent comment
      await _db
          .collection(FirebaseCollectionNames.comments)
          .doc(parentCommentId)
          .update({
        FirebaseFieldNames.replyCount: FieldValue.increment(-1),
      });
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

  /// Get reply count for a comment (from subcollection)
  Future<int> getReplyCount(String parentCommentId) async {
    try {
      final snapshot = await _db
          .collection(FirebaseCollectionNames.comments)
          .doc(parentCommentId)
          .collection(FirebaseCollectionNames.replies)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get replies sorted by likes (top replies) from subcollection
  Stream<List<ReplyModel>> fetchTopReplies({
    required String parentCommentId,
    int limit = 50,
  }) {
    return _db
        .collection(FirebaseCollectionNames.comments)
        .doc(parentCommentId)
        .collection(FirebaseCollectionNames.replies)
        .snapshots()
        .map((snapshot) {
      final replies = snapshot.docs
          .map((doc) => ReplyModel.fromSnapshot(doc))
          .toList();

      // Sort by likes count in descending order
      replies.sort((a, b) => b.likes.length.compareTo(a.likes.length));

      return replies.take(limit).toList();
    });
  }

  /// Batch delete all replies for a comment (when comment is deleted)
  Future<void> deleteAllRepliesForComment(String parentCommentId) async {
    try {
      final repliesSnapshot = await _db
          .collection(FirebaseCollectionNames.comments)
          .doc(parentCommentId)
          .collection(FirebaseCollectionNames.replies)
          .get();

      final batch = _db.batch();
      for (var doc in repliesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      // Silently handle error to avoid disrupting comment deletion
    }
  }
}