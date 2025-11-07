import 'dart:async';
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
  final searchController = TextEditingController();

  // Posts state
  final posts = <PostModel>[].obs;
  final isLoadingPosts = false.obs;
  final isLoadingMore = false.obs;
  final postsError = ''.obs;
  final hasMorePosts = true.obs;
  DocumentSnapshot? lastPostDoc;

  // Stream subscription for real-time updates
  StreamSubscription<List<PostModel>>? _postsSubscription;

  // 🆕 用于跟踪哪些帖子是在当前会话中加载的（用于实时更新时保留disabled状态）
  final Set<String> _sessionPostIds = {};

  // New posts banner
  final hasNewPosts = false.obs;
  final newPostsCount = 0.obs;
  Timer? _refreshTimer;

  // Filtering & Search
  final selectedPostType = 'all'.obs;
  final searchQuery = ''.obs;
  final postTypeFilters = ['all', 'general', 'tips', 'recipe', 'story'];
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
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    print('🔄 Starting periodic post check...');
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
          (timer) => _checkForNewPosts(),
    );
    _checkForNewPosts();
  }

  Future<void> _checkForNewPosts() async {
    print('🔍 Checking for new posts...');
    if (posts.isEmpty) {
      print('❌ No posts to check against');
      return;
    }

    try {
      final currentLatestId = posts.first.postId;
      print('📝 Current latest post ID: $currentLatestId');

      final count = await postRepo.getNewPostsCount(currentLatestId);
      print('📊 New posts count: $count');

      if (count > 0) {
        newPostsCount.value = count;
        hasNewPosts.value = true;
        print('✅ Found $count new posts');
      } else {
        print('ℹ️ No new posts');
      }
    } catch (e) {
      print('❌ Error checking for new posts: $e');
    }
  }

  Future<void> loadNewPosts() async {
    hasNewPosts.value = false;
    newPostsCount.value = 0;
    await fetchPosts(refresh: true);
  }

  void dismissNewPostsBanner() {
    hasNewPosts.value = false;
    newPostsCount.value = 0;
  }

  @override
  void onClose() {
    print('🛑 Stopping auto refresh timer');
    _refreshTimer?.cancel();
    _postsSubscription?.cancel();
    scrollController.dispose();
    postContent.dispose();
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

  Future<void> fetchPosts({bool refresh = false}) async {
    if (refresh) {
      // 🆕 刷新时清除会话ID缓存
      _sessionPostIds.clear();
      _postsSubscription?.cancel();
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
        isLoadingPosts.value = false;
        return;
      }

      final stream = postRepo.fetchPosts(
        postType: selectedPostType.value == 'all' ? null : selectedPostType.value,
        searchQuery: searchQuery.value.isEmpty ? null : searchQuery.value,
        isDisable: false,
        limit: 10,
        startAfter: null,
      );

      _postsSubscription = stream.listen(
            (newPosts) {
          if (refresh || posts.isEmpty) {
            // 首次加载或刷新时，直接替换
            posts.assignAll(newPosts);
            // 🆕 记录所有初始加载的帖子ID
            _sessionPostIds.addAll(newPosts.map((p) => p.postId));
          } else {
            // 实时更新：合并新数据
            _mergePostsRealtime(newPosts);
          }

          hasMorePosts.value = newPosts.length >= 10;
          isLoadingPosts.value = false;
        },
        onError: (error) {
          print('❌ Error in posts stream: $error');
          postsError.value = 'Failed to load posts. Please try again.';
          isLoadingPosts.value = false;
        },
      );
    } catch (e) {
      print('❌ Error fetching posts: $e');
      postsError.value = 'Failed to load posts. Please try again.';
      isLoadingPosts.value = false;
    }
  }

  /// 🆕 实时合并帖子数据 - 处理禁用状态
  void _mergePostsRealtime(List<PostModel> newPosts) {
    for (var newPost in newPosts) {
      final index = posts.indexWhere((p) => p.postId == newPost.postId);
      if (index != -1) {
        // 更新现有帖子（保持位置不变）
        posts[index] = newPost;
      } else {
        // 这是真正的新帖子，但不要自动添加
        print('📨 Detected truly new post: ${newPost.postId}');
      }
    }

    // 🆕 检查是否有帖子被禁用了（存在于会话中但不在新数据中）
    final newPostIds = newPosts.map((p) => p.postId).toSet();

    for (var i = 0; i < posts.length; i++) {
      final post = posts[i];

      // 如果这个帖子是在当前会话中加载的，但现在查询结果中没有了
      // 说明它可能被禁用了
      if (_sessionPostIds.contains(post.postId) && !newPostIds.contains(post.postId)) {
        // 🆕 检查这个帖子是否真的被禁用了
        _checkAndUpdateDisabledPost(post.postId, i);
      }
    }
  }

  /// 🆕 检查并更新被禁用的帖子（通过 Repository）
  Future<void> _checkAndUpdateDisabledPost(String postId, int index) async {
    try {
      // 🔄 使用 Repository 获取帖子状态
      final updatedPost = await postRepo.getPost(postId);

      if (updatedPost != null && updatedPost.isDisable) {
        print('⚠️ Post $postId is now disabled, updating in place');
        posts[index] = updatedPost;
      }
    } catch (e) {
      print('❌ Error checking disabled post: $e');
    }
  }

  Future<void> loadMorePosts() async {
    if (isLoadingMore.value || !hasMorePosts.value || posts.isEmpty) return;
    isLoadingMore.value = true;

    try {
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        isLoadingMore.value = false;
        return;
      }

      // 🔄 使用 Repository 进行分页加载
      final lastPost = posts.last;
      final result = await postRepo.fetchMorePosts(
        lastPostId: lastPost.postId,
        postType: selectedPostType.value == 'all' ? null : selectedPostType.value,
        searchQuery: searchQuery.value.isEmpty ? null : searchQuery.value,
        limit: 10,
      );

      if (result == null || result.isEmpty) {
        hasMorePosts.value = false;
      } else {
        // 🆕 记录新加载的帖子ID
        _sessionPostIds.addAll(result.map((p) => p.postId));

        // 添加到现有列表
        posts.addAll(result);

        // 检查是否还有更多
        hasMorePosts.value = result.length >= 10;
      }
    } catch (e) {
      print('❌ Error loading more posts: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  void _loadPostCounts() async {
    try {
      final counts = await postRepo.getPostsCountByType();
      postTypeCounts.assignAll(counts);
    } catch (e) {
      // Handle silently
    }
  }

  /// =================== POST FILTERING & SEARCH =================== ///

  void filterByPostType(String postType) {
    if (selectedPostType.value == postType) return;
    selectedPostType.value = postType;
    fetchPosts(refresh: true);
  }

  void performSearch(String query) {
    searchQuery.value = query;
    // Debounce search to avoid too many requests
    Future.delayed(const Duration(milliseconds: 500), () {
      if (searchQuery.value == query) {
        fetchPosts(refresh: true);
      }
    });
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    fetchPosts(refresh: true);
  }

  String getPostTypeLabel(String type) {
    switch (type) {
      case 'all':
        return 'All Posts';
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

  int getPostTypeCount(String type) {
    return postTypeCounts[type] ?? 0;
  }

  /// =================== POST INTERACTIONS =================== ///

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

  Future<void> deletePost(String postId) async {
    try {
      await postRepo.deletePost(postId);
      posts.removeWhere((post) => post.postId == postId);
      _sessionPostIds.remove(postId); // 🆕 从会话缓存中移除
      _loadPostCounts();
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

  PostModel? getPostById(String postId) {
    try {
      return posts.firstWhere((post) => post.postId == postId);
    } catch (e) {
      return null;
    }
  }

  /// =================== VIDEO SPECIFIC =================== ///

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

  Future<void> refreshPosts() async {
    hasNewPosts.value = false;
    newPostsCount.value = 0;
    postsError.value = '';
    await fetchPosts(refresh: true);
    _loadPostCounts();
  }
}