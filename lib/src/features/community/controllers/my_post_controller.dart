import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/community/post_repository.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/network_manager.dart';
import '../models/post_model.dart';

class MyPostController extends GetxController {
  static MyPostController get instance => Get.find();

  final postRepo = PostRepository.instance;
  final scrollController = ScrollController();
  final searchController = TextEditingController();

  // Posts state
  final myPosts = <PostModel>[].obs;
  final isLoadingPosts = false.obs;
  final isLoadingMore = false.obs;
  final hasMorePosts = true.obs;
  DocumentSnapshot? lastPostDoc;

  // Statistics
  final stats = <String, dynamic>{}.obs;
  final isLoadingStats = false.obs;

  // Filtering & Sorting
  final selectedPostType = 'all'.obs;
  final selectedStatus = 'all'.obs; // all, active, disabled
  final searchQuery = ''.obs;
  final sortBy = 'createdAt'.obs; // createdAt, likes, commentCount
  final sortDescending = true.obs;

  final postTypeFilters = ['all', 'general', 'tips', 'recipe', 'story'];
  final statusFilters = ['all', 'active', 'disabled'];
  final sortOptions = [
    {'value': 'createdAt', 'label': 'Date Created'},
    {'value': 'updatedAt', 'label': 'Last Updated'},
    {'value': 'likes', 'label': 'Likes'},
    {'value': 'commentCount', 'label': 'Comments'},
  ];

  @override
  void onInit() {
    super.onInit();
    _setupScrollListener();
    fetchMyPosts();
    loadStats();
  }

  @override
  void onClose() {
    scrollController.dispose();
    searchController.dispose();
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

  Future<void> fetchMyPosts({bool refresh = false}) async {
    if (refresh) {
      myPosts.clear();
      lastPostDoc = null;
      hasMorePosts.value = true;
    }

    if (isLoadingPosts.value) return;
    isLoadingPosts.value = true;

    try {
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TLoaders.warningSnackBar(
          title: 'No Connection',
          message: TTexts.networkErrorMessage,
        );
        return;
      }

      final stream = postRepo.fetchMyPosts(
        postType: selectedPostType.value == 'all' ? null : selectedPostType.value,
        isDisabled: _getDisabledFilter(),
        searchQuery: searchQuery.value.isEmpty ? null : searchQuery.value,
        sortBy: sortBy.value,
        descending: sortDescending.value,
        limit: 10,
        startAfter: lastPostDoc as DocumentSnapshot<Map<String, dynamic>>?,
      );

      myPosts.bindStream(stream);
    } catch (e) {
      TLoaders.errorSnackBar(
        title: TTexts.error,
        message: 'Failed to load posts: ${e.toString()}',
      );
    } finally {
      isLoadingPosts.value = false;
    }
  }

  Future<void> loadMorePosts() async {
    if (isLoadingMore.value || !hasMorePosts.value) return;
    isLoadingMore.value = true;

    try {
      // Implement pagination logic here if needed
    } catch (e) {
      // Handle error silently
    } finally {
      isLoadingMore.value = false;
    }
  }

  bool? _getDisabledFilter() {
    switch (selectedStatus.value) {
      case 'active':
        return false;
      case 'disabled':
        return true;
      default:
        return null;
    }
  }

  /// =================== STATISTICS =================== ///

  Future<void> loadStats() async {
    isLoadingStats.value = true;
    try {
      final fetchedStats = await postRepo.getMyPostsStats();
      stats.assignAll(fetchedStats);
    } catch (e) {
      // Handle silently
    } finally {
      isLoadingStats.value = false;
    }
  }

  /// =================== FILTERING & SORTING =================== ///

  void filterByPostType(String postType) {
    if (selectedPostType.value == postType) return;
    selectedPostType.value = postType;
    fetchMyPosts(refresh: true);
  }

  void filterByStatus(String status) {
    if (selectedStatus.value == status) return;
    selectedStatus.value = status;
    fetchMyPosts(refresh: true);
  }

  void updateSortBy(String newSortBy) {
    if (sortBy.value == newSortBy) {
      // Toggle sort direction
      sortDescending.value = !sortDescending.value;
    } else {
      sortBy.value = newSortBy;
      sortDescending.value = true;
    }
    fetchMyPosts(refresh: true);
  }

  void performSearch(String query) {
    searchQuery.value = query;
    fetchMyPosts(refresh: true);
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    fetchMyPosts(refresh: true);
  }

  void resetFilters() {
    selectedPostType.value = 'all';
    selectedStatus.value = 'all';
    sortBy.value = 'createdAt';
    sortDescending.value = true;
    clearSearch();
    fetchMyPosts(refresh: true);
  }

  /// =================== POST ACTIONS =================== ///

  Future<void> togglePostStatus(PostModel post) async {
    try {
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TLoaders.warningSnackBar(
          title: 'No Connection',
          message: TTexts.networkErrorMessage,
        );
        return;
      }

      await postRepo.togglePostStatus(post.postId, post.isDisable);

      TLoaders.successSnackBar(
        title: 'Success',
        message: post.isDisable
            ? 'Post has been enabled'
            : 'Post has been disabled',
      );

      fetchMyPosts(refresh: true);
      loadStats();
    } catch (e) {
      TLoaders.errorSnackBar(
        title: TTexts.error,
        message: 'Failed to update post status',
      );
    }
  }

  Future<void> deletePost(PostModel post) async {
    try {
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TLoaders.warningSnackBar(
          title: 'No Connection',
          message: TTexts.networkErrorMessage,
        );
        return;
      }

      await postRepo.deletePost(post.postId);

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Post deleted successfully',
      );

      fetchMyPosts(refresh: true);
      loadStats();
    } catch (e) {
      TLoaders.errorSnackBar(
        title: TTexts.error,
        message: 'Failed to delete post',
      );
    }
  }

  /// =================== UTILITY METHODS =================== ///

  Future<void> refreshPosts() async {
    await fetchMyPosts(refresh: true);
    await loadStats();
  }

  String getPostTypeLabel(String type) {
    switch (type) {
      case 'all':
        return 'All Types';
      case 'general':
        return 'General';
      case 'tips':
        return 'Tips';
      case 'recipe':
        return 'Recipes';
      case 'story':
        return 'Stories';
      default:
        return type.toUpperCase();
    }
  }

  String getStatusLabel(String status) {
    switch (status) {
      case 'all':
        return 'All Posts';
      case 'active':
        return 'Active';
      case 'disabled':
        return 'Disabled';
      default:
        return status.toUpperCase();
    }
  }

  int getPostTypeCount(String type) {
    final postsByType = stats['postsByType'] as Map<String, int>?;
    if (postsByType == null) return 0;

    if (type == 'all') {
      return postsByType.values.fold(0, (sum, count) => sum + count);
    }

    return postsByType[type] ?? 0;
  }
}