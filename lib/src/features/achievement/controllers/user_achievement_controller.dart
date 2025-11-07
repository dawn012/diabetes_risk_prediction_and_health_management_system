import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/achievement/achievement_repository.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../utils/constants/enums.dart';
import '../models/achievement_display_data.dart';
import '../models/user_achievement_model.dart';
import 'achievement_controller.dart';

class UserAchievementController extends GetxController {
  static UserAchievementController get instance => Get.find();

  final AchievementRepository _achievementRepository = Get.find();
  final AchievementController _achievementController = Get.find();
  final _authRepo = AuthenticationRepository.instance;

  // PageController for swipe gesture
  late final PageController pageController = PageController(initialPage: selectedTab.value);

  // Observable variables
  var selectedTab = 0.obs; // 0 for Periodic, 1 for Permanent
  var selectedFilter = 'all'.obs;
  var userAchievements = <UserAchievementModel>[].obs;
  var expandedAchievements = <String>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _setupUserAchievementsStream();

    // Listen to page changes for tab synchronization
    pageController.addListener(_handlePageChange);
  }

  @override
  void onClose() {
    // Dispose PageController when controller is closed
    pageController.removeListener(_handlePageChange);
    pageController.dispose();
    super.onClose();
  }

  /// Handle page changes and sync with tab selection
  void _handlePageChange() {
    if (pageController.page != null && !pageController.position.isScrollingNotifier.value) {
      final newPage = pageController.page!.round();
      if (newPage != selectedTab.value) {
        selectedTab.value = newPage;
        selectedFilter.value = 'all';
        expandedAchievements.clear();
      }
    }
  }

  /// Setup real-time user achievements stream with details
  void _setupUserAchievementsStream() {
    try {
      isLoading.value = true;

      final userId = _authRepo.authUser?.uid;
      if (userId == null) {
        TLoaders.errorSnackBar(
          title: 'Error',
          message: 'User not authenticated',
        );
        isLoading.value = false;
        return;
      }

      _achievementRepository.getUserAchievementsWithDetailsStream(userId).listen(
            (achievements) {
          userAchievements.value = achievements;
          isLoading.value = false;
        },
        onError: (error) {
          isLoading.value = false;
          TLoaders.errorSnackBar(
            title: 'Error',
            message: 'Failed to load user achievements: ${error.toString()}',
          );
        },
      );
    } catch (e) {
      isLoading.value = false;
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to setup achievements stream: ${e.toString()}',
      );
    }
  }

  /// Combine system achievements with user progress
  List<AchievementDisplayData> get displayAchievements {
    final AchievementType type = selectedTab.value == 0
        ? AchievementType.periodic
        : AchievementType.permanent;
    final systemAchievements = _achievementController.getAchievementsByType(type);

    final achievements = systemAchievements.map((achievement) {
      final userAchievement = userAchievements.firstWhereOrNull(
            (ua) => ua.achievement.achievementId == achievement.achievementId,
      );

      return AchievementDisplayData(
        achievement: achievement,
        userAchievement: userAchievement,
        isLocked: userAchievement == null,
        currentLevel: userAchievement?.currentLevel ?? UserAchievementLevel.none,
        currentCount: userAchievement?.currentCount ?? 0,
        status: userAchievement?.status ?? AchievementStatus.inProgress,
      );
    }).toList();

    // 按等级排序：Gold > Silver > Bronze > None > Locked
    achievements.sort((a, b) {
      // 等级权重映射
      final levelWeights = {
        UserAchievementLevel.gold: 4,
        UserAchievementLevel.silver: 3,
        UserAchievementLevel.bronze: 2,
        UserAchievementLevel.none: 1,
      };

      final aWeight = a.isLocked ? 0 : levelWeights[a.currentLevel] ?? 0;
      final bWeight = b.isLocked ? 0 : levelWeights[b.currentLevel] ?? 0;

      // 等级高的排在前面
      if (aWeight != bWeight) {
        return bWeight.compareTo(aWeight);
      }

      // 如果等级相同，已完成的排在前面
      if (a.status != b.status) {
        if (a.status == AchievementStatus.completed) return -1;
        if (b.status == AchievementStatus.completed) return 1;
      }

      // 如果状态也相同，按进度百分比排序
      final aProgress = getProgress(a);
      final bProgress = getProgress(b);
      if (aProgress != bProgress) {
        return bProgress.compareTo(aProgress);
      }

      // 最后按标题字母顺序排序
      return a.achievement.achievementTitle
          .compareTo(b.achievement.achievementTitle);
    });

    return achievements;
  }

  /// Get filtered achievements
  List<AchievementDisplayData> get filteredAchievements {
    final achievements = displayAchievements;

    if (selectedFilter.value != 'all') {
      return achievements.where((item) {
        if (selectedFilter.value == 'locked') {
          return item.isLocked;
        }

        if (item.isLocked) {
          return false;
        }

        if (selectedFilter.value == 'unlocked') {
          return !item.isLocked && item.currentLevel == UserAchievementLevel.none;
        }

        final medal = item.currentLevel.value.toLowerCase();
        return medal == selectedFilter.value;
      }).toList();
    }

    return achievements;
  }

  /// Get completed achievements count
  int get completedCount {
    if (selectedFilter.value != 'all') return 0;
    return displayAchievements
        .where((item) => !item.isLocked && item.status == AchievementStatus.completed)
        .length;
  }

  /// Get total achievements count
  int get totalCount {
    if (selectedFilter.value != 'all') return 0;
    return displayAchievements.length;
  }

  /// Should show progress counter
  bool get shouldShowProgress => selectedFilter.value == 'all';

  /// Change tab with page animation
  void changeTab(int index) {
    if (index == selectedTab.value) return;

    selectedTab.value = index;
    selectedFilter.value = 'all';
    expandedAchievements.clear();

    // Animate to the selected page
    if (pageController.hasClients) {
      pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Change filter
  void changeFilter(String filter) {
    selectedFilter.value = filter;
    expandedAchievements.clear();
  }

  /// Toggle achievement expansion
  void toggleAchievement(String achievementId) {
    if (expandedAchievements.contains(achievementId)) {
      expandedAchievements.remove(achievementId);
    } else {
      expandedAchievements.add(achievementId);
    }
  }

  /// Check if achievement is expanded
  bool isAchievementExpanded(String achievementId) {
    return expandedAchievements.contains(achievementId);
  }

  /// Get medal type based on current level
  String getMedalType(AchievementDisplayData achievementData) {
    if (achievementData.isLocked) {
      return 'locked';
    }
    if (achievementData.currentLevel == UserAchievementLevel.none) {
      return 'unlocked';
    }
    return achievementData.currentLevel.value.toLowerCase();
  }

  /// Get progress percentage
  double getProgress(AchievementDisplayData achievementData) {
    if (achievementData.isLocked) return 0.0;
    if (achievementData.status == AchievementStatus.completed) return 1.0;

    final achievement = achievementData.achievement;
    if (achievement.levels.isEmpty) return 0.0;

    final currentCount = achievementData.currentCount;
    final currentLevel = achievementData.currentLevel;

    if (currentLevel == UserAchievementLevel.none) {
      final firstLevel = achievement.levels.first;
      return (currentCount / firstLevel.criteria).clamp(0.0, 1.0);
    }

    final currentIndex = achievement.levels.indexWhere(
          (level) => level.level.value == currentLevel.value,
    );

    if (currentIndex == -1 || currentIndex == achievement.levels.length - 1) {
      return 1.0;
    }

    final nextLevelData = achievement.levels[currentIndex + 1];

    return (currentCount / nextLevelData.criteria).clamp(0.0, 1.0);
  }

  /// Get progress text with unit
  String getProgressText(AchievementDisplayData achievementData) {
    if (achievementData.isLocked) return 'Locked';
    if (achievementData.status == AchievementStatus.completed) return 'Completed';

    final achievement = achievementData.achievement;
    if (achievement.levels.isEmpty) return '0/0';

    final currentCount = achievementData.currentCount;
    final currentLevel = achievementData.currentLevel;

    if (currentLevel == UserAchievementLevel.none) {
      final firstLevel = achievement.levels.first;
      return '$currentCount/${firstLevel.criteria} ${firstLevel.criteriaUnit}';
    }

    final currentIndex = achievement.levels.indexWhere(
          (level) => level.level.value == currentLevel.value,
    );

    if (currentIndex == -1 || currentIndex == achievement.levels.length - 1) {
      return '$currentCount/$currentCount';
    }

    final nextLevelData = achievement.levels[currentIndex + 1];
    return '$currentCount/${nextLevelData.criteria} ${nextLevelData.criteriaUnit}';
  }

  /// Check if a level is achieved
  bool isLevelAchieved(AchievementDisplayData achievementData, AchievementLevel levelName) {
    if (achievementData.isLocked) return false;

    final achievement = achievementData.achievement;
    final currentLevel = achievementData.currentLevel;

    if (currentLevel == UserAchievementLevel.none) return false;

    final levels = achievement.levels;
    final currentLevelIndex = levels.indexWhere((l) => l.level.value == currentLevel.value);
    final targetLevelIndex = levels.indexWhere((l) => l.level.value == levelName.value);

    return currentLevelIndex >= targetLevelIndex;
  }

  /// Increment achievement progress (called when user completes an action)
  Future<void> incrementAchievement({
    required String achievementId,
    int incrementBy = 1,
  }) async {
    try {
      final userId = _authRepo.authUser?.uid;
      if (userId == null) {
        TLoaders.errorSnackBar(
          title: 'Error',
          message: 'User not authenticated',
        );
        return;
      }

      final achievement = _achievementController.getAchievementById(achievementId);
      if (achievement == null) {
        TLoaders.errorSnackBar(
          title: 'Error',
          message: 'Achievement not found',
        );
        return;
      }

      await _achievementRepository.incrementAchievementCount(
        userId: userId,
        achievementId: achievementId,
        achievement: achievement,
        incrementBy: incrementBy,
      );

      TLoaders.successSnackBar(
        title: 'Progress Updated',
        message: 'Achievement progress has been updated',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to update achievement: ${e.toString()}',
      );
    }
  }

  /// Reset periodic achievements (should be called monthly)
  Future<void> resetPeriodicAchievements() async {
    try {
      final userId = _authRepo.authUser?.uid;
      if (userId == null) {
        TLoaders.errorSnackBar(
          title: 'Error',
          message: 'User not authenticated',
        );
        return;
      }

      isLoading.value = true;
      await _achievementRepository.resetPeriodicAchievements(userId);
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to reset achievements: ${e.toString()}',
      );
    }
  }

  /// Refresh user achievements
  Future<void> refreshData() async {
    try {
      isLoading.value = true;
      await Future.delayed(const Duration(milliseconds: 500));
      isLoading.value = false;
      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Achievements refreshed',
      );
    } catch (e) {
      isLoading.value = false;
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to refresh: ${e.toString()}',
      );
    }
  }

  /// Get user's total score
  Future<int> getUserTotalScore() async {
    try {
      final userId = _authRepo.authUser?.uid;
      if (userId == null) return 0;

      return await _achievementRepository.getUserTotalScore(userId);
    } catch (e) {
      return 0;
    }
  }
}