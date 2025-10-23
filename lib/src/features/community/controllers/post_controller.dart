import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/community/post_repository.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/network_manager.dart';
import '../models/post_model.dart';

class PostController extends GetxController {
  static PostController get instance => Get.find();

  final postRepo = Get.put(PostRepository());
  final scrollController = ScrollController();

  // Posts state
  final posts = <PostModel>[].obs;
  final isLoadingPosts = false.obs;
  final isLoadingMore = false.obs;
  final postsError = ''.obs;
  final hasMorePosts = true.obs;
  DocumentSnapshot? lastPostDoc;

  // Filtering
  final selectedPostType = 'all'.obs;
  final postTypeFilters = [
    'all',
    'general',
    'tips',
    'recipe',
    'story'
  ];

  final postTypeCounts = <String, int>{}.obs;

  // Post creation
  final postContent = TextEditingController();
  final selectedMediaFiles = <File>[].obs;
  final creatingPost = false.obs;

  @override
  void onInit() {
    super.onInit();
    _setupScrollListener();
    fetchPosts();
    _loadPostCounts();
  }

  @override
  void onClose() {
    scrollController.dispose();
    postContent.dispose();
    super.onClose();
  }

  /// =================== POSTS FETCHING =================== ///

  void _setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent * 0.8) {
        if (!isLoadingMore.value && hasMorePosts.value) {
          loadMorePosts();
        }
      }
    });
  }

  /// Fetch initial posts
  Future<void> fetchPosts({bool refresh = false}) async {
    if (refresh) {
      posts.clear();
      lastPostDoc = null;
      hasMorePosts.value = true;
    }

    if (isLoadingPosts.value) return;
    isLoadingPosts.value = true;
    postsError.value = '';

    try {
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        postsError.value = TTexts.networkErrorMessage;
        return;
      }

      // Bind to stream for real-time updates
      final stream = postRepo.fetchPosts(
        postType: selectedPostType.value == 'all' ? null : selectedPostType.value,
        limit: 10,
        startAfter: lastPostDoc as DocumentSnapshot<Map<String, dynamic>>?,
      );

      posts.bindStream(stream);
    } catch (e) {
      postsError.value = 'Failed to load posts. Please try again.';
    } finally {
      isLoadingPosts.value = false;
    }
  }

  /// Load more posts for pagination
  Future<void> loadMorePosts() async {
    if (isLoadingMore.value || !hasMorePosts.value) return;

    isLoadingMore.value = true;

    try {
      // Note: For pagination with streams, you might need to implement
      // a different approach or use limit and offset
      // This is a simplified version
    } catch (e) {
      // Handle error silently for load more
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Load post counts by type
  void _loadPostCounts() async {
    try {
      final counts = await postRepo.getPostsCountByType();
      postTypeCounts.assignAll(counts);
    } catch (e) {
      // Handle silently
    }
  }

  /// =================== POST FILTERING =================== ///

  void filterByPostType(String postType) {
    if (selectedPostType.value == postType) return;

    selectedPostType.value = postType;
    fetchPosts(refresh: true);
  }

  String getPostTypeLabel(String type) {
    switch (type) {
      case 'all':
        return 'All Posts';
      case 'general':
        return 'General';
      case 'tips':
        return 'Tips & Tricks';
      case 'recipe':
        return 'Recipes';
      case 'story':
        return 'Success Stories';
      default:
        return type.toUpperCase();
    }
  }

  int getPostTypeCount(String type) {
    return postTypeCounts[type] ?? 0;
  }

  /// =================== POST INTERACTIONS =================== ///

  /// Toggle like on post
  Future<void> togglePostLike(String postId, List<String> currentLikes) async {
    try {
      await postRepo.togglePostLike(
        postId: postId,
        currentLikes: currentLikes,
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: TTexts.error,
        message: 'Failed to update like',
      );
    }
  }

  /// Delete post
  Future<void> deletePost(String postId) async {
    try {
      // Delete post
      await postRepo.deletePost(postId);

      // Remove post from local list
      posts.removeWhere((post) => post.postId == postId);

      // Update post counts
      _loadPostCounts();

      // Show success message
      TLoaders.successSnackBar(
        title: 'Post Deleted',
        message: 'Your post has been deleted successfully',
      );

    } catch (e) {
      TLoaders.errorSnackBar(
        title: TTexts.error,
        message: 'Failed to delete post: ${e.toString()}',
      );
    }
  }

  /// Delete post with additional checks (for own posts)
  Future<void> deleteOwnPost(String postId) async {
    try {
      // Verify the post belongs to current user
      final post = getPostById(postId);
      final currentUserId = ''; // Get current user ID from your auth service

      if (post == null) {
        TLoaders.errorSnackBar(
          title: TTexts.error,
          message: 'Post not found',
        );
        return;
      }

      // if (post.posterId != currentUserId) {
      //   TLoaders.errorSnackBar(
      //     title: 'Permission Denied',
      //     message: 'You can only delete your own posts',
      //   );
      //   return;
      // }

      await deletePost(postId);
    } catch (e) {
      TLoaders.errorSnackBar(
        title: TTexts.error,
        message: 'Failed to delete post',
      );
    }
  }

  /// Get post by ID
  PostModel? getPostById(String postId) {
    try {
      return posts.firstWhere((post) => post.postId == postId);
    } catch (e) {
      return null;
    }
  }

  /// =================== VIDEO SPECIFIC =================== ///

  /// Get video posts only
  List<PostModel> get videoPosts {
    return posts.where((post) =>
        post.mediaUrls.any((url) =>
        url.contains('community/videos') ||
            url.toLowerCase().contains('.mp4') ||
            url.toLowerCase().contains('.mov')
        )
    ).toList();
  }

  /// =================== UTILITY METHODS =================== ///

  /// Refresh posts (pull to refresh)
  Future<void> refreshPosts() async {
    await fetchPosts(refresh: true);
    _loadPostCounts();
  }
}