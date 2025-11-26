import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../../features/community/models/post_model.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/firebase_collection_names.dart';
import '../../../utils/constants/firebase_field_names.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/exceptions/firebase_exceptions.dart';
import '../../../utils/exceptions/format_exceptions.dart';
import '../../../utils/exceptions/platform_exceptions.dart';
import '../../../utils/helpers/image_helper.dart';
import '../../../utils/helpers/video_helper.dart';
import 'comment_repository.dart';
import 'post_report_repository.dart';

/// Paginated posts response model
class PaginatedPostsResponse {
  final List<PostModel> posts;
  final int totalCount;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;

  PaginatedPostsResponse({
    required this.posts,
    required this.totalCount,
    required this.hasMore,
    this.lastDocument,
  });
}

class PostRepository extends GetxController {
  static PostRepository get instance => Get.find();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;

  /// Fetch paginated posts with filters
  Future<PaginatedPostsResponse> fetchPaginatedPosts({
    required int page,
    required int itemsPerPage,
    String? postType,
    String? searchQuery,
    bool isDisable = false,
  }) async {
    try {
      // Build base query
      Query<Map<String, dynamic>> query = _db
          .collection(FirebaseCollectionNames.posts)
          .where(FirebaseFieldNames.isDisable, isEqualTo: isDisable)
          .orderBy(FirebaseFieldNames.updatedAt, descending: true);

      // Filter by post type
      if (postType != null && postType != 'all') {
        query = query.where(FirebaseFieldNames.postType, isEqualTo: postType);
      }

      // Get total count for this filter
      final countSnapshot = await query.count().get();
      final totalCount = countSnapshot.count ?? 0;

      // Calculate pagination
      final skipCount = (page - 1) * itemsPerPage;

      // Fetch documents with pagination
      QuerySnapshot<Map<String, dynamic>> snapshot;

      if (skipCount > 0) {
        // For non-first pages, we need to skip documents
        final skipSnapshot = await query.limit(skipCount).get();
        if (skipSnapshot.docs.isEmpty) {
          return PaginatedPostsResponse(
            posts: [],
            totalCount: totalCount,
            hasMore: false,
          );
        }

        snapshot = await query
            .startAfterDocument(skipSnapshot.docs.last)
            .limit(itemsPerPage)
            .get();
      } else {
        // First page
        snapshot = await query.limit(itemsPerPage).get();
      }

      var posts = snapshot.docs
          .map((doc) => PostModel.fromSnapshot(doc))
          .toList();

      // Apply search filter if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();

        // Get all unique poster IDs
        final posterIds = posts.map((p) => p.posterId).toSet().toList();

        // Fetch user data for all posters in parallel
        final userDocs = await Future.wait(
            posterIds.map((id) =>
                _db.collection(FirebaseCollectionNames.users).doc(id).get()
            )
        );

        // Create a map of userId to username
        final userMap = <String, String>{};
        for (var doc in userDocs) {
          if (doc.exists) {
            final data = doc.data();
            if (data != null) {
              userMap[doc.id] = (data[FirebaseFieldNames.username] ?? '')
                  .toString()
                  .toLowerCase();
            }
          }
        }

        // Filter posts by content or username
        posts = posts.where((post) {
          final contentMatch = post.postContent.toLowerCase().contains(lowerQuery);
          final usernameMatch = userMap[post.posterId]?.contains(lowerQuery) ?? false;
          final postIdMatch = post.postId.toLowerCase().contains(lowerQuery);
          return contentMatch || usernameMatch || postIdMatch;
        }).toList();
      }

      final hasMore = (page * itemsPerPage) < totalCount;

      return PaginatedPostsResponse(
        posts: posts,
        totalCount: totalCount,
        hasMore: hasMore,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      print('Error fetching paginated posts: $e');
      throw TTexts.commonErrorMessage;
    }
  }

  /// Stream to detect new posts (for banner notification)
  Stream<int> streamNewPostsCount({
    DateTime? since,
    String? postType,
    bool isDisable = false,
  }) {
    try {
      Query<Map<String, dynamic>> query = _db
          .collection(FirebaseCollectionNames.posts)
          .where(FirebaseFieldNames.isDisable, isEqualTo: isDisable);

      // Filter by post type
      if (postType != null && postType != 'all') {
        query = query.where(FirebaseFieldNames.postType, isEqualTo: postType);
      }

      // Filter by timestamp if provided
      if (since != null) {
        query = query.where(
          FirebaseFieldNames.createdAt,
          isGreaterThan: since.millisecondsSinceEpoch,
        );
      }

      return query.snapshots().map((snapshot) => snapshot.docs.length);
    } catch (e) {
      print('Error streaming new posts count: $e');
      return Stream.value(0);
    }
  }

  /// Get latest post timestamp (for new posts detection)
  Future<DateTime?> getLatestPostTimestamp({
    String? postType,
    bool isDisable = false,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _db
          .collection(FirebaseCollectionNames.posts)
          .where(FirebaseFieldNames.isDisable, isEqualTo: isDisable)
          .orderBy(FirebaseFieldNames.createdAt, descending: true)
          .limit(1);

      // Filter by post type
      if (postType != null && postType != 'all') {
        query = query.where(FirebaseFieldNames.postType, isEqualTo: postType);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) return null;

      final post = PostModel.fromSnapshot(snapshot.docs.first);
      return post.createdAt;
    } catch (e) {
      print('Error getting latest post timestamp: $e');
      return null;
    }
  }

  /// Upload multiple media files to Firebase Storage with thumbnails for videos
  Future<List<String>> _uploadMediaFiles(List<File> mediaFiles) async {
    List<String> downloadUrls = [];

    for (File file in mediaFiles) {
      try {
        final filePath = file.path;
        final fileExtension = path.extension(filePath).toLowerCase();
        final isVideo = VideoHelper.isVideoFile(filePath);
        final isImage = ImageHelper.isImageFile(filePath);

        if (!isVideo && !isImage) {
          continue;
        }

        final fileName = const Uuid().v4();

        if (isVideo) {
          try {
            final thumbnail = await VideoHelper.getVideoThumbnailFile(file);
            if (thumbnail != null && thumbnail.existsSync()) {
              final thumbPath = 'community/thumbnails/$fileName.webp';
              final thumbRef = _storage.ref().child(thumbPath);
              await thumbRef.putFile(thumbnail);

              print('Thumbnail uploaded successfully: $thumbPath');

              try {
                await thumbnail.delete();
              } catch (e) {
                print('Failed to delete temp thumbnail: $e');
              }
            } else {
              print('Thumbnail generation failed for video');
            }
          } catch (e) {
            print('Failed to upload thumbnail: $e');
          }

          final videoPath = 'community/videos/$fileName$fileExtension';
          final videoRef = _storage.ref().child(videoPath);
          final videoUpload = await videoRef.putFile(file);
          final videoUrl = await videoUpload.ref.getDownloadURL();
          downloadUrls.add(videoUrl);
        } else {
          final imagePath = 'community/images/$fileName$fileExtension';
          final imageRef = _storage.ref().child(imagePath);
          final imageUpload = await imageRef.putFile(file);
          final imageUrl = await imageUpload.ref.getDownloadURL();
          downloadUrls.add(imageUrl);
        }
      } catch (e) {
        print('Failed to upload file: $e');
      }
    }

    return downloadUrls;
  }

  /// Helper method to delete multiple media files from storage
  Future<void> _deleteMediaFiles(List<String> mediaUrls) async {
    try {
      for (String mediaUrl in mediaUrls) {
        try {
          final ref = _storage.refFromURL(mediaUrl);
          await ref.delete();

          if (mediaUrl.contains('/videos/')) {
            try {
              final fileName = _extractFileNameFromUrl(mediaUrl);
              if (fileName != null) {
                final thumbPath = 'community/thumbnails/$fileName.webp';
                final thumbRef = _storage.ref().child(thumbPath);
                await thumbRef.delete();
              }
            } catch (e) {
              print('Failed to delete thumbnail: $e');
            }
          }
        } catch (e) {
          print('Failed to delete media file: $mediaUrl, error: $e');
        }
      }
    } catch (e) {
      print('Error in _deleteMediaFiles: $e');
    }
  }

  /// Extract filename from Firebase Storage URL
  String? _extractFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      final oIndex = pathSegments.indexOf('o');
      if (oIndex != -1 && oIndex + 1 < pathSegments.length) {
        final encodedPath = pathSegments[oIndex + 1];
        final decodedPath = Uri.decodeComponent(encodedPath);
        final fileName = path.basenameWithoutExtension(decodedPath);
        return fileName;
      }

      return null;
    } catch (e) {
      print('Error extracting filename: $e');
      return null;
    }
  }

  /// Create a new post
  Future<String?> createPost({
    required String content,
    required PostType postType,
    List<File>? mediaFiles,
  }) async {
    try {
      final postId = const Uuid().v1();
      final authorId = _auth.currentUser!.uid;
      final now = DateTime.now();

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

  /// Toggle like on a post
  Future<String?> togglePostLike({
    required String postId,
    required List<String> currentLikes,
  }) async {
    try {
      final userId = _auth.currentUser!.uid;
      final postRef = _db.collection(FirebaseCollectionNames.posts).doc(postId);

      if (currentLikes.contains(userId)) {
        await postRef.update({
          FirebaseFieldNames.likes: FieldValue.arrayRemove([userId]),
          // FirebaseFieldNames.updatedAt: DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        await postRef.update({
          FirebaseFieldNames.likes: FieldValue.arrayUnion([userId]),
          // FirebaseFieldNames.updatedAt: DateTime.now().millisecondsSinceEpoch,
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
        // FirebaseFieldNames.updatedAt: DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      // Silently handle error
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
      print('🔄 Updating post: $postId');

      final currentPostDoc = await _db
          .collection(FirebaseCollectionNames.posts)
          .doc(postId)
          .get();

      if (!currentPostDoc.exists) {
        throw 'Post not found';
      }

      final currentPost = PostModel.fromSnapshot(currentPostDoc);
      final currentMediaUrls = currentPost.mediaUrls;
      print('📋 Current media: ${currentMediaUrls.length} files');

      List<String> newMediaUrls = [];
      if (newMediaFiles != null && newMediaFiles.isNotEmpty) {
        print('📤 Uploading ${newMediaFiles.length} new files...');
        newMediaUrls = await _uploadMediaFiles(newMediaFiles);
        print('✅ New media uploaded: ${newMediaUrls.length} files');
      }

      final allMediaUrls = [
        ...(existingMediaUrls ?? []),
        ...newMediaUrls,
      ];
      print('📊 Total media after update: ${allMediaUrls.length} files');

      final mediaUrlsToDelete = currentMediaUrls
          .where((url) => !allMediaUrls.contains(url))
          .toList();

      if (mediaUrlsToDelete.isNotEmpty) {
        print('🗑️ Deleting ${mediaUrlsToDelete.length} removed files...');
        await _deleteMediaFiles(mediaUrlsToDelete);
        print('✅ Removed files deleted');
      }

      await _db
          .collection(FirebaseCollectionNames.posts)
          .doc(postId)
          .update({
        FirebaseFieldNames.postContent: content,
        FirebaseFieldNames.postType: postType,
        FirebaseFieldNames.mediaUrls: allMediaUrls,
        FirebaseFieldNames.updatedAt: DateTime.now().millisecondsSinceEpoch,
      });

      print('✅ Post updated successfully');
      return null;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      print('❌ Error updating post: $e');
      throw TTexts.commonErrorMessage;
    }
  }

  /// Delete post and its media files and comments
  Future<String?> deletePost(String postId) async {
    try {
      print('🗑️ Deleting post: $postId');

      final postDoc = await _db.collection(FirebaseCollectionNames.posts).doc(postId).get();
      if (postDoc.exists) {
        final post = PostModel.fromSnapshot(postDoc);

        if (post.mediaUrls.isNotEmpty) {
          print('🗑️ Deleting ${post.mediaUrls.length} media files...');
          await _deleteMediaFiles(post.mediaUrls);
          print('✅ Media files deleted');
        }
      }

      final commentRepo = Get.put(CommentRepository());
      await commentRepo.deleteCommentsByPostId(postId);
      print('✅ Comments deleted');

      await _db.collection(FirebaseCollectionNames.posts).doc(postId).delete();
      print('✅ Post deleted successfully');

      return null;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      print('❌ Error deleting post: $e');
      throw TTexts.commonErrorMessage;
    }
  }

  /// Get single post by ID
  Future<PostModel?> getPost(String postId) async {
    try {
      final doc = await _db
          .collection(FirebaseCollectionNames.posts)
          .doc(postId)
          .get();

      if (doc.exists) {
        return PostModel.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      print('❌ Error getting post: $e');
      return null;
    }
  }

  /// Toggle post disable status
  Future<String?> togglePostStatus(String postId, bool currentStatus) async {
    try {
      await _db
          .collection(FirebaseCollectionNames.posts)
          .doc(postId)
          .update({
        FirebaseFieldNames.isDisable: !currentStatus,
        // FirebaseFieldNames.updatedAt: DateTime.now().millisecondsSinceEpoch,
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

  /// Enable post after user edits it
  Future<String?> enablePostAfterEdit(String postId) async {
    try {
      await _db
          .collection(FirebaseCollectionNames.posts)
          .doc(postId)
          .update({
        FirebaseFieldNames.isDisable: false,
        // FirebaseFieldNames.updatedAt: DateTime.now().millisecondsSinceEpoch,
      });

      // Resolve all pending reports for this post
      final reportRepo = Get.put(PostReportRepository());
      await reportRepo.resolveAllPendingReportsForPost(postId);

      return null;
    } on FirebaseException catch (e) {
      print('Error enabling post after edit: ${e.code}');
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      print('Error enabling post after edit: $e');
      throw TTexts.commonErrorMessage;
    }
  }

  // /// Upload multiple media files to Firebase Storage with thumbnails for videos
  // Future<List<String>> _uploadMediaFiles(List<File> mediaFiles) async {
  //   List<String> downloadUrls = [];
  //
  //   for (File file in mediaFiles) {
  //     try {
  //       final filePath = file.path;
  //       final fileExtension = path.extension(filePath).toLowerCase();
  //       final isVideo = VideoHelper.isVideoFile(filePath);
  //       final isImage = ImageHelper.isImageFile(filePath);
  //
  //       if (!isVideo && !isImage) {
  //         continue;
  //       }
  //
  //       final fileName = const Uuid().v4();
  //
  //       if (isVideo) {
  //         try {
  //           final thumbnail = await VideoHelper.getVideoThumbnailFile(file);
  //           if (thumbnail != null && thumbnail.existsSync()) {
  //             final thumbPath = 'community/thumbnails/$fileName.webp';
  //             final thumbRef = _storage.ref().child(thumbPath);
  //             await thumbRef.putFile(thumbnail);
  //
  //             print('Thumbnail uploaded successfully: $thumbPath');
  //
  //             // 清理临时缩略图文件
  //             try {
  //               await thumbnail.delete();
  //             } catch (e) {
  //               print('Failed to delete temp thumbnail: $e');
  //             }
  //           } else {
  //             print('Thumbnail generation failed for video');
  //           }
  //         } catch (e) {
  //           print('Failed to upload thumbnail: $e');
  //           // 不要因为缩略图失败而中断视频上传
  //         }
  //
  //         // 上传视频
  //         final videoPath = 'community/videos/$fileName$fileExtension';
  //         final videoRef = _storage.ref().child(videoPath);
  //         final videoUpload = await videoRef.putFile(file);
  //         final videoUrl = await videoUpload.ref.getDownloadURL();
  //         downloadUrls.add(videoUrl);
  //       } else {
  //         // 上传图片
  //         final imagePath = 'community/images/$fileName$fileExtension';
  //         final imageRef = _storage.ref().child(imagePath);
  //         final imageUpload = await imageRef.putFile(file);
  //         final imageUrl = await imageUpload.ref.getDownloadURL();
  //         downloadUrls.add(imageUrl);
  //       }
  //     } catch (e) {
  //       print('Failed to upload file: $e');
  //       // 继续处理其他文件
  //     }
  //   }
  //
  //   return downloadUrls;
  // }
  //
  // /// Helper method to delete multiple media files from storage (including thumbnails)
  // Future<void> _deleteMediaFiles(List<String> mediaUrls) async {
  //   try {
  //     for (String mediaUrl in mediaUrls) {
  //       try {
  //         // 删除主文件
  //         final ref = _storage.refFromURL(mediaUrl);
  //         await ref.delete();
  //
  //         // 如果是视频，同时删除缩略图
  //         if (mediaUrl.contains('/videos/')) {
  //           try {
  //             // 从视频URL提取文件名（不含扩展名）
  //             final fileName = _extractFileNameFromUrl(mediaUrl);
  //             if (fileName != null) {
  //               final thumbPath = 'community/thumbnails/$fileName.webp';
  //
  //               final thumbRef = _storage.ref().child(thumbPath);
  //               await thumbRef.delete();
  //             }
  //           } catch (e) {
  //             print('Failed to delete thumbnail (might not exist): $e');
  //             // 缩略图可能不存在，不影响主流程
  //           }
  //         }
  //       } catch (e) {
  //         print('Failed to delete media file: $mediaUrl, error: $e');
  //       }
  //     }
  //   } catch (e) {
  //     print('Error in _deleteMediaFiles: $e');
  //   }
  // }
  //
  // /// Extract filename (without extension) from Firebase Storage URL
  // String? _extractFileNameFromUrl(String url) {
  //   try {
  //     // Firebase Storage URL 格式:
  //     // https://firebasestorage.googleapis.com/v0/b/.../o/community%2Fvideos%2Ffilename.mp4?alt=...
  //
  //     final uri = Uri.parse(url);
  //     final pathSegments = uri.pathSegments;
  //
  //     // 找到 'o' 后面的路径
  //     final oIndex = pathSegments.indexOf('o');
  //     if (oIndex != -1 && oIndex + 1 < pathSegments.length) {
  //       // 获取编码的路径 (e.g., "community%2Fvideos%2Ffilename.mp4")
  //       final encodedPath = pathSegments[oIndex + 1];
  //       // 解码
  //       final decodedPath = Uri.decodeComponent(encodedPath);
  //       // 提取文件名（不含扩展名）
  //       final fileName = path.basenameWithoutExtension(decodedPath);
  //       return fileName;
  //     }
  //
  //     return null;
  //   } catch (e) {
  //     print('Error extracting filename: $e');
  //     return null;
  //   }
  // }
  //
  // /// Create a new post with multiple media files
  // Future<String?> createPost({
  //   required String content,
  //   required PostType postType,
  //   List<File>? mediaFiles,
  // }) async {
  //   try {
  //     final postId = const Uuid().v1();
  //     final authorId = _auth.currentUser!.uid;
  //     final now = DateTime.now();
  //
  //     // Upload media files if any
  //     List<String> mediaUrls = [];
  //     if (mediaFiles != null && mediaFiles.isNotEmpty) {
  //       mediaUrls = await _uploadMediaFiles(mediaFiles);
  //     }
  //
  //     PostModel post = PostModel(
  //       postId: postId,
  //       posterId: authorId,
  //       postContent: content,
  //       postType: postType,
  //       mediaUrls: mediaUrls,
  //       likes: const [],
  //       commentCount: 0,
  //       isDisable: false,
  //       createdAt: now,
  //       updatedAt: now,
  //     );
  //
  //     await _db
  //         .collection(FirebaseCollectionNames.posts)
  //         .doc(postId)
  //         .set(post.toJson());
  //
  //     return null;
  //   } on FirebaseException catch (e) {
  //     throw TFirebaseException(e.code).message;
  //   } on FormatException catch (_) {
  //     throw const TFormatException();
  //   } on PlatformException catch (e) {
  //     throw TPlatformException(e.code).message;
  //   } catch (e) {
  //     throw TTexts.commonErrorMessage;
  //   }
  // }

  /// Fetch posts with pagination, filtering, and search
  Stream<List<PostModel>> fetchPosts({
    String? postType,
    String? searchQuery,
    bool isDisable = false,
    int limit = 10,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection(FirebaseCollectionNames.posts)
        .where(FirebaseFieldNames.isDisable, isEqualTo: isDisable)
        .orderBy(FirebaseFieldNames.createdAt, descending: true);

    // Filter by post type
    if (postType != null && postType != 'all') {
      query = query.where(FirebaseFieldNames.postType, isEqualTo: postType);
    }

    // Add pagination
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(limit);

    return query.snapshots().asyncMap((snapshot) async {
      var posts = snapshot.docs
          .map((doc) => PostModel.fromSnapshot(doc))
          .toList();

      // Client-side search filtering for both content and username
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();

        // Get all unique poster IDs
        final posterIds = posts.map((p) => p.posterId).toSet().toList();

        // Fetch user data for all posters in parallel
        final userDocs = await Future.wait(
            posterIds.map((id) =>
                _db.collection(FirebaseCollectionNames.users).doc(id).get()
            )
        );

        // Create a map of userId to username
        final userMap = <String, String>{};
        for (var doc in userDocs) {
          if (doc.exists) {
            final data = doc.data();
            if (data != null) {
              userMap[doc.id] = (data[FirebaseFieldNames.username] ?? '')
                  .toString()
                  .toLowerCase();
            }
          }
        }

        // Filter posts by content or username
        posts = posts.where((post) {
          final contentMatch = post.postContent.toLowerCase().contains(lowerQuery);
          final usernameMatch = userMap[post.posterId]?.contains(lowerQuery) ?? false;
          return contentMatch || usernameMatch;
        }).toList();
      }

      return posts;
    });
  }

  /// 获取新帖子数量
  Future<int> getNewPostsCount(String afterPostId) async {
    try {
      final postDoc = await _db
          .collection(FirebaseCollectionNames.posts)
          .doc(afterPostId)
          .get();

      if (!postDoc.exists) return 0;

      final timestamp = postDoc.data()?[FirebaseFieldNames.createdAt] ?? 0;

      final snapshot = await _db
          .collection(FirebaseCollectionNames.posts)
          .where(FirebaseFieldNames.isDisable, isEqualTo: false)
          .where(FirebaseFieldNames.createdAt, isGreaterThan: timestamp)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
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

  // /// Toggle like on a post
  // Future<String?> togglePostLike({
  //   required String postId,
  //   required List<String> currentLikes,
  // }) async {
  //   try {
  //     final userId = _auth.currentUser!.uid;
  //     final postRef = _db.collection(FirebaseCollectionNames.posts).doc(postId);
  //
  //     if (currentLikes.contains(userId)) {
  //       await postRef.update({
  //         FirebaseFieldNames.likes: FieldValue.arrayRemove([userId]),
  //         FirebaseFieldNames.updatedAt: DateTime.now().millisecondsSinceEpoch,
  //       });
  //     } else {
  //       await postRef.update({
  //         FirebaseFieldNames.likes: FieldValue.arrayUnion([userId]),
  //         FirebaseFieldNames.updatedAt: DateTime.now().millisecondsSinceEpoch,
  //       });
  //     }
  //
  //     return null;
  //   } on FirebaseException catch (e) {
  //     throw TFirebaseException(e.code).message;
  //   } on FormatException catch (_) {
  //     throw const TFormatException();
  //   } on PlatformException catch (e) {
  //     throw TPlatformException(e.code).message;
  //   } catch (e) {
  //     throw TTexts.commonErrorMessage;
  //   }
  // }
  //
  // /// Update comment count for a post
  // Future<void> updateCommentCount(String postId, int increment) async {
  //   try {
  //     await _db.collection(FirebaseCollectionNames.posts).doc(postId).update({
  //       FirebaseFieldNames.commentCount: FieldValue.increment(increment),
  //       FirebaseFieldNames.updatedAt: DateTime.now().millisecondsSinceEpoch,
  //     });
  //   } catch (e) {
  //     // Silently handle error
  //   }
  // }

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

  // /// Update post with content, type, and media
  // Future<String?> updatePostWithMedia({
  //   required String postId,
  //   required String content,
  //   required String postType,
  //   List<File>? newMediaFiles,
  //   List<String>? existingMediaUrls,
  // }) async {
  //   try {
  //     print('🔄 Updating post: $postId');
  //
  //     // Get current post
  //     final currentPostDoc = await _db
  //         .collection(FirebaseCollectionNames.posts)
  //         .doc(postId)
  //         .get();
  //
  //     if (!currentPostDoc.exists) {
  //       throw 'Post not found';
  //     }
  //
  //     final currentPost = PostModel.fromSnapshot(currentPostDoc);
  //     final currentMediaUrls = currentPost.mediaUrls;
  //     print('📋 Current media: ${currentMediaUrls.length} files');
  //
  //     // Upload new media files
  //     List<String> newMediaUrls = [];
  //     if (newMediaFiles != null && newMediaFiles.isNotEmpty) {
  //       print('📤 Uploading ${newMediaFiles.length} new files...');
  //       newMediaUrls = await _uploadMediaFiles(newMediaFiles);
  //       print('✅ New media uploaded: ${newMediaUrls.length} files');
  //     }
  //
  //     // Combine media URLs
  //     final allMediaUrls = [
  //       ...(existingMediaUrls ?? []),
  //       ...newMediaUrls,
  //     ];
  //     print('📊 Total media after update: ${allMediaUrls.length} files');
  //
  //     // Delete removed media files
  //     final mediaUrlsToDelete = currentMediaUrls
  //         .where((url) => !allMediaUrls.contains(url))
  //         .toList();
  //
  //     if (mediaUrlsToDelete.isNotEmpty) {
  //       print('🗑️ Deleting ${mediaUrlsToDelete.length} removed files...');
  //       await _deleteMediaFiles(mediaUrlsToDelete);
  //       print('✅ Removed files deleted');
  //     }
  //
  //     // Update post in Firestore
  //     await _db
  //         .collection(FirebaseCollectionNames.posts)
  //         .doc(postId)
  //         .update({
  //       FirebaseFieldNames.postContent: content,
  //       FirebaseFieldNames.postType: postType,
  //       FirebaseFieldNames.mediaUrls: allMediaUrls,
  //       FirebaseFieldNames.updatedAt: DateTime.now().millisecondsSinceEpoch,
  //     });
  //
  //     print('✅ Post updated successfully');
  //     return null;
  //   } on FirebaseException catch (e) {
  //     throw TFirebaseException(e.code).message;
  //   } on FormatException catch (_) {
  //     throw const TFormatException();
  //   } on PlatformException catch (e) {
  //     throw TPlatformException(e.code).message;
  //   } catch (e) {
  //     print('❌ Error updating post: $e');
  //     throw TTexts.commonErrorMessage;
  //   }
  // }
  //
  // /// Delete post and its media files and comments
  // Future<String?> deletePost(String postId) async {
  //   try {
  //     print('🗑️ Deleting post: $postId');
  //
  //     // Get post to retrieve media URLs
  //     final postDoc = await _db.collection(FirebaseCollectionNames.posts).doc(postId).get();
  //     if (postDoc.exists) {
  //       final post = PostModel.fromSnapshot(postDoc);
  //
  //       if (post.mediaUrls.isNotEmpty) {
  //         print('🗑️ Deleting ${post.mediaUrls.length} media files...');
  //         await _deleteMediaFiles(post.mediaUrls);
  //         print('✅ Media files deleted');
  //       }
  //     }
  //
  //     // Delete all comments
  //     final commentRepo = Get.put(CommentRepository());
  //     await commentRepo.deleteCommentsByPostId(postId);
  //     print('✅ Comments deleted');
  //
  //     // Delete post document
  //     await _db.collection(FirebaseCollectionNames.posts).doc(postId).delete();
  //     print('✅ Post deleted successfully');
  //
  //     return null;
  //   } on FirebaseException catch (e) {
  //     throw TFirebaseException(e.code).message;
  //   } on FormatException catch (_) {
  //     throw const TFormatException();
  //   } on PlatformException catch (e) {
  //     throw TPlatformException(e.code).message;
  //   } catch (e) {
  //     print('❌ Error deleting post: $e');
  //     throw TTexts.commonErrorMessage;
  //   }
  // }

  /// 🆕 Fetch more posts for pagination (non-streaming)
  Future<List<PostModel>?> fetchMorePosts({
    required String lastPostId,
    String? postType,
    String? searchQuery,
    int limit = 10,
  }) async {
    try {
      // 获取最后一个帖子的文档快照
      final lastDoc = await _db
          .collection(FirebaseCollectionNames.posts)
          .doc(lastPostId)
          .get();

      if (!lastDoc.exists) {
        return null;
      }

      // 构建查询
      Query<Map<String, dynamic>> query = _db
          .collection(FirebaseCollectionNames.posts)
          .where(FirebaseFieldNames.isDisable, isEqualTo: false)
          .orderBy(FirebaseFieldNames.createdAt, descending: true);

      // Filter by post type
      if (postType != null && postType != 'all') {
        query = query.where(FirebaseFieldNames.postType, isEqualTo: postType);
      }

      // 从最后一个文档之后开始
      query = query.startAfterDocument(lastDoc).limit(limit);

      // 获取快照
      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      var posts = snapshot.docs
          .map((doc) => PostModel.fromSnapshot(doc))
          .toList();

      // 应用搜索过滤（如果有）
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();

        // Get all unique poster IDs
        final posterIds = posts.map((p) => p.posterId).toSet().toList();

        // Fetch user data for all posters in parallel
        final userDocs = await Future.wait(
            posterIds.map((id) =>
                _db.collection(FirebaseCollectionNames.users).doc(id).get()
            )
        );

        // Create a map of userId to username
        final userMap = <String, String>{};
        for (var doc in userDocs) {
          if (doc.exists) {
            final data = doc.data();
            if (data != null) {
              userMap[doc.id] = (data[FirebaseFieldNames.username] ?? '')
                  .toString()
                  .toLowerCase();
            }
          }
        }

        // Filter posts by content or username
        posts = posts.where((post) {
          final contentMatch = post.postContent.toLowerCase().contains(lowerQuery);
          final usernameMatch = userMap[post.posterId]?.contains(lowerQuery) ?? false;
          return contentMatch || usernameMatch;
        }).toList();
      }

      return posts;
    } catch (e) {
      print('❌ Error fetching more posts: $e');
      return null;
    }
  }

  // /// 🆕 Get single post by ID (already exists, but ensure it's there)
  // Future<PostModel?> getPost(String postId) async {
  //   try {
  //     final doc = await _db
  //         .collection(FirebaseCollectionNames.posts)
  //         .doc(postId)
  //         .get();
  //
  //     if (doc.exists) {
  //       return PostModel.fromSnapshot(doc);
  //     }
  //     return null;
  //   } catch (e) {
  //     print('❌ Error getting post: $e');
  //     return null;
  //   }
  // }

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

  /// Fetch current user's posts with pagination, filtering, and search
  Stream<List<PostModel>> fetchMyPosts({
    String? postType,
    bool? isDisabled,
    String? searchQuery,
    String sortBy = 'createdAt',
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

    // Apply sorting - convert field names to Firebase field names
    String sortField;
    switch (sortBy) {
      case 'updatedAt':
        sortField = FirebaseFieldNames.updatedAt;
        break;
      case 'likes':
        sortField = FirebaseFieldNames.likes;
        break;
      case 'commentCount':
        sortField = FirebaseFieldNames.commentCount;
        break;
      case 'createdAt':
      default:
        sortField = FirebaseFieldNames.createdAt;
        break;
    }

    query = query.orderBy(sortField, descending: descending);

    // Add pagination
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(limit);

    return query.snapshots().map((snapshot) {
      var posts = snapshot.docs
          .map((doc) => PostModel.fromSnapshot(doc))
          .toList();

      // Apply search filter if provided (search by post content only for my posts)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        posts = posts.where((post) =>
            post.postContent.toLowerCase().contains(lowerQuery)
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

  // /// Toggle post disable status (enable/disable post)
  // Future<String?> togglePostStatus(String postId, bool currentStatus) async {
  //   try {
  //     await _db
  //         .collection(FirebaseCollectionNames.posts)
  //         .doc(postId)
  //         .update({
  //       FirebaseFieldNames.isDisable: !currentStatus,
  //       FirebaseFieldNames.updatedAt: DateTime.now().millisecondsSinceEpoch,
  //     });
  //
  //     return null;
  //   } on FirebaseException catch (e) {
  //     throw TFirebaseException(e.code).message;
  //   } on FormatException catch (_) {
  //     throw const TFormatException();
  //   } on PlatformException catch (e) {
  //     throw TPlatformException(e.code).message;
  //   } catch (e) {
  //     throw TTexts.commonErrorMessage;
  //   }
  // }
  //
  // /// Enable post after user edits it
  // /// This automatically sets isDisable to false when user successfully edits their post
  // Future<String?> enablePostAfterEdit(String postId) async {
  //   try {
  //     await _db
  //         .collection(FirebaseCollectionNames.posts)
  //         .doc(postId)
  //         .update({
  //       FirebaseFieldNames.isDisable: false,
  //       FirebaseFieldNames.updatedAt: DateTime.now().millisecondsSinceEpoch,
  //     });
  //
  //     return null;
  //   } on FirebaseException catch (e) {
  //     print('Error enabling post after edit: ${e.code}');
  //     throw TFirebaseException(e.code).message;
  //   } on FormatException catch (_) {
  //     throw const TFormatException();
  //   } on PlatformException catch (e) {
  //     throw TPlatformException(e.code).message;
  //   } catch (e) {
  //     print('Error enabling post after edit: $e');
  //     throw TTexts.commonErrorMessage;
  //   }
  // }

  /// Download media files from Firebase Storage URLs
  Future<List<File>> _downloadMediaFiles(List<String> mediaUrls) async {
    List<File> downloadedFiles = [];

    for (String url in mediaUrls) {
      try {
        final file = await _downloadMediaFile(url);
        if (file != null) {
          downloadedFiles.add(file);
        }
      } catch (e) {
        print('Failed to download media from $url: $e');
        // Continue with other files even if one fails
      }
    }

    return downloadedFiles;
  }

  /// Download single media file from URL
  Future<File?> _downloadMediaFile(String mediaUrl) async {
    try {
      // Create a temporary file
      final tempDir = Directory.systemTemp;
      final fileName = mediaUrl.split('/').last;
      final tempFile = File('${tempDir.path}/$fileName');

      // Get reference from URL
      final ref = _storage.refFromURL(mediaUrl);

      // Download the file
      await ref.writeToFile(tempFile);

      return tempFile;
    } catch (e) {
      print('Error downloading media file: $e');
      return null;
    }
  }

  /// Get existing post with downloaded media files
  Future<PostModel?> getPostWithMedia(String postId) async {
    try {
      final doc = await _db.collection(FirebaseCollectionNames.posts).doc(postId).get();
      if (doc.exists) {
        final post = PostModel.fromSnapshot(doc);

        // Download media files if any
        if (post.mediaUrls.isNotEmpty) {
          // Note: We'll handle the downloaded files separately
          // since we can't store them in the PostModel
          return post;
        }
        return post;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}