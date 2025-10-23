import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../features/community/models/post_model.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/firebase_collection_names.dart';
import '../../../utils/constants/firebase_field_names.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/exceptions/firebase_exceptions.dart';
import '../../../utils/exceptions/format_exceptions.dart';
import '../../../utils/exceptions/platform_exceptions.dart';

class PostRepository extends GetxController {
  static PostRepository get instance => Get.find();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;

  /// Upload multiple media files to Firebase Storage
  Future<List<String>> _uploadMediaFiles(List<File> mediaFiles) async {
    List<String> downloadUrls = [];

    for (File file in mediaFiles) {
      final fileExtension = file.path.split('.').last.toLowerCase();
      final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(fileExtension);
      final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileExtension);

      if (!isVideo && !isImage) continue;

      final fileName = const Uuid().v1();
      final folderPath = isVideo ? 'community/videos' : 'community/images';
      final storageRef = _storage.ref().child('$folderPath/$fileName.$fileExtension');

      final uploadTask = await storageRef.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      downloadUrls.add(downloadUrl);
    }

    return downloadUrls;
  }

  /// Create a new post with multiple media files
  Future<String?> createPost({
    required String content,
    required PostType postType,
    List<File>? mediaFiles,
  }) async {
    try {
      final postId = const Uuid().v1();
      final authorId = _auth.currentUser!.uid;
      final now = DateTime.now();

      // Upload media files if any
      List<String> mediaUrls = [];
      if (mediaFiles != null && mediaFiles.isNotEmpty) {
        mediaUrls = await _uploadMediaFiles(mediaFiles);
      }

      PostModel post = PostModel(
        postId: postId,
        posterId: authorId,
        postContent: content,
        postType: postType,
        mediaUrls: mediaUrls,
        likes: const [],
        commentCount: 0,
        isDisable: false,
        createdAt: now,
        updatedAt: now,
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

  /// Fetch posts with pagination and filtering
  Stream<List<PostModel>> fetchPosts({
    String? postType,
    int limit = 10,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection(FirebaseCollectionNames.posts)
        .orderBy(FirebaseFieldNames.createdAt, descending: true)
        .limit(limit);

    // Filter by post type if specified
    if (postType != null && postType != 'all') {
      query = query.where(FirebaseFieldNames.postType, isEqualTo: postType);
    }

    // Add pagination if startAfter is provided
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => PostModel.fromSnapshot(doc))
          .toList();
    });
  }

  /// Fetch posts by type (for video tab)
  Stream<List<PostModel>> fetchPostsByType(String postType, {int limit = 10}) {
    return _db
        .collection(FirebaseCollectionNames.posts)
        .where(FirebaseFieldNames.postType, isEqualTo: postType)
        .orderBy(FirebaseFieldNames.createdAt, descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PostModel.fromSnapshot(doc))
          .toList();
    });
  }

  /// Get posts that contain videos (new method - check mediaUrls)
  Stream<List<PostModel>> fetchVideoPosts({int limit = 10}) {
    return _db
        .collection(FirebaseCollectionNames.posts)
        .where(FirebaseFieldNames.mediaUrls, isNotEqualTo: [])
        .orderBy(FirebaseFieldNames.createdAt, descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PostModel.fromSnapshot(doc))
          .where((post) => post.mediaUrls.any((url) =>
      url.contains('community/videos') ||
          url.toLowerCase().contains('.mp4') ||
          url.toLowerCase().contains('.mov')))
          .toList();
    });
  }

  /// Toggle like on a post
  Future<String?> togglePostLike({
    required String postId,
    required List<String> currentLikes,
  }) async {
    try {
      final userId = _auth.currentUser!.uid;
      final postRef = _db.collection(FirebaseCollectionNames.posts).doc(postId);

      if (currentLikes.contains(userId)) {
        // Remove like
        await postRef.update({
          FirebaseFieldNames.likes: FieldValue.arrayRemove([userId]),
          FirebaseFieldNames.updatedAt: DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        // Add like
        await postRef.update({
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

  /// Update comment count for a post
  Future<void> updateCommentCount(String postId, int increment) async {
    try {
      await _db.collection(FirebaseCollectionNames.posts).doc(postId).update({
        FirebaseFieldNames.commentCount: FieldValue.increment(increment),
        FirebaseFieldNames.updatedAt: DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      // Silently handle error to avoid UI disruption
    }
  }

  /// Update post content
  Future<String?> updatePost({
    required String postId,
    required String content,
  }) async {
    try {
      await _db
          .collection(FirebaseCollectionNames.posts)
          .doc(postId)
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

  /// Update post with content, type, and media
  Future<String?> updatePostWithMedia({
    required String postId,
    required String content,
    required String postType,
    List<File>? newMediaFiles,
    List<String>? existingMediaUrls,
  }) async {
    try {
      // Upload new media files if any
      List<String> newMediaUrls = [];
      if (newMediaFiles != null && newMediaFiles.isNotEmpty) {
        newMediaUrls = await _uploadMediaFiles(newMediaFiles);
      }

      // Combine existing and new media URLs
      final allMediaUrls = [
        ...(existingMediaUrls ?? []),
        ...newMediaUrls,
      ];

      await _db
          .collection(FirebaseCollectionNames.posts)
          .doc(postId)
          .update({
        FirebaseFieldNames.postContent: content,
        FirebaseFieldNames.postType: postType,
        FirebaseFieldNames.mediaUrls: allMediaUrls,
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

  /// Delete post and its media files
  Future<String?> deletePost(String postId) async {
    try {
      // Get post to retrieve media URLs for deletion
      final postDoc = await _db.collection(FirebaseCollectionNames.posts).doc(postId).get();
      if (postDoc.exists) {
        final post = PostModel.fromSnapshot(postDoc);

        // Delete media files from storage
        for (String mediaUrl in post.mediaUrls) {
          try {
            final ref = _storage.refFromURL(mediaUrl);
            await ref.delete();
          } catch (e) {
            // Continue deletion even if some files can't be deleted
          }
        }
      }

      // Delete the post document
      await _db.collection(FirebaseCollectionNames.posts).doc(postId).delete();

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

  /// Get single post by ID
  Future<PostModel?> getPost(String postId) async {
    try {
      final doc = await _db.collection(FirebaseCollectionNames.posts).doc(postId).get();
      if (doc.exists) {
        return PostModel.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get posts count by type
  Future<Map<String, int>> getPostsCountByType() async {
    try {
      final snapshot = await _db.collection(FirebaseCollectionNames.posts).get();
      final counts = <String, int>{
        'all': snapshot.size,
        'general': 0,
        'tips': 0,
        'recipe': 0,
        'story': 0,
      };

      for (var doc in snapshot.docs) {
        final postType = doc.data()[FirebaseFieldNames.postType] as String? ?? 'general';
        counts[postType] = (counts[postType] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      return {'all': 0, 'general': 0, 'tips': 0, 'recipe': 0, 'story': 0};
    }
  }

  /// Fetch current user's posts with pagination and filtering
  Stream<List<PostModel>> fetchMyPosts({
    String? postType,
    bool? isDisabled,
    String? searchQuery,
    String sortBy = 'createdAt', // createdAt, likes, commentCount
    bool descending = true,
    int limit = 10,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    final userId = _auth.currentUser!.uid;

    Query<Map<String, dynamic>> query = _db
        .collection(FirebaseCollectionNames.posts)
        .where(FirebaseFieldNames.posterId, isEqualTo: userId);

    // Filter by post type
    if (postType != null && postType != 'all') {
      query = query.where(FirebaseFieldNames.postType, isEqualTo: postType);
    }

    // Filter by disabled status
    if (isDisabled != null) {
      query = query.where(FirebaseFieldNames.isDisable, isEqualTo: isDisabled);
    }

    // Apply sorting
    query = query.orderBy(sortBy, descending: descending).limit(limit);

    // Add pagination
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.snapshots().map((snapshot) {
      var posts = snapshot.docs
          .map((doc) => PostModel.fromSnapshot(doc))
          .toList();

      // Apply search filter if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        posts = posts.where((post) =>
            post.postContent.toLowerCase().contains(searchQuery.toLowerCase())
        ).toList();
      }

      return posts;
    });
  }

  /// Get my posts statistics
  Future<Map<String, dynamic>> getMyPostsStats() async {
    try {
      final userId = _auth.currentUser!.uid;
      final snapshot = await _db
          .collection(FirebaseCollectionNames.posts)
          .where(FirebaseFieldNames.posterId, isEqualTo: userId)
          .get();

      int totalPosts = snapshot.size;
      int activePosts = 0;
      int disabledPosts = 0;
      int totalLikes = 0;
      int totalComments = 0;
      Map<String, int> postsByType = {
        'general': 0,
        'tips': 0,
        'recipe': 0,
        'story': 0,
      };

      for (var doc in snapshot.docs) {
        final post = PostModel.fromSnapshot(doc);

        if (post.isDisable) {
          disabledPosts++;
        } else {
          activePosts++;
        }

        totalLikes += post.likes.length;
        totalComments += post.commentCount;

        postsByType[post.postType.name] = (postsByType[post.postType.name] ?? 0) + 1;
      }

      return {
        'totalPosts': totalPosts,
        'activePosts': activePosts,
        'disabledPosts': disabledPosts,
        'totalLikes': totalLikes,
        'totalComments': totalComments,
        'postsByType': postsByType,
      };
    } catch (e) {
      return {
        'totalPosts': 0,
        'activePosts': 0,
        'disabledPosts': 0,
        'totalLikes': 0,
        'totalComments': 0,
        'postsByType': {},
      };
    }
  }

  /// Toggle post disable status (enable/disable post)
  Future<String?> togglePostStatus(String postId, bool currentStatus) async {
    try {
      await _db
          .collection(FirebaseCollectionNames.posts)
          .doc(postId)
          .update({
        FirebaseFieldNames.isDisable: !currentStatus,
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
}