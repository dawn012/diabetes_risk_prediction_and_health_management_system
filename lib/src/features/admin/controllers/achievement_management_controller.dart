import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../achievement/models/achievement_level_model.dart';
import '../../achievement/models/achievement_model.dart';
import '../../achievement/models/user_achievement_model.dart';

class AchievementManagementController extends GetxController {
  static AchievementManagementController get instance => Get.find();

  // Observables
  final isLoading = false.obs;
  final currentPage = 1.obs;
  final itemsPerPage = 10.obs;
  final totalPages = 1.obs;
  final showingActiveAchievements = true.obs;
  final selectedAchievementType = 'all'.obs;
  final sortColumnIndex = 0.obs;
  final sortAscending = true.obs;

  // Data
  final allAchievements = <AchievementModel>[].obs;
  final filteredAchievements = <AchievementModel>[].obs;
  final selectedAchievements = <AchievementModel>[].obs;
  final userAchievements = <UserAchievementModel>[].obs;

  // Controllers
  final searchController = TextEditingController();

  // Constants
  final List<int> itemsPerPageOptions = [5, 10, 25, 50];
  final List<String> achievementTypes = ['all', 'monthly', 'permanent'];

  @override
  void onInit() {
    super.onInit();
    loadAchievements();
    setupSearchListener();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void setupSearchListener() {
    searchController.addListener(() {
      filterAchievements();
    });
  }

  // Data Loading
  Future<void> loadAchievements() async {
    try {
      isLoading.value = true;

      // Simulate API call - replace with actual implementation
      await Future.delayed(Duration(seconds: 1));

      // Mock data for demonstration
      allAchievements.value = _generateMockAchievements();
      await loadUserAchievements();

      filterAchievements();
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Error', message: 'Failed to load achievements: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadUserAchievements() async {
    try {
      // Simulate loading user achievements for statistics
      await Future.delayed(Duration(milliseconds: 500));
      userAchievements.value = _generateMockUserAchievements();
    } catch (e) {
      print('Failed to load user achievements: $e');
    }
  }

  Future<void> refreshAchievements() async {
    currentPage.value = 1;
    selectedAchievements.clear();
    await loadAchievements();
    TLoaders.successSnackBar(title: 'Success', message: 'Achievements refreshed successfully');
  }

  // Filtering and Searching
  void filterAchievements() {
    List<AchievementModel> filtered = allAchievements.where((achievement) {
      // Filter by status
      bool statusMatch = showingActiveAchievements.value
          ? achievement.isActive
          : !achievement.isActive;

      // Filter by type
      bool typeMatch = selectedAchievementType.value == 'all' ||
          achievement.achievementType == selectedAchievementType.value;

      // Filter by search query
      bool searchMatch = true;
      if (searchController.text.isNotEmpty) {
        final query = searchController.text.toLowerCase();
        searchMatch = achievement.achievementTitle.toLowerCase().contains(query) ||
            achievement.description.toLowerCase().contains(query) ||
            achievement.achievementId.toLowerCase().contains(query);
      }

      return statusMatch && typeMatch && searchMatch;
    }).toList();

    // Apply sorting
    _sortAchievements(filtered);

    filteredAchievements.value = filtered;
    _updatePagination();
  }

  void _sortAchievements(List<AchievementModel> achievements) {
    achievements.sort((a, b) {
      dynamic aValue, bValue;

      switch (sortColumnIndex.value) {
        case 0: // Title
          aValue = a.achievementTitle;
          bValue = b.achievementTitle;
          break;
        case 1: // Type
          aValue = a.achievementType;
          bValue = b.achievementType;
          break;
        case 2: // Levels count
          aValue = a.levels.length;
          bValue = b.levels.length;
          break;
        case 3: // Participants
          aValue = getCompletionStats(a)['total'] ?? 0;
          bValue = getCompletionStats(b)['total'] ?? 0;
          break;
        case 4: // Created date
          aValue = a.createdAt;
          bValue = b.createdAt;
          break;
        case 5: // Status
          aValue = a.isActive ? 1 : 0;
          bValue = b.isActive ? 1 : 0;
          break;
        default:
          aValue = a.achievementTitle;
          bValue = b.achievementTitle;
      }

      int comparison;
      if (aValue is String && bValue is String) {
        comparison = aValue.compareTo(bValue);
      } else if (aValue is num && bValue is num) {
        comparison = aValue.compareTo(bValue);
      } else if (aValue is DateTime && bValue is DateTime) {
        comparison = aValue.compareTo(bValue);
      } else {
        comparison = aValue.toString().compareTo(bValue.toString());
      }

      return sortAscending.value ? comparison : -comparison;
    });
  }

  void _updatePagination() {
    final itemCount = filteredAchievements.length;
    totalPages.value = (itemCount / itemsPerPage.value).ceil().clamp(1, double.infinity).toInt();

    if (currentPage.value > totalPages.value) {
      currentPage.value = totalPages.value;
    }
  }

  // UI State Management
  void showActiveAchievements() {
    showingActiveAchievements.value = true;
    currentPage.value = 1;
    selectedAchievements.clear();
    filterAchievements();
  }

  void showDisabledAchievements() {
    showingActiveAchievements.value = false;
    currentPage.value = 1;
    selectedAchievements.clear();
    filterAchievements();
  }

  void changeAchievementTypeFilter(String type) {
    selectedAchievementType.value = type;
    currentPage.value = 1;
    selectedAchievements.clear();
    filterAchievements();
  }

  void changeItemsPerPage(int? items) {
    if (items != null) {
      itemsPerPage.value = items;
      currentPage.value = 1;
      _updatePagination();
    }
  }

  void changePage(int page) {
    currentPage.value = page;
  }

  void sortAchievements(int columnIndex, bool ascending) {
    sortColumnIndex.value = columnIndex;
    sortAscending.value = ascending;
    filterAchievements();
  }

  // Selection Management
  void toggleAchievementSelection(AchievementModel achievement, bool selected) {
    if (selected) {
      if (!selectedAchievements.contains(achievement)) {
        selectedAchievements.add(achievement);
      }
    } else {
      selectedAchievements.remove(achievement);
    }
  }

  void toggleSelectAll(bool selectAll) {
    if (selectAll) {
      selectedAchievements.clear();
      selectedAchievements.addAll(filteredAchievements);
    } else {
      selectedAchievements.clear();
    }
  }

  // Achievement Actions
  Future<void> enableAchievement(AchievementModel achievement) async {
    try {
      isLoading.value = true;

      // Simulate API call
      await Future.delayed(Duration(seconds: 1));

      // Update local data
      final index = allAchievements.indexWhere((a) => a.achievementId == achievement.achievementId);
      if (index != -1) {
        // Create updated achievement
        final updatedAchievement = AchievementModel(
          achievementId: achievement.achievementId,
          achievementTitle: achievement.achievementTitle,
          description: achievement.description,
          achievementType: achievement.achievementType,
          imagePath: achievement.imagePath,
          levels: achievement.levels,
          isActive: true,
          createdAt: achievement.createdAt,
        );

        allAchievements[index] = updatedAchievement;
        filterAchievements();
      }

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Achievement enabled successfully',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to enable achievement: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> disableAchievement(AchievementModel achievement) async {
    try {
      isLoading.value = true;

      // Simulate API call
      await Future.delayed(Duration(seconds: 1));

      // Update local data
      final index = allAchievements.indexWhere((a) => a.achievementId == achievement.achievementId);
      if (index != -1) {
        // Create updated achievement
        final updatedAchievement = AchievementModel(
          achievementId: achievement.achievementId,
          achievementTitle: achievement.achievementTitle,
          description: achievement.description,
          achievementType: achievement.achievementType,
          imagePath: achievement.imagePath,
          levels: achievement.levels,
          isActive: false,
          createdAt: achievement.createdAt,
        );

        allAchievements[index] = updatedAchievement;
        filterAchievements();
      }

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Achievement disabled successfully',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to disable achievement: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Batch Actions
  Future<void> batchEnableAchievements() async {
    try {
      isLoading.value = true;

      // Simulate API call
      await Future.delayed(Duration(seconds: 2));

      final selectedIds = selectedAchievements.map((a) => a.achievementId).toList();

      for (final achievementId in selectedIds) {
        final index = allAchievements.indexWhere((a) => a.achievementId == achievementId);
        if (index != -1) {
          final achievement = allAchievements[index];
          final updatedAchievement = AchievementModel(
            achievementId: achievement.achievementId,
            achievementTitle: achievement.achievementTitle,
            description: achievement.description,
            achievementType: achievement.achievementType,
            imagePath: achievement.imagePath,
            levels: achievement.levels,
            isActive: true,
            createdAt: achievement.createdAt,
          );
          allAchievements[index] = updatedAchievement;
        }
      }

      selectedAchievements.clear();
      filterAchievements();

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Successfully enabled ${selectedIds.length} achievements',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to enable achievements: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> batchDisableAchievements() async {
    try {
      isLoading.value = true;

      // Simulate API call
      await Future.delayed(Duration(seconds: 2));

      final selectedIds = selectedAchievements.map((a) => a.achievementId).toList();

      for (final achievementId in selectedIds) {
        final index = allAchievements.indexWhere((a) => a.achievementId == achievementId);
        if (index != -1) {
          final achievement = allAchievements[index];
          final updatedAchievement = AchievementModel(
            achievementId: achievement.achievementId,
            achievementTitle: achievement.achievementTitle,
            description: achievement.description,
            achievementType: achievement.achievementType,
            imagePath: achievement.imagePath,
            levels: achievement.levels,
            isActive: false,
            createdAt: achievement.createdAt,
          );
          allAchievements[index] = updatedAchievement;
        }
      }

      selectedAchievements.clear();
      filterAchievements();

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Successfully disabled ${selectedIds.length} achievements',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to disable achievements: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Edit Achievement
  void editAchievement(AchievementModel achievement) {
    // TODO: Implement edit achievement dialog
    TLoaders.modernSnackBar(
      title: 'Coming Soon',
      message: 'Achievement editing feature will be available soon',
    );
  }

  // Participant-based counting
  Map<String, int> getCompletionStats(AchievementModel achievement) {
    final now = DateTime.now();

    if (achievement.achievementType == 'monthly') {
      // ========== 月度成就统计逻辑 ==========
      // Get all participants for this achievement (both in_progress and completed)
      final participants = userAchievements.where((ua) =>
      ua.achievement.achievementId == achievement.achievementId &&
          (ua.status == 'in_progress' || ua.status == 'completed')
      ).toList();

      // Get unique participants (one user counted once)
      final uniqueUserIds = participants.map((ua) => ua.userAchievementId.split('_')[1]).toSet();
      final totalParticipants = uniqueUserIds.length;

      // Count participants who started today
      final todayParticipantIds = participants.where((ua) =>
      ua.startedAt.day == now.day &&
          ua.startedAt.month == now.month &&
          ua.startedAt.year == now.year
      ).map((ua) => ua.userAchievementId.split('_')[1]).toSet();

      final todayParticipants = todayParticipantIds.length;

      return {
        'total': totalParticipants,    // 总参与人数
        'recent': todayParticipants,   // 今日开始参与人数
      };

    } else {
      // ========== 永久成就统计逻辑 ==========
      // Get all completions for this achievement (only completed status)
      final completions = userAchievements.where((ua) =>
      ua.achievement.achievementId == achievement.achievementId &&
          ua.status == 'completed'
      ).toList();

      // Get unique completions (one user counted once)
      final uniqueUserIds = completions.map((ua) => ua.userAchievementId.split('_')[1]).toSet();
      final totalCompletions = uniqueUserIds.length;

      // Count completions this month (based on completedAt)
      final thisMonthCompletions = completions.where((ua) =>
      ua.completedAt!.month == now.month &&
          ua.completedAt!.year == now.year
      ).map((ua) => ua.userAchievementId.split('_')[1]).toSet();

      final thisMonthCount = thisMonthCompletions.length;

      return {
        'total': totalCompletions,     // 总完成人数
        'recent': thisMonthCount,      // 本月完成人数
      };
    }
  }

  // Updated level completion counting - cumulative approach
  int getLevelCompletions(String achievementId, String targetLevel) {
    final achievement = allAchievements.firstWhere(
            (a) => a.achievementId == achievementId,
        orElse: () => throw Exception('Achievement not found')
    );

    // Get all user achievements for this achievement
    final relevantUserAchievements = userAchievements.where((ua) =>
    ua.achievement.achievementId == achievementId
    ).toList();

    // For monthly achievements with bronze/silver/gold levels
    if (achievement.achievementType == 'monthly') {
      final levelHierarchy = ['bronze', 'silver', 'gold', 'platinum'];
      final targetLevelIndex = levelHierarchy.indexOf(targetLevel.toLowerCase());

      if (targetLevelIndex == -1) return 0;

      // Count users who have achieved this level or higher
      return relevantUserAchievements.where((ua) {
        final userLevelIndex = levelHierarchy.indexOf(ua.currentLevel.toLowerCase());
        return userLevelIndex != -1 && userLevelIndex >= targetLevelIndex;
      }).length;
    } else {
      // For permanent achievements, count exact level matches
      return relevantUserAchievements.where((ua) =>
      ua.currentLevel.toLowerCase() == targetLevel.toLowerCase()
      ).length;
    }
  }

  void showCompletionBreakdown(AchievementModel achievement) {
    // TODO: Implement completion breakdown dialog
    TLoaders.modernSnackBar(
      title: 'Achievement Stats',
      message: 'Viewing completion details for ${achievement.achievementTitle}',
    );
  }

  // Search highlighting
  List<TextSpan> getHighlightedText(String text, String query, {Color? textColor}) {
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
        spans.add(TextSpan(
          text: text.substring(start),
          style: TextStyle(color: textColor),
        ));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: TextStyle(color: textColor),
        ));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          color: textColor,
          backgroundColor: Colors.yellow.withOpacity(0.3),
          fontWeight: FontWeight.bold,
        ),
      ));

      start = index + query.length;
    }

    return spans;
  }

  // Mock Data Generation with updated logic
  List<AchievementModel> _generateMockAchievements() {
    return [
      AchievementModel(
        achievementId: 'ach_001',
        achievementTitle: 'Glucose Master',
        description: 'Maintain healthy glucose levels consistently',
        achievementType: 'monthly',
        imagePath: '',
        levels: [
          _createLevel('bronze', 7, 'days', 10),
          _createLevel('silver', 15, 'days', 25),
          _createLevel('gold', 30, 'days', 50),
        ],
        isActive: true,
        createdAt: DateTime.now().subtract(Duration(days: 30)),
      ),
      AchievementModel(
        achievementId: 'ach_002',
        achievementTitle: 'Step Counter Champion',
        description: 'Complete your daily step goals',
        achievementType: 'monthly',
        imagePath: '',
        levels: [
          _createLevel('bronze', 10000, 'steps', 15),
          _createLevel('silver', 15000, 'steps', 30),
          _createLevel('gold', 20000, 'steps', 60),
        ],
        isActive: true,
        createdAt: DateTime.now().subtract(Duration(days: 45)),
      ),
      AchievementModel(
        achievementId: 'ach_003',
        achievementTitle: 'Community Helper',
        description: 'Help other users by sharing tips and recipes',
        achievementType: 'permanent',
        imagePath: '',
        levels: [
          _createLevel('Helper', 50, 'posts', 0),
        ],
        isActive: true,
        createdAt: DateTime.now().subtract(Duration(days: 60)),
      ),
      AchievementModel(
        achievementId: 'ach_004',
        achievementTitle: 'Meal Planner Pro',
        description: 'Create and follow meal plans consistently',
        achievementType: 'monthly',
        imagePath: '',
        levels: [
          _createLevel('bronze', 7, 'meals planned', 20),
          _createLevel('silver', 14, 'meals planned', 40),
          _createLevel('gold', 21, 'meals planned', 80),
        ],
        isActive: false,
        createdAt: DateTime.now().subtract(Duration(days: 90)),
      ),
      AchievementModel(
        achievementId: 'ach_005',
        achievementTitle: 'Early Bird',
        description: 'Log your morning glucose readings consistently',
        achievementType: 'permanent',
        imagePath: '',
        levels: [
          _createLevel('Morning Person', 30, 'consecutive days', 0),
        ],
        isActive: true,
        createdAt: DateTime.now().subtract(Duration(days: 120)),
      ),
    ];
  }

  AchievementLevelModel _createLevel(String level, int criteria, String unit, int points) {
    return AchievementLevelModel(level: level, criteria: criteria, criteriaUnit: unit, points: points);
  }

  List<UserAchievementModel> _generateMockUserAchievements() {
    final List<UserAchievementModel> mockData = [];
    final achievementIds = ['ach_001', 'ach_002', 'ach_003', 'ach_004', 'ach_005'];
    final now = DateTime.now();

    // Generate realistic participant data
    int userIdCounter = 1;

    for (String achievementId in achievementIds) {
      final achievement = allAchievements.firstWhere((a) => a.achievementId == achievementId);

      if (achievement.achievementType == 'monthly') {
        // Monthly achievements: bronze < silver < gold (cumulative)

        // Gold level participants (20 people) - they also count for silver and bronze
        for (int i = 0; i < 20; i++) {
          mockData.add(UserAchievementModel(
            userAchievementId: 'ua_${userIdCounter}_$achievementId',
            achievement: achievement,
            currentLevel: 'gold',
            currentCount: 30 + i, // Meets gold criteria
            status: i < 15 ? 'completed' : 'in_progress',
            startedAt: now.subtract(Duration(days: i + 1)),
            completedAt: i < 15 ? now.subtract(Duration(days: i)) : null,
          ));
          userIdCounter++;
        }

        // Silver level participants (25 people) - they also count for bronze
        for (int i = 0; i < 25; i++) {
          mockData.add(UserAchievementModel(
            userAchievementId: 'ua_${userIdCounter}_$achievementId',
            achievement: achievement,
            currentLevel: 'silver',
            currentCount: 15 + i, // Meets silver but not gold criteria
            status: i < 20 ? 'completed' : 'in_progress',
            startedAt: now.subtract(Duration(days: i + 5)),
            completedAt: i < 20 ? now.subtract(Duration(days: i + 3)) : null,
          ));
          userIdCounter++;
        }

        // Bronze level participants (35 people)
        for (int i = 0; i < 35; i++) {
          mockData.add(UserAchievementModel(
            userAchievementId: 'ua_${userIdCounter}_$achievementId',
            achievement: achievement,
            currentLevel: 'bronze',
            currentCount: 7 + i, // Meets bronze but not silver criteria
            status: i < 30 ? 'completed' : 'in_progress',
            startedAt: now.subtract(Duration(days: i + 10)),
            completedAt: i < 30 ? now.subtract(Duration(days: i + 8)) : null,
          ));
          userIdCounter++;
        }

        // Add some participants who started today for "today participants" count
        for (int i = 0; i < 5; i++) {
          mockData.add(UserAchievementModel(
            userAchievementId: 'ua_${userIdCounter}_$achievementId',
            achievement: achievement,
            currentLevel: 'bronze',
            currentCount: i + 1,
            status: 'in_progress',
            startedAt: now, // Started today
            completedAt: null,
          ));
          userIdCounter++;
        }

      } else {
        // Permanent achievements: exact level matches
        final levelName = achievement.levels.first.level;

        for (int i = 0; i < 40; i++) {
          mockData.add(UserAchievementModel(
            userAchievementId: 'ua_${userIdCounter}_$achievementId',
            achievement: achievement,
            currentLevel: levelName,
            currentCount: achievement.levels.first.criteria + i,
            status: 'completed',
            startedAt: now.subtract(Duration(days: i + 20)),
            completedAt: now.subtract(Duration(days: i + 35)),
          ));
          userIdCounter++;
        }

        // Add some who completed this month
        for (int i = 0; i < 3; i++) {
          mockData.add(UserAchievementModel(
            userAchievementId: 'ua_${userIdCounter}_$achievementId',
            achievement: achievement,
            currentLevel: levelName,
            currentCount: i + 1,
            status: 'completed',
            startedAt: now.subtract(Duration(days: i + 20)), // Started today
            completedAt: now.subtract(Duration(days: i + 5)),
          ));
          userIdCounter++;
        }
      }
    }

    return mockData;
  }
}