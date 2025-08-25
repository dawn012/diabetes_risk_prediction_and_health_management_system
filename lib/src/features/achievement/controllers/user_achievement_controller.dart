import 'package:get/get.dart';
import '../models/achievement_model.dart';
import '../models/user_achievement_model.dart';
import 'achievement_controller.dart';

class UserAchievementController extends GetxController {
  static UserAchievementController get instance => Get.find();

  // Observable variables
  var selectedTab = 0.obs; // 0 for Periodic, 1 for Permanent
  var selectedFilter = 'all'.obs; // all, locked, unlocked, bronze, silver, gold
  var userAchievements = <UserAchievementModel>[].obs; // 用户实际的成就记录
  var expandedAchievements = <String>[].obs; // Track which achievements are expanded
  var isLoading = false.obs;

  // 获取 AchievementController 实例
  late AchievementController achievementController;

  @override
  void onInit() {
    super.onInit();
    achievementController = Get.find<AchievementController>();
    loadUserAchievements();
  }

  /// 加载用户成就数据 (后续替换为 Firestore 调用)
  Future<void> loadUserAchievements() async {
    try {
      isLoading.value = true;

      // 模拟网络延迟
      await Future.delayed(Duration(milliseconds: 800));

      // TODO: 替换为实际的 Firestore 调用
      // final userAchievementsData = await FirebaseFirestore.instance
      //     .collection('user_achievements')
      //     .where('userId', isEqualTo: currentUserId)
      //     .get();

      userAchievements.value = _getMockUserAchievements();

    } catch (e) {
      Get.snackbar('Error', 'Failed to load user achievements: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// 模拟用户成就数据（后续移除）
  List<UserAchievementModel> _getMockUserAchievements() {
    return [
      UserAchievementModel(
        userAchievementId: '1',
        achievement: achievementController.getAchievementById('1')!,
        currentLevel: 'Gold',
        currentCount: 90,
        status: 'completed',
        startedAt: DateTime.now().subtract(Duration(days: 90)),
        completedAt: DateTime.now(),
      ),
      UserAchievementModel(
        userAchievementId: '2',
        achievement: achievementController.getAchievementById('2')!,
        currentLevel: 'Silver',
        currentCount: 12,
        status: 'in_progress',
        startedAt: DateTime.now().subtract(Duration(days: 15)),
        completedAt: DateTime(0),
      ),
      UserAchievementModel(
        userAchievementId: '4',
        achievement: achievementController.getAchievementById('4')!,
        currentLevel: 'none',
        currentCount: 20,
        status: 'in_progress',
        startedAt: DateTime.now().subtract(Duration(days: 60)),
        completedAt: DateTime(0),
      ),
    ];
  }

  // 组合显示数据：系统成就 + 用户进度
  List<Map<String, dynamic>> get displayAchievements {
    String type = selectedTab.value == 0 ? 'periodic' : 'permanent';
    var systemAchievements = achievementController.getAchievementsByType(type);

    return systemAchievements.map((achievement) {
      var userAchievement = userAchievements.firstWhereOrNull(
              (ua) => ua.achievement.achievementId == achievement.achievementId
      );

      return {
        'achievement': achievement,
        'userAchievement': userAchievement,
        'isLocked': userAchievement == null,
        'currentLevel': userAchievement?.currentLevel ?? 'none',
        'currentCount': userAchievement?.currentCount ?? 0,
        'status': userAchievement?.status ?? 'locked',
      };
    }).toList();
  }

  // 过滤后的成就
  List<Map<String, dynamic>> get filteredAchievements {
    var achievements = displayAchievements;

    // Apply filter
    if (selectedFilter.value != 'all') {
      achievements = achievements.where((item) {
        if (selectedFilter.value == 'locked') {
          return item['isLocked'] as bool;
        }

        if (item['isLocked'] as bool) {
          return false; // locked achievements don't match unlocked/medal filters
        }

        if (selectedFilter.value == 'unlocked') {
          return !(item['isLocked'] as bool) && item['currentLevel'] == 'none';
        }

        String medal = (item['currentLevel'] as String).toLowerCase();
        return medal == selectedFilter.value;
      }).toList();
    }

    return achievements;
  }

  // Get completed achievements count (only for 'all' filter)
  int get completedCount {
    if (selectedFilter.value != 'all') return 0;
    return displayAchievements.where((item) =>
    !(item['isLocked'] as bool) && item['status'] == 'completed').length;
  }

  // Get total achievements count (only for 'all' filter)
  int get totalCount {
    if (selectedFilter.value != 'all') return 0;
    return displayAchievements.length;
  }

  // Should show progress counter
  bool get shouldShowProgress {
    return selectedFilter.value == 'all';
  }

  // Change tab
  void changeTab(int index) {
    selectedTab.value = index;
    selectedFilter.value = 'all'; // Reset filter when changing tab
    expandedAchievements.clear(); // Clear expanded state
  }

  // Change filter
  void changeFilter(String filter) {
    selectedFilter.value = filter;
    expandedAchievements.clear(); // Clear expanded state when filtering
  }

  // Toggle achievement expansion
  void toggleAchievement(String achievementId) {
    if (expandedAchievements.contains(achievementId)) {
      expandedAchievements.remove(achievementId);
    } else {
      expandedAchievements.add(achievementId);
    }
  }

  // Check if achievement is expanded
  bool isAchievementExpanded(String achievementId) {
    return expandedAchievements.contains(achievementId);
  }

  // Get medal type based on current level
  String getMedalType(Map<String, dynamic> achievementData) {
    if (achievementData['isLocked'] as bool) {
      return 'locked';
    }
    if (achievementData['currentLevel'] == 'none') {
      return 'unlocked';
    }
    return (achievementData['currentLevel'] as String).toLowerCase();
  }

  // Get progress percentage
  double getProgress(Map<String, dynamic> achievementData) {
    if (achievementData['isLocked'] as bool) return 0.0;
    if (achievementData['status'] == 'completed') return 1.0;

    AchievementModel achievement = achievementData['achievement'] as AchievementModel;
    if (achievement.levels.isEmpty) return 0.0;

    int currentCount = achievementData['currentCount'] as int;
    String currentLevel = achievementData['currentLevel'] as String;

    // 还没拿到任何等级
    if (currentLevel == 'none') {
      var firstLevel = achievement.levels.first;
      return (currentCount / firstLevel.criteria).clamp(0.0, 1.0);
    }

    int currentIndex = achievement.levels.indexWhere(
          (level) => level.level == currentLevel,
    );

    // 已经是最后等级
    if (currentIndex == -1 || currentIndex == achievement.levels.length - 1) {
      return 1.0;
    }

    var nextLevelData = achievement.levels[currentIndex + 1];
    return (currentCount / nextLevelData.criteria).clamp(0.0, 1.0);
  }

  // Get progress text with unit
  String getProgressText(Map<String, dynamic> achievementData) {
    if (achievementData['isLocked'] as bool) return 'Locked';
    if (achievementData['status'] == 'completed') return 'Completed';

    AchievementModel achievement = achievementData['achievement'] as AchievementModel;
    if (achievement.levels.isEmpty) return '0/0';

    int currentCount = achievementData['currentCount'] as int;
    String currentLevel = achievementData['currentLevel'] as String;

    // 还没开始拿到等级
    if (currentLevel == 'none') {
      var firstLevel = achievement.levels.first;
      return '$currentCount/${firstLevel.criteria} ${firstLevel.criteriaUnit}';
    }

    int currentIndex = achievement.levels.indexWhere(
          (level) => level.level == currentLevel,
    );

    if (currentIndex == -1 || currentIndex == achievement.levels.length - 1) {
      return '$currentCount/$currentCount';
    }

    var nextLevelData = achievement.levels[currentIndex + 1];
    return '$currentCount/${nextLevelData.criteria} ${nextLevelData.criteriaUnit}';
  }

  // Helper method to check if a level is achieved
  bool isLevelAchieved(Map<String, dynamic> achievementData, String levelName) {
    if (achievementData['isLocked'] as bool) return false;

    AchievementModel achievement = achievementData['achievement'] as AchievementModel;
    String currentLevel = achievementData['currentLevel'] as String;

    if (currentLevel == 'none') return false;

    final levels = achievement.levels;
    final currentLevelIndex = levels.indexWhere((l) => l.level == currentLevel);
    final targetLevelIndex = levels.indexWhere((l) => l.level == levelName);

    return currentLevelIndex >= targetLevelIndex;
  }

  /// 刷新数据 (供 UI 调用)
  Future<void> refreshData() async {
    await loadUserAchievements();
  }
}