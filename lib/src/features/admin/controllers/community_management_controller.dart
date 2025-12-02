import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../utils/constants/admin_colors.dart';
import '../../../utils/constants/enums.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/repositories/community/post_repository.dart';
import '../../../data/repositories/community/post_report_repository.dart';
import '../../authentication/models/user_model.dart';
import '../../community/models/post_model.dart';
import '../../community/models/post_report_model.dart';

/// Cache entry model
class CachedPage {
  final List<PostModel> posts;
  final DateTime cachedAt;
  final int totalCount;

  CachedPage({
    required this.posts,
    required this.cachedAt,
    required this.totalCount,
  });
}

class CommunityManagementController extends GetxController {
  static CommunityManagementController get instance => Get.find();

  // Observable variables
  final RxList<PostModel> displayedPosts = <PostModel>[].obs;
  final RxList<PostModel> selectedPosts = <PostModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool showingActivePosts = true.obs;
  final Rx<PostType?> selectedPostType = Rx<PostType?>(null);

  // Search and sorting
  final TextEditingController searchController = TextEditingController();
  final RxInt sortColumnIndex = 0.obs;
  final RxBool sortAscending = true.obs;
  Timer? _searchDebounce;

  // Pagination
  final RxInt currentPage = 1.obs;
  final RxInt itemsPerPage = 10.obs;
  final RxInt totalCount = 0.obs;
  final RxInt totalPages = 1.obs;
  final RxList<int> itemsPerPageOptions = [10, 25, 50, 100].obs;

  // Cache management (max 3 pages)
  final Map<String, CachedPage> _pageCache = {};
  static const int _maxCachedPages = 3;

  // New posts detection
  final RxInt newPostsCount = 0.obs;
  DateTime? _lastLoadTimestamp;
  StreamSubscription<int>? _newPostsSubscription;
  Timer? _newPostsTimer;
  static const int _newPostsThreshold = 3;
  static const Duration _newPostsCheckInterval = Duration(seconds: 30);

  // Post types for filtering
  final RxList<PostType> postTypes = PostType.values.obs;

  // User data for poster info
  final RxMap<String, UserModel> posterData = <String, UserModel>{}.obs;

  // Reports data
  final RxMap<String, List<PostReportModel>> postReports = <String, List<PostReportModel>>{}.obs;

  // Reports dialog state
  final RxBool isLoadingReports = false.obs;
  final RxList<String> selectedReportIds = <String>[].obs;
  final RxInt currentReportTabIndex = 0.obs;

  // Current user role
  final RxString currentUserRole = ''.obs;

  // Repositories
  final _postRepo = Get.put(PostRepository());
  final _reportRepo = Get.put(PostReportRepository());
  final _authRepo = AuthenticationRepository.instance;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_onSearchChanged);
    _loadCurrentUserRole();
    _loadFirstPage();
  }

  @override
  void onClose() {
    searchController.dispose();
    _searchDebounce?.cancel();
    _newPostsSubscription?.cancel();
    _newPostsTimer?.cancel();
    _pageCache.clear();
    super.onClose();
  }

  /// Load current user role
  Future<void> _loadCurrentUserRole() async {
    try {
      final role = await _authRepo.getUserRole();
      currentUserRole.value = role;
    } catch (e) {
      print("Error loading user role: $e");
      currentUserRole.value = "user";
    }
  }

  /// Check if user has permission to manage posts
  bool get canManagePosts {
    final role = currentUserRole.value.toLowerCase();
    return role == 'admin' || role == 'community manager';
  }

  /// Generate cache key
  String _getCacheKey() {
    return '${showingActivePosts.value ? "active" : "disabled"}_'
        '${selectedPostType.value?.name ?? "all"}_'
        '${searchController.text}_'
        '$currentPage';
  }

  /// Load first page
  Future<void> _loadFirstPage() async {
    currentPage.value = 1;
    await _loadPage(1, preloadNext: true);
  }

  /// Load specific page
  Future<void> _loadPage(int page, {bool preloadNext = false}) async {
    try {
      final cacheKey = _getCacheKey();

      if (_pageCache.containsKey(cacheKey)) {
        print('📦 Loading page $page from cache');
        final cached = _pageCache[cacheKey]!;
        displayedPosts.assignAll(cached.posts);
        totalCount.value = cached.totalCount;
        _calculateTotalPages();
        _loadPosterData(cached.posts);
        _loadReportsForPosts(cached.posts);

        if (preloadNext && page < totalPages.value) {
          _preloadPage(page + 1);
        }
        return;
      }

      isLoading.value = true;

      final response = await _postRepo.fetchPaginatedPosts(
        page: page,
        itemsPerPage: itemsPerPage.value,
        postType: selectedPostType.value?.name,
        searchQuery: searchController.text.trim().isEmpty
            ? null
            : searchController.text.trim(),
        isDisable: !showingActivePosts.value,
      );

      _updateCache(cacheKey, response.posts, response.totalCount);

      displayedPosts.assignAll(response.posts);
      selectedPosts.clear();
      totalCount.value = response.totalCount;
      _calculateTotalPages();

      await _loadPosterData(response.posts);
      await _loadReportsForPosts(response.posts);

      if (preloadNext && page < totalPages.value) {
        _preloadPage(page + 1);
      }

      _lastLoadTimestamp = DateTime.now();
      print('🕒 Updated baseline timestamp: $_lastLoadTimestamp');
      _startNewPostsDetection();
    } catch (e) {
      print('Error loading page $page: $e');
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to load posts: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Preload page in background
  Future<void> _preloadPage(int page) async {
    try {
      final cacheKey = '${showingActivePosts.value ? "active" : "disabled"}_'
          '${selectedPostType.value?.name ?? "all"}_'
          '${searchController.text}_'
          '$page';

      if (_pageCache.containsKey(cacheKey)) {
        return;
      }

      print('⏳ Preloading page $page...');

      final response = await _postRepo.fetchPaginatedPosts(
        page: page,
        itemsPerPage: itemsPerPage.value,
        postType: selectedPostType.value?.name,
        searchQuery: searchController.text.trim().isEmpty
            ? null
            : searchController.text.trim(),
        isDisable: !showingActivePosts.value,
      );

      _updateCache(cacheKey, response.posts, response.totalCount);
      print('✅ Page $page preloaded');
    } catch (e) {
      print('Error preloading page $page: $e');
    }
  }

  /// Update cache with LRU strategy
  void _updateCache(String key, List<PostModel> posts, int totalCount) {
    if (_pageCache.length >= _maxCachedPages) {
      final sortedEntries = _pageCache.entries.toList()
        ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));

      final toRemove = _pageCache.length - _maxCachedPages + 1;
      for (var i = 0; i < toRemove; i++) {
        _pageCache.remove(sortedEntries[i].key);
        print('🗑️ Removed old cache: ${sortedEntries[i].key}');
      }
    }

    _pageCache[key] = CachedPage(
      posts: posts,
      cachedAt: DateTime.now(),
      totalCount: totalCount,
    );
    print('💾 Cached page: $key (${_pageCache.length}/$_maxCachedPages)');
  }

  /// Clear all cache
  void _clearCache() {
    _pageCache.clear();
    print('🧹 Cache cleared');
  }

  /// Calculate total pages
  void _calculateTotalPages() {
    if (itemsPerPage.value > 0) {
      totalPages.value = (totalCount.value / itemsPerPage.value).ceil();
      if (totalPages.value == 0) totalPages.value = 1;
    }
  }

  /// Load poster data
  Future<void> _loadPosterData(List<PostModel> posts) async {
    try {
      final posterIds = posts.map((p) => p.posterId).toSet().toList();

      for (String posterId in posterIds) {
        if (!posterData.containsKey(posterId)) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(posterId)
              .get();

          if (userDoc.exists) {
            posterData[posterId] = UserModel.fromSnapshot(userDoc);
          }
        }
      }
    } catch (e) {
      print('Error loading poster data: $e');
    }
  }

  /// Load reports for visible posts
  Future<void> _loadReportsForPosts(List<PostModel> posts) async {
    try {
      for (var post in posts) {
        if (!postReports.containsKey(post.postId)) {
          final allReports = await _reportRepo.getPostReports(post.postId);
          postReports[post.postId] = allReports;
        }
      }
    } catch (e) {
      print('Error loading reports: $e');
    }
  }

  /// Get pending reports for a post
  List<PostReportModel> getPendingReportsForPost(String postId) {
    final reports = postReports[postId] ?? [];
    return reports.where((r) => r.status == ReportStatus.pending).toList();
  }

  /// Get resolved reports for a post
  List<PostReportModel> getResolvedReportsForPost(String postId) {
    final reports = postReports[postId] ?? [];
    return reports.where((r) => r.status == ReportStatus.resolved).toList();
  }

  /// Load reports for dialog
  Future<void> loadReportsForDialog(String postId) async {
    isLoadingReports.value = true;
    selectedReportIds.clear();

    try {
      final reports = await _reportRepo.getPostReports(postId);
      postReports[postId] = reports;
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to load reports',
      );
    } finally {
      isLoadingReports.value = false;
    }
  }

  /// Mark single report as reviewed
  Future<void> markReportAsReviewed(String postId, String reportId) async {
    try {
      await _reportRepo.markReportAsReviewed(postId, reportId);
      await loadReportsForDialog(postId);
      await refreshPosts(showMessage: false);
      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Report marked as reviewed',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to mark report as reviewed',
      );
    }
  }

  /// Mark multiple reports as reviewed
  Future<void> markMultipleReportsAsReviewed(String postId) async {
    if (selectedReportIds.isEmpty) return;

    try {
      await _reportRepo.markMultipleReportsAsReviewed(
        postId,
        selectedReportIds,
      );
      selectedReportIds.clear();
      await loadReportsForDialog(postId);
      await refreshPosts(showMessage: false);
      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Reports marked as reviewed',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to mark reports as reviewed',
      );
    }
  }

  /// Disable post from report
  Future<void> disablePostFromReport(String postId, String reportId) async {
    try {
      await _reportRepo.disablePostFromReport(postId, reportId);
      await loadReportsForDialog(postId);
      await refreshPosts(showMessage: false);
      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Post disabled and report reviewed',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to disable post',
      );
    }
  }

  /// Toggle report selection
  void toggleReportSelection(String reportId) {
    if (selectedReportIds.contains(reportId)) {
      selectedReportIds.remove(reportId);
    } else {
      selectedReportIds.add(reportId);
    }
  }

  /// Clear report selections
  void clearReportSelections() {
    selectedReportIds.clear();
  }

  /// Change report tab
  void changeReportTab(int index) {
    currentReportTabIndex.value = index;
    selectedReportIds.clear();
  }

  /// Handle search input changes with debounce
  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _clearCache();
      currentPage.value = 1;
      _loadPage(1, preloadNext: true);
    });
  }

  /// Change page
  void changePage(int page) {
    if (page >= 1 && page <= totalPages.value && page != currentPage.value) {
      currentPage.value = page;
      selectedPosts.clear();

      final isJump = (page - currentPage.value).abs() > 1;

      if (isJump) {
        final targetKey = _getCacheKey();
        final nextPageKey = '${showingActivePosts.value ? "active" : "disabled"}_'
            '${selectedPostType.value?.name ?? "all"}_'
            '${searchController.text}_'
            '${page + 1}';

        _pageCache.removeWhere((key, value) =>
        key != targetKey && key != nextPageKey);
      }

      _loadPage(page, preloadNext: true);
    }
  }

  /// Change items per page
  void changeItemsPerPage(int? items) {
    if (items != null && items != itemsPerPage.value) {
      itemsPerPage.value = items;
      _clearCache();
      currentPage.value = 1;
      selectedPosts.clear();
      _loadPage(1, preloadNext: true);
    }
  }

  /// Show active posts
  void showActivePosts() {
    if (!showingActivePosts.value) {
      showingActivePosts.value = true;
      _clearCache();
      selectedPosts.clear();
      currentPage.value = 1;
      _lastLoadTimestamp = null;
      _loadPage(1, preloadNext: true);
    }
  }

  /// Show disabled posts
  void showDisabledPosts() {
    if (showingActivePosts.value) {
      showingActivePosts.value = false;
      _clearCache();
      selectedPosts.clear();
      currentPage.value = 1;
      _lastLoadTimestamp = null;
      _loadPage(1, preloadNext: true);
    }
  }

  /// Change post type filter
  void changePostTypeFilter(PostType? type) {
    if (selectedPostType.value != type) {
      selectedPostType.value = type;
      _clearCache();
      currentPage.value = 1;
      selectedPosts.clear();
      _lastLoadTimestamp = null;
      _loadPage(1, preloadNext: true);
    }
  }

  /// Toggle post selection
  void togglePostSelection(PostModel post, bool selected) {
    if (selected) {
      selectedPosts.add(post);
    } else {
      selectedPosts.remove(post);
    }
  }

  /// Toggle select all
  void toggleSelectAll(bool selectAll) {
    if (selectAll) {
      selectedPosts.assignAll(displayedPosts);
    } else {
      selectedPosts.clear();
    }
  }

  /// Sort posts
  void sortPosts(int columnIndex, bool ascending) {
    sortColumnIndex.value = columnIndex;
    sortAscending.value = ascending;

    displayedPosts.sort((a, b) {
      dynamic valueA, valueB;

      switch (columnIndex) {
        case 0:
          valueA = a.postId;
          valueB = b.postId;
          break;
        case 1:
          valueA = posterData[a.posterId]?.username ?? '';
          valueB = posterData[b.posterId]?.username ?? '';
          break;
        case 2:
          valueA = a.postType.displayName;
          valueB = b.postType.displayName;
          break;
        case 3:
          valueA = a.mediaUrls.length;
          valueB = b.mediaUrls.length;
          break;
        case 4:
          valueA = a.likes.length;
          valueB = b.likes.length;
          break;
        case 5:
          valueA = a.updatedAt;
          valueB = b.updatedAt;
          break;
        case 6:
          valueA = a.pendingReportCount;
          valueB = b.pendingReportCount;
          break;
        default:
          valueA = a.updatedAt;
          valueB = b.updatedAt;
      }

      int comparison = 0;
      if (valueA is String && valueB is String) {
        comparison = valueA.compareTo(valueB);
      } else if (valueA is int && valueB is int) {
        comparison = valueA.compareTo(valueB);
      } else if (valueA is DateTime && valueB is DateTime) {
        comparison = valueA.compareTo(valueB);
      }

      return ascending ? comparison : -comparison;
    });
  }

  /// Start new posts detection
  void _startNewPostsDetection() {
    _newPostsSubscription?.cancel();
    _newPostsTimer?.cancel();
    newPostsCount.value = 0;

    if (_lastLoadTimestamp == null) {
      print('⏸️ New posts detection paused - no baseline timestamp');
      return;
    }

    _newPostsTimer = Timer.periodic(_newPostsCheckInterval, (_) {
      _checkNewPosts();
    });

    _newPostsSubscription = _postRepo.streamNewPostsCount(
      since: _lastLoadTimestamp,
      postType: selectedPostType.value?.name,
      isDisable: !showingActivePosts.value,
    ).listen((count) {
      newPostsCount.value = count;

      if (count >= _newPostsThreshold) {
        _showNewPostsNotification(count);
      }
    });
  }

  /// Check for new posts periodically
  void _checkNewPosts() {
    if (newPostsCount.value > 0) {
      _showNewPostsNotification(newPostsCount.value);
    }
  }

  /// Show new posts notification
  void _showNewPostsNotification(int count) {
    Get.snackbar(
      'New Posts Available',
      '$count new post${count > 1 ? 's' : ''} available. Tap to refresh.',
      duration: const Duration(seconds: 5),
      backgroundColor: TAdminColors.info.withOpacity(0.9),
      colorText: Colors.white,
      icon: const Icon(Icons.refresh, color: Colors.white),
      onTap: (_) => refreshPosts(),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
    );
  }

  /// Refresh posts
  Future<void> refreshPosts({bool showMessage = true}) async {
    _clearCache();
    selectedPosts.clear();
    newPostsCount.value = 0;
    _lastLoadTimestamp = null;
    currentPage.value = 1;

    await _loadPage(1, preloadNext: true);

    if (showMessage) {
      TLoaders.successSnackBar(
        title: 'Refreshed',
        message: 'Posts data has been refreshed.',
      );
    }
  }

  /// Disable a single post
  Future<void> disablePost(PostModel post) async {
    if (!canManagePosts) {
      TLoaders.errorSnackBar(
        title: 'Permission Denied',
        message: 'You do not have permission to disable posts.',
      );
      return;
    }

    try {
      await _postRepo.togglePostStatus(post.postId, post.isDisable);

      final cacheKey = _getCacheKey();
      if (_pageCache.containsKey(cacheKey)) {
        final cached = _pageCache[cacheKey]!;
        final updatedPosts = cached.posts.where((p) => p.postId != post.postId).toList();
        _pageCache[cacheKey] = CachedPage(
          posts: updatedPosts,
          cachedAt: DateTime.now(),
          totalCount: cached.totalCount - 1,
        );
        displayedPosts.assignAll(updatedPosts);
        totalCount.value = cached.totalCount - 1;
        _calculateTotalPages();
      }

      selectedPosts.clear();

      TLoaders.successSnackBar(
        title: 'Post Disabled',
        message: 'Post has been successfully disabled.',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to disable post: ${e.toString()}',
      );
    }
  }

  /// Enable a single post
  Future<void> enablePost(PostModel post) async {
    if (!canManagePosts) {
      TLoaders.errorSnackBar(
        title: 'Permission Denied',
        message: 'You do not have permission to enable posts.',
      );
      return;
    }

    try {
      await _postRepo.togglePostStatus(post.postId, post.isDisable);

      final cacheKey = _getCacheKey();
      if (_pageCache.containsKey(cacheKey)) {
        final cached = _pageCache[cacheKey]!;
        final updatedPosts = cached.posts.where((p) => p.postId != post.postId).toList();
        _pageCache[cacheKey] = CachedPage(
          posts: updatedPosts,
          cachedAt: DateTime.now(),
          totalCount: cached.totalCount - 1,
        );
        displayedPosts.assignAll(updatedPosts);
        totalCount.value = cached.totalCount - 1;
        _calculateTotalPages();
      }

      selectedPosts.clear();

      TLoaders.successSnackBar(
        title: 'Post Enabled',
        message: 'Post has been successfully enabled.',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to enable post: ${e.toString()}',
      );
    }
  }

  /// Batch disable posts
  Future<void> batchDisablePosts() async {
    if (!canManagePosts) {
      TLoaders.errorSnackBar(
        title: 'Permission Denied',
        message: 'You do not have permission to disable posts.',
      );
      return;
    }

    if (selectedPosts.isEmpty) return;

    try {
      isLoading.value = true;
      final count = selectedPosts.length;

      for (var post in selectedPosts) {
        await _postRepo.togglePostStatus(post.postId, post.isDisable);
      }

      _clearCache();
      selectedPosts.clear();
      await _loadPage(currentPage.value, preloadNext: true);

      TLoaders.successSnackBar(
        title: 'Posts Disabled',
        message: '$count post${count > 1 ? 's' : ''} disabled successfully.',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to disable posts: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Batch enable posts
  Future<void> batchEnablePosts() async {
    if (!canManagePosts) {
      TLoaders.errorSnackBar(
        title: 'Permission Denied',
        message: 'You do not have permission to enable posts.',
      );
      return;
    }

    if (selectedPosts.isEmpty) return;

    try {
      isLoading.value = true;
      final count = selectedPosts.length;

      for (var post in selectedPosts) {
        await _postRepo.togglePostStatus(post.postId, post.isDisable);
      }

      _clearCache();
      selectedPosts.clear();
      await _loadPage(currentPage.value, preloadNext: true);

      TLoaders.successSnackBar(
        title: 'Posts Enabled',
        message: '$count post${count > 1 ? 's' : ''} enabled successfully.',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to enable posts: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Get highlighted text for search
  List<TextSpan> getHighlightedText(
      String text,
      String query, {
        Color? textColor,
      }) {
    if (query.isEmpty) {
      return [TextSpan(text: text, style: TextStyle(color: textColor))];
    }

    final List<TextSpan> spans = [];
    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();
    int start = 0;

    while (true) {
      final int index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(
            TextSpan(text: text.substring(start), style: TextStyle(color: textColor)));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(
            text: text.substring(start, index), style: TextStyle(color: textColor)));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          backgroundColor: TAdminColors.warning.withOpacity(0.3),
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ));

      start = index + query.length;
    }

    return spans;
  }
}