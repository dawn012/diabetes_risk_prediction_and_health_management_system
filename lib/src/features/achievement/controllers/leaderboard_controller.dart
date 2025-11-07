import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/achievement/leaderboard_repository.dart';
import '../../../data/repositories/user/user_repository.dart';
import '../../../utils/constants/enums.dart';
import '../models/leaderboard_model.dart';

class LeaderboardController extends GetxController {
  static LeaderboardController get instance => Get.find();

  // Repositories
  final _leaderboardRepo = Get.put(LeaderboardRepository());
  final _userRepo = UserRepository.instance;

  // PageController for swipe gesture
  late final PageController pageController = PageController(initialPage: selectedTab.value);

  // 为每个tab创建独立的ScrollController
  final scrollControllerThisMonth = ScrollController();
  final scrollControllerLastMonth = ScrollController();

  // Timer for auto-refresh
  Timer? _refreshTimer;

  // Observable variables
  final selectedTab = 0.obs;
  final isLoading = false.obs;
  final leaderboardData = <LeaderboardModel>[].obs;
  final currentUserRankData = Rxn<LeaderboardModel>();
  final isCurrentUserVisible = false.obs;

  // 缓存数据 - 分别存储两个月份的数据
  List<LeaderboardModel>? _thisMonthCache;
  LeaderboardModel? _thisMonthUserCache;

  List<LeaderboardModel>? _lastMonthCache;
  LeaderboardModel? _lastMonthUserCache;

  // 标记是否已经初始加载过
  bool _hasLoadedThisMonth = false;
  bool _hasLoadedLastMonth = false;

  // 获取当前活动的ScrollController
  ScrollController get activeScrollController {
    return selectedTab.value == 0 ? scrollControllerThisMonth : scrollControllerLastMonth;
  }

  @override
  void onInit() {
    super.onInit();
    // Listen to page changes for tab synchronization
    pageController.addListener(_handlePageChange);

    // 为两个ScrollController都添加监听
    scrollControllerThisMonth.addListener(_scrollListener);
    scrollControllerLastMonth.addListener(_scrollListener);

    // 初始加载当前月份
    loadLeaderboard(showLoading: true);

    // 设置每5分钟自动刷新（仅针对 This Month）
    _setupAutoRefresh();
  }

  @override
  void onClose() {
    pageController.removeListener(_handlePageChange);
    pageController.dispose();

    scrollControllerThisMonth.removeListener(_scrollListener);
    scrollControllerThisMonth.dispose();

    scrollControllerLastMonth.removeListener(_scrollListener);
    scrollControllerLastMonth.dispose();

    _refreshTimer?.cancel();
    super.onClose();
  }

  /// Handle page changes and sync with tab selection
  void _handlePageChange() {
    if (pageController.page != null && !pageController.position.isScrollingNotifier.value) {
      final newPage = pageController.page!.round();
      if (newPage != selectedTab.value) {
        selectedTab.value = newPage;
        // 切换tab时加载数据（如果还没加载过）
        _onTabChanged();
      }
    }
  }

  /// 设置自动刷新（每5分钟，仅针对 This Month）
  void _setupAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      // 只在 This Month tab 且不在加载状态时静默刷新
      if (selectedTab.value == 0 && !isLoading.value) {
        loadLeaderboard(showLoading: false, forceRefresh: true);
      }
    });
  }

  void _scrollListener() {
    _checkCurrentUserVisibility();
  }

  void updateScrollPosition(double position) {
    _checkCurrentUserVisibility();
  }

  void _checkCurrentUserVisibility() {
    if (currentUserRankData.value == null) {
      isCurrentUserVisible.value = false;
      return;
    }

    final currentUser = currentUserRankData.value!;

    if (currentUser.currentRank <= 20) {
      final userIndex = leaderboardData.indexWhere((item) => item.isCurrentUser);

      if (userIndex == -1) {
        isCurrentUserVisible.value = false;
        return;
      }

      final itemHeight = 60.0;
      final itemPosition = userIndex * itemHeight;

      final scrollController = activeScrollController;
      final scrollPosition = scrollController.hasClients
          ? scrollController.position.pixels
          : 0.0;
      final viewportHeight = scrollController.hasClients
          ? scrollController.position.viewportDimension
          : 0.0;

      final isVisible = itemPosition >= scrollPosition &&
          itemPosition <= scrollPosition + viewportHeight;

      isCurrentUserVisible.value = isVisible;
    } else {
      isCurrentUserVisible.value = false;
    }
  }

  /// 当tab切换时调用
  void _onTabChanged() {
    if (selectedTab.value == 0) {
      // This Month - 如果有缓存就用缓存
      if (_hasLoadedThisMonth && _thisMonthCache != null) {
        _loadFromCache(_thisMonthCache!, _thisMonthUserCache);
      } else {
        loadLeaderboard(showLoading: true);
      }
    } else {
      // Last Month - 如果有缓存就用缓存
      if (_hasLoadedLastMonth && _lastMonthCache != null) {
        _loadFromCache(_lastMonthCache!, _lastMonthUserCache);
      } else {
        loadLeaderboard(showLoading: true);
      }
    }
  }

  /// 从缓存加载数据
  void _loadFromCache(List<LeaderboardModel> cachedData, LeaderboardModel? cachedUser) {
    leaderboardData.value = cachedData;
    currentUserRankData.value = cachedUser;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCurrentUserVisibility();
    });
  }

  /// 保存到缓存
  void _saveToCache(List<LeaderboardModel> data, LeaderboardModel? userData) {
    if (selectedTab.value == 0) {
      // This Month
      _thisMonthCache = List.from(data);
      _thisMonthUserCache = userData;
      _hasLoadedThisMonth = true;
    } else {
      // Last Month
      _lastMonthCache = List.from(data);
      _lastMonthUserCache = userData;
      _hasLoadedLastMonth = true;
    }
  }

  Future<void> loadLeaderboard({
    bool showLoading = true,
    bool forceRefresh = false
  }) async {
    try {
      // 如果不是强制刷新，且已有缓存，直接使用缓存
      if (!forceRefresh) {
        if (selectedTab.value == 0 && _hasLoadedThisMonth && _thisMonthCache != null) {
          _loadFromCache(_thisMonthCache!, _thisMonthUserCache);
          return;
        }
        if (selectedTab.value == 1 && _hasLoadedLastMonth && _lastMonthCache != null) {
          _loadFromCache(_lastMonthCache!, _lastMonthUserCache);
          return;
        }
      }

      // 只在需要时显示loading
      if (showLoading) {
        isLoading.value = true;
      }

      final currentUserId = _leaderboardRepo.currentUserId;
      if (currentUserId.isEmpty) {
        TLoaders.errorSnackBar(
          title: 'Error',
          message: 'User not authenticated',
        );
        return;
      }

      List<Map<String, dynamic>> leaderboardRawData;
      Map<String, int>? lastMonthRanks;

      if (selectedTab.value == 0) {
        // This Month
        leaderboardRawData = await _leaderboardRepo.fetchCurrentMonthLeaderboard();
        lastMonthRanks = await _getLastMonthRanksMap();
      } else {
        // Last Month
        leaderboardRawData = await _leaderboardRepo.fetchLastMonthLeaderboard();

        if (leaderboardRawData.isEmpty) {
          leaderboardData.clear();
          currentUserRankData.value = null;
          _saveToCache([], null);
          return;
        }
      }

      // Convert to LeaderboardModel
      final data = <LeaderboardModel>[];

      for (var userData in leaderboardRawData) {
        final userId = userData['userId'] as String;
        final currentRank = userData['rank'] as int;

        // Determine rank change
        RankChange? rankChange;
        int? previousRank;

        if (selectedTab.value == 0 && lastMonthRanks != null) {
          if (lastMonthRanks.containsKey(userId)) {
            previousRank = lastMonthRanks[userId];
            if (previousRank! > currentRank) {
              rankChange = RankChange.up;
            } else if (previousRank < currentRank) {
              rankChange = RankChange.down;
            } else {
              rankChange = RankChange.same;
            }
          } else {
            rankChange = RankChange.new_entry;
          }
        }

        data.add(LeaderboardModel(
          user: LeaderboardUserModel(
            userId: userId,
            userName: userData['username'] as String,
            totalScore: userData['totalScore'] as int,
            profileImg: userData['profileImg'] as String? ?? '',
          ),
          currentRank: currentRank,
          previousRank: previousRank,
          rankChange: rankChange,
          isCurrentUser: userId == currentUserId,
        ));
      }

      leaderboardData.value = data;

      // Find current user
      LeaderboardModel? currentUser;
      final currentUserIndex = data.indexWhere((item) => item.isCurrentUser);
      if (currentUserIndex != -1) {
        currentUser = data[currentUserIndex];
        currentUserRankData.value = currentUser;
      } else {
        if (selectedTab.value == 0) {
          currentUser = await _loadCurrentUserNotInLeaderboard(currentUserId);
          currentUserRankData.value = currentUser;
        } else {
          currentUserRankData.value = null;
        }
      }

      // 保存到缓存
      _saveToCache(data, currentUser);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkCurrentUserVisibility();
      });
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to load leaderboard: ${e.toString()}',
      );
    } finally {
      if (showLoading) {
        isLoading.value = false;
      }
    }
  }

  Future<Map<String, int>> _getLastMonthRanksMap() async {
    try {
      final lastMonthData = await _leaderboardRepo.fetchLastMonthLeaderboard();
      final ranksMap = <String, int>{};

      for (var data in lastMonthData) {
        ranksMap[data['userId'] as String] = data['rank'] as int;
      }

      return ranksMap;
    } catch (e) {
      return {};
    }
  }

  Future<LeaderboardModel?> _loadCurrentUserNotInLeaderboard(String userId) async {
    try {
      final userDoc = await _userRepo.fetchUserDetailsById(userId);

      // 如果用户分数为0，不显示排名
      if (userDoc.totalScore == 0) {
        return null;
      }

      final userRank = await _leaderboardRepo.getCurrentUserRank(userId);

      if (userRank > 0) {
        final lastMonthRank = await _leaderboardRepo.getLastMonthUserRank(userId);

        RankChange? rankChange;
        if (lastMonthRank != null) {
          if (lastMonthRank > userRank) {
            rankChange = RankChange.up;
          } else if (lastMonthRank < userRank) {
            rankChange = RankChange.down;
          } else {
            rankChange = RankChange.same;
          }
        } else {
          rankChange = RankChange.new_entry;
        }

        return LeaderboardModel(
          user: LeaderboardUserModel(
            userId: userId,
            userName: userDoc.username,
            totalScore: userDoc.totalScore,
            profileImg: userDoc.profileImg,
          ),
          currentRank: userRank,
          previousRank: lastMonthRank,
          rankChange: rankChange,
          isCurrentUser: true,
        );
      }
      return null;
    } catch (e) {
      print('Error loading current user data: $e');
      return null;
    }
  }

  /// Change tab with page animation
  void changeTab(int index) {
    if (index == selectedTab.value) return;

    selectedTab.value = index;

    // Animate to the selected page
    if (pageController.hasClients) {
      pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    // 切换后加载对应tab的数据（会自动使用缓存）
    _onTabChanged();
  }

  /// 手动刷新（pull to refresh用）
  Future<void> refreshLeaderboard() async {
    await loadLeaderboard(showLoading: false, forceRefresh: true);
  }
}