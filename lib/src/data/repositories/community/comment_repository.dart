import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  final _storage = FirebaseStorage.instance;

  Future<String?> makeComment({
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
        postId: postId,
        content: content,
        createdAt: now,
        likes: const [],
        parentCommentId: null, // 这里不需要 parentCommentId
      );

      // 存入 `comments` 集合
      await _db
          .collection(FirebaseCollectionNames.comments)
          .doc(commentId)
          .set(comment.toJson());

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

  Future<String?> makeReply({
    required String content,
    required String parentCommentId,
  }) async {
    try {
      final replyId = const Uuid().v1();
      final authorId = _auth.currentUser!.uid;
      final now = DateTime.now();

      CommentModel reply = CommentModel(
        commentId: replyId,
        authorId: authorId,
        postId: null, // 回复不存 postId
        content: content,
        createdAt: now,
        likes: const [],
        parentCommentId: parentCommentId, // 标识属于哪个父评论
      );

      // 存入 `replies` 子集合
      await _db
          .collection(FirebaseCollectionNames.comments)
          .doc(parentCommentId)
          .collection(FirebaseCollectionNames.replies)
          .doc(replyId)
          .set(reply.toJson());

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

  /// Fetch comments
  Stream<List<CommentModel>> fetchComments(String postId) {
    return _db
        .collection(FirebaseCollectionNames.comments)
        .where(FirebaseFieldNames.postId, isEqualTo: postId)
        .orderBy(FirebaseFieldNames.createdAt, descending: true)
    // 监听这个集合的所有更改，并返回一个 Stream<QuerySnapshot>
        .snapshots() // 如果没有 .snapshots(): 那 .get() 只会获取一次数据，不会监听实时变化。
        .map((snapshot) {
      return snapshot.docs // 获取所有文档
          .map((doc) => CommentModel.fromSnapshot(doc)) // 将每个文档转换为 PostModel
          .toList();
    });
  }

  /// Fetch replies
  Stream<List<CommentModel>> fetchReplies(String parentCommentId) {
    return _db
        .collection(FirebaseCollectionNames.comments)
        .doc(parentCommentId) // 定位到父评论
        .collection(FirebaseCollectionNames.replies) // 进入 `replies` 子集合
        .orderBy(FirebaseFieldNames.createdAt, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CommentModel.fromSnapshot(doc))
          .toList();
    });
  }

  /// Like a comment
  Future<String?> likeDislikeComment({
    required String commentId,
    required List<String> likes,
    String? parentCommentId, // ✅ 用于区分评论还是回复
  }) async {
    try {
      final authorId = _auth.currentUser!.uid;

      // 确定 Firestore 路径
      DocumentReference commentRef;
      if (parentCommentId == null) {
        // 顶级评论（直接在 comments 集合）
        commentRef = _db.collection(FirebaseCollectionNames.comments).doc(commentId);
      } else {
        // 回复（在某个评论的 replies 子集合）
        commentRef = _db
            .collection(FirebaseCollectionNames.comments)
            .doc(parentCommentId)
            .collection(FirebaseCollectionNames.replies)
            .doc(commentId);
      }

      // 点赞或取消点赞
      if (likes.contains(authorId)) {
        // 取消点赞
        await commentRef.update({
          FirebaseFieldNames.likes: FieldValue.arrayRemove([authorId]),
        });
      } else {
        // 点赞
        await commentRef.update({
          FirebaseFieldNames.likes: FieldValue.arrayUnion([authorId]),
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

  Future<int> getReplyCount(String commentId) async {
    final snapshot = await _db
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .get();

    return snapshot.docs.length;
  }

  Future<void> updateCommentDetails(CommentModel updatedComment) async {
    try {
      await _db
          .collection(FirebaseCollectionNames.comments)
          .doc(updatedComment.commentId)
          .update(updatedComment.toJson());
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

  Future<void> updateSingleField({required String commentId, required Map<String, dynamic> json}) async {
    try {
      await _db.collection(FirebaseCollectionNames.comments).doc(commentId).update(json);
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

  Future<void> updateReplySingleField({required String replyId, required String parentCommentId, required Map<String, dynamic> json}) async {
    try {
      await _db
          .collection(FirebaseCollectionNames.comments)
          .doc(parentCommentId)
          .collection(FirebaseCollectionNames.replies)
          .doc(replyId).update(json);
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

  /// Function to remove comment and reply (if any) from Firestore
  Future<void> removeComment(String commentId) async {
    try {
      await _db.collection(FirebaseCollectionNames.comments).doc(commentId).delete();
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

  /// Function to remove comment and reply (if any) from Firestore
  Future<void> removeReply({required String parentCommentId, required String replyId}) async {
    try {
      await _db
          .collection(FirebaseCollectionNames.comments)
          .doc(parentCommentId)
          .collection(FirebaseCollectionNames.replies)
          .doc(replyId).delete();
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
}
