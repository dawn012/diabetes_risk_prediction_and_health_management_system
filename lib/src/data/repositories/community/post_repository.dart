import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diabetes_risk_prediction_and_health_management_system/src/utils/constants/firebase_collection_names.dart';
import 'package:diabetes_risk_prediction_and_health_management_system/src/utils/constants/firebase_field_names.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../features/community/models/post_model.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/exceptions/firebase_exceptions.dart';
import '../../../utils/exceptions/format_exceptions.dart';
import '../../../utils/exceptions/platform_exceptions.dart';

class PostRepository extends GetxController {
  static PostRepository get instance => Get.find();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;

  /// Make Post
  Future<String?> makePost({
    required String content,
    required File file,
    required String postType,
  }) async {
    try {
      final postId = const Uuid().v1();
      final posterId = _auth.currentUser!.uid;
      final now = DateTime.now();

      // Post file to storage
      final fileUid = const Uuid().v1();
      // _storage.ref(postType)	访问根目录下的 postType 目录（如果不存在会自动创建）
      // .child(fileUid)	在 postType 目录下创建一个子路径，文件名是 fileUid
      final path = _storage.ref(postType).child(fileUid); // 存储路径
      final taskSnapshot = await path.putFile(file); // 上传文件去到该路径
      final downloadUrl = await taskSnapshot.ref.getDownloadURL(); // 获取下载链接

      // Create our community
      PostModel post = PostModel(
        postId: postId,
        posterId: posterId,
        content: content,
        postType: postType,
        fileUrl: downloadUrl,
        createdAt: now,
        likes: const [],
      );

      await _db
          .collection(FirebaseCollectionNames.posts)
          .doc(postId)
          .set(post.toJson());

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

  /// Fetch posts
  Stream<List<PostModel>> fetchPosts() {
    return _db
        .collection(FirebaseCollectionNames.posts)
        .orderBy(FirebaseFieldNames.datePublished, descending: true)
        // 监听这个集合的所有更改，并返回一个 Stream<QuerySnapshot>
        .snapshots() // 如果没有 .snapshots(): 那 .get() 只会获取一次数据，不会监听实时变化。
        .map((snapshot) {
      return snapshot.docs // 获取所有文档
          .map((doc) => PostModel.fromSnapshot(doc)) // 将每个文档转换为 PostModel
          .toList();
    });
  }

  /// Like a community
  Future<String?> likeDislikePost({
    required String postId,
    required List<String> likes,
  }) async {
    try {
      final authorId = _auth.currentUser!.uid;

      if (likes.contains(authorId)) {
        // We already liked the community
        _db.collection(FirebaseCollectionNames.posts).doc(postId).update({
          FirebaseFieldNames.likes: FieldValue.arrayRemove([authorId])
          // Remove the user from likes
        });
      } else {
        // We need to like the community
        _db.collection(FirebaseCollectionNames.posts).doc(postId).update({
          FirebaseFieldNames.likes: FieldValue.arrayUnion([authorId])
          // Add likes (without duplication)
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

  /// Fetch videos
  Stream<List<PostModel>> fetchVideos() {
    return _db
        .collection(FirebaseCollectionNames.posts)
        .where(FirebaseFieldNames.postType, isEqualTo: 'video')
        .orderBy(FirebaseFieldNames.datePublished, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PostModel.fromSnapshot(doc)).toList();
    });
  }
}
