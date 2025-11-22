import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/achievement/achievement_repository.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../utils/constants/enums.dart';
import '../../achievement/models/achievement_level_model.dart';
import '../../achievement/models/achievement_model.dart';
import '../../achievement/models/user_achievement_model.dart';
import '../views/achievement_management/achievement_detail_dialog.dart';
import '../views/achievement_management/edit_achievement_dialog.dart';

class AchievementManagementController extends GetxController {
  static AchievementManagementController get instance => Get.find();

  // Repositories
  final _achievementRepo = Get.put(AchievementRepository());
  final _authRepo = AuthenticationRepository.instance;

  // Observables
  final isLoading = false.obs;
  final currentPage = 1.obs;
  final itemsPerPage = 10.obs;
  final totalPages = 1.obs;
  final showingActiveAchievements = true.obs;
  final selectedAchievementType = 'all'.obs;
  final sortColumnIndex = 4.obs; // Default sort by updatedAt
  final sortAscending = false.obs; // Newest first

  // Edit Dialog State Management
  final editFormKey = GlobalKey<FormState>();
  final editTitleController = TextEditingController();
  final editDescriptionController = TextEditingController();
  final editSelectedType = AchievementType.permanent.obs;
  final editSelectedIconCodePoint = 0.obs;
  final editLevels = <AchievementLevelModel>[].obs;
  final editIsLoading = false.obs;
  final isEditingAchievement = false.obs;
  final editingAchievement = Rx<AchievementModel?>(null);
  final editCustomIconCodePoint = Rx<int?>(null); // Track custom icon
  final editTitleDuplicationError = ''.obs;

  // Preset icons for quick selection
  final List<int> editPresetIcons = [
    Icons.emoji_events.codePoint,
    Icons.star.codePoint,
    Icons.favorite.codePoint,
    // Icons.local_fire_department.codePoint,
    Icons.workspace_premium.codePoint,
    Icons.military_tech.codePoint,
    Icons.celebration.codePoint,
    Icons.verified.codePoint,
  ];

  // Data
  final allAchievements = <AchievementModel>[].obs;
  final filteredAchievements = <AchievementModel>[].obs;
  final selectedAchievements = <AchievementModel>[].obs;
  final paginatedAchievements = <AchievementModel>[].obs;
  final userAchievements = <UserAchievementModel>[].obs;

  // Controllers
  final searchController = TextEditingController();

  // Stream subscriptions
  StreamSubscription<List<AchievementModel>>? _achievementsSubscription;
  StreamSubscription<List<UserAchievementModel>>? _userAchievementsSubscription;

  // Constants
  final List<int> itemsPerPageOptions = [5, 10, 25, 50];
  final List<String> achievementTypes = ['all', 'periodic', 'permanent'];

  @override
  void onInit() {
    super.onInit();
    checkPermissionAndLoad();
    setupSearchListener();
  }

  @override
  void onClose() {
    editTitleController.dispose();
    editDescriptionController.dispose();
    searchController.dispose();
    _achievementsSubscription?.cancel();
    _userAchievementsSubscription?.cancel();
    super.onClose();
  }

  void setupSearchListener() {
    searchController.addListener(() {
      filterAchievements();
    });
  }

  // Permission Check
  Future<void> checkPermissionAndLoad() async {
    try {
      isLoading.value = true;

      // Get current user role
      final userRole = await _authRepo.getUserRole();

      if (userRole != 'admin' && userRole != 'achievement manager') {
        TLoaders.errorSnackBar(
          title: 'Access Denied',
          message: 'You do not have permission to access achievement management',
        );
        Get.back(); // Navigate back
        return;
      }

      // If permission granted, load data
      await loadAchievements();
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to verify permissions: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  bool get hasPermission {
    final userRole = _authRepo.userRole.value;
    return userRole == 'admin' || userRole == 'achievement manager';
  }

  // Data Loading with Streams
  Future<void> loadAchievements() async {
    try {
      isLoading.value = true;

      // Subscribe to achievements stream
      _achievementsSubscription?.cancel();
      _achievementsSubscription = _achievementRepo
          .getAllAchievementsForAdminStream()
          .listen(
            (achievements) {
          allAchievements.value = achievements;
          filterAchievements();
        },
        onError: (error) {
          TLoaders.errorSnackBar(
            title: 'Error',
            message: 'Failed to load achievements: $error',
          );
        },
      );

      // Subscribe to user achievements stream for statistics
      _userAchievementsSubscription?.cancel();
      _userAchievementsSubscription = _achievementRepo
          .getAllUserAchievementsStream()
          .listen(
            (userAchs) {
          userAchievements.value = userAchs;
        },
        onError: (error) {
          print('Failed to load user achievements: $error');
        },
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to load achievements: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshAchievements() async {
    currentPage.value = 1;
    selectedAchievements.clear();
    _updatePaginatedData();
    // No need to reload, stream handles it automatically
    TLoaders.successSnackBar(
      title: 'Success',
      message: 'Achievements refreshed successfully',
    );
  }

  /// Check for title duplication
  String? checkTitleDuplication(String currentAchievementId) {
    final title = editTitleController.text.trim();

    if (title.isNotEmpty && title != editingAchievement.value?.achievementTitle) {
      final isDuplicate = allAchievements.any((achievement) =>
      achievement.achievementId != currentAchievementId &&
          achievement.achievementTitle.toLowerCase() == title.toLowerCase());

      if (isDuplicate) {
        return 'Achievement title already exists.';
      }
    }
    return null;
  }

  /// Validate edit form including duplication check
  bool validateEditForm(AchievementModel originalAchievement) {
    // Clear previous duplication error
    editTitleDuplicationError.value = '';

    bool hasFormErrors = false;

    // 1. 检查表单基础验证
    if (!editFormKey.currentState!.validate()) {
      hasFormErrors = true;
    }

    // 2. 检查标题重复（同时进行）
    final duplicationError = checkTitleDuplication(originalAchievement.achievementId);
    if (duplicationError != null) {
      editTitleDuplicationError.value = duplicationError;
      hasFormErrors = true;
    }

    editFormKey.currentState!.validate();

    return !hasFormErrors;
  }

  // Get paginated data for current page
  void _updatePaginatedData() {
    final startIndex = (currentPage.value - 1) * itemsPerPage.value;
    final endIndex = (currentPage.value * itemsPerPage.value)
        .clamp(0, filteredAchievements.length);

    paginatedAchievements.value = filteredAchievements.sublist(
      startIndex,
      endIndex,
    );
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
          achievement.achievementType.value == selectedAchievementType.value;

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
    selectedAchievements.clear();
    _updatePagination();
    _updatePaginatedData();
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
          aValue = a.achievementType.value;
          bValue = b.achievementType.value;
          break;
        case 2: // Levels count
          aValue = a.levels.length;
          bValue = b.levels.length;
          break;
        case 3: // Participants
          aValue = getCompletionStats(a)['total'] ?? 0;
          bValue = getCompletionStats(b)['total'] ?? 0;
          break;
        case 4: // Updated date (default)
          aValue = a.updatedAt;
          bValue = b.updatedAt;
          break;
        case 5: // Status
          aValue = a.isActive ? 1 : 0;
          bValue = b.isActive ? 1 : 0;
          break;
        default:
          aValue = a.updatedAt; // Default to updatedAt
          bValue = b.updatedAt;
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

    // 确保当前页至少为1
    if (currentPage.value < 1 && totalPages.value > 0) {
      currentPage.value = 1;
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
      _updatePaginatedData();
    }
  }

  void changePage(int page) {
    currentPage.value = page;
    _updatePaginatedData();
  }

  void sortAchievements(int columnIndex, bool ascending) {
    sortColumnIndex.value = columnIndex;
    sortAscending.value = ascending;
    filterAchievements();
  }

  // Selection Management - FIXED: Force UI update
  void toggleAchievementSelection(AchievementModel achievement, bool selected) {
    if (selected) {
      if (!selectedAchievements.contains(achievement)) {
        selectedAchievements.add(achievement);
      }
    } else {
      selectedAchievements.remove(achievement);
    }
    // Force UI update
    selectedAchievements.refresh();
  }

  void toggleSelectAll(bool selectAll) {
    if (selectAll) {
      selectedAchievements.clear();
      selectedAchievements.addAll(paginatedAchievements);
    } else {
      selectedAchievements.clear();
    }
    // Force UI update
    selectedAchievements.refresh();
  }

  // Achievement Actions
  Future<void> enableAchievement(AchievementModel achievement) async {
    if (!hasPermission) {
      TLoaders.errorSnackBar(
        title: 'Permission Denied',
        message: 'You do not have permission to enable achievements',
      );
      return;
    }

    try {
      isLoading.value = true;
      await _achievementRepo.toggleAchievementStatus(achievement.achievementId, true);

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
    if (!hasPermission) {
      TLoaders.errorSnackBar(
        title: 'Permission Denied',
        message: 'You do not have permission to disable achievements',
      );
      return;
    }

    try {
      isLoading.value = true;
      await _achievementRepo.toggleAchievementStatus(achievement.achievementId, false);

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
    if (!hasPermission) {
      TLoaders.errorSnackBar(
        title: 'Permission Denied',
        message: 'You do not have permission to enable achievements',
      );
      return;
    }

    try {
      isLoading.value = true;
      final selectedIds = selectedAchievements.map((a) => a.achievementId).toList();

      await _achievementRepo.batchToggleAchievementStatus(selectedIds, true);

      selectedAchievements.clear();

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
    if (!hasPermission) {
      TLoaders.errorSnackBar(
        title: 'Permission Denied',
        message: 'You do not have permission to disable achievements',
      );
      return;
    }

    try {
      isLoading.value = true;
      final selectedIds = selectedAchievements.map((a) => a.achievementId).toList();

      await _achievementRepo.batchToggleAchievementStatus(selectedIds, false);

      selectedAchievements.clear();

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

  // Open view achievement detail dialog
  void openViewAchievementDetailDialog(AchievementModel achievement) {
    if (!hasPermission) {
      TLoaders.errorSnackBar(
        title: 'Permission Denied',
        message: 'You do not have permission to view achievement details',
      );
      return;
    }

    Get.dialog(
      AchievementDetailDialog(
        achievement: achievement,
        controller: this,
      ),
    );
  }

  // Open edit achievement dialog
  void openEditAchievementDialog(AchievementModel achievement) {
    if (!hasPermission) {
      TLoaders.errorSnackBar(
        title: 'Permission Denied',
        message: 'You do not have permission to edit achievements',
      );
      return;
    }

    editingAchievement.value = achievement;
    initializeEditDialog(achievement);
    isEditingAchievement.value = true;

    Get.dialog(
      EditAchievementDialog(
        achievement: achievement,
        controller: this,
      ),
      barrierDismissible: false,
    );
  }

  // Initialize edit dialog
  void initializeEditDialog(AchievementModel achievement) {
    editTitleController.text = achievement.achievementTitle;
    editDescriptionController.text = achievement.description;
    editSelectedType.value = achievement.achievementType;
    editSelectedIconCodePoint.value = achievement.iconCodePoint;
    editLevels.assignAll(List.from(achievement.levels));
    editIsLoading.value = false;

    // Check if icon is custom or preset
    if (editPresetIcons.contains(achievement.iconCodePoint)) {
      editCustomIconCodePoint.value = null;
    } else {
      editCustomIconCodePoint.value = achievement.iconCodePoint;
    }
  }

  // Update level criteria
  void updateLevelCriteria(int index, int criteria) {
    if (index >= 0 && index < editLevels.length) {
      final level = editLevels[index];
      editLevels[index] = level.copyWith(criteria: criteria);
    }
  }

  // Update level points
  void updateLevelPoints(int index, int points) {
    if (index >= 0 && index < editLevels.length) {
      final level = editLevels[index];
      editLevels[index] = level.copyWith(points: points);
    }
  }

  // FIXED: Check if there are changes
  bool hasChanges(AchievementModel originalAchievement) {
    if (editTitleController.text.trim() != originalAchievement.achievementTitle) return true;
    if (editDescriptionController.text.trim() != originalAchievement.description) return true;
    if (editSelectedType.value != originalAchievement.achievementType) return true;
    if (editSelectedIconCodePoint.value != originalAchievement.iconCodePoint) return true;

    // Check levels
    if (editLevels.length != originalAchievement.levels.length) return true;
    for (int i = 0; i < editLevels.length; i++) {
      if (editLevels[i].criteria != originalAchievement.levels[i].criteria) return true;
      if (editLevels[i].points != originalAchievement.levels[i].points) return true;
    }

    return false;
  }

  // Handle save edit
  Future<void> handleSaveEdit(AchievementModel originalAchievement) async {
    if (!validateEditForm(originalAchievement)) {
      return;
    }

    // Check if there are any changes
    if (!hasChanges(originalAchievement)) {
      TLoaders.warningSnackBar(
        title: 'No Changes',
        message: 'No changes were made to the achievement',
      );
      return;
    }

    editIsLoading.value = true;

    try {
      final updatedAchievement = originalAchievement.copyWith(
        achievementTitle: editTitleController.text.trim(),
        description: editDescriptionController.text.trim(),
        achievementType: editSelectedType.value,
        iconCodePoint: editSelectedIconCodePoint.value,
        levels: editLevels,
      );

      await updateAchievement(updatedAchievement);
      closeEditDialog();
    } catch (e) {
      // Error already handled in controller
    } finally {
      editIsLoading.value = false;
    }
  }

  // Close edit dialog
  void closeEditDialog() {
    editingAchievement.value = null;
    editTitleController.clear();
    editDescriptionController.clear();
    editLevels.clear();
    editIsLoading.value = false;
    isEditingAchievement.value = false;
    editCustomIconCodePoint.value = null;

    if (Get.context != null) {
      Navigator.of(Get.context!, rootNavigator: true).pop(true);
    }
  }

  // Update achievement from edit dialog
  Future<void> updateAchievement(AchievementModel achievement) async {
    if (!hasPermission) {
      TLoaders.errorSnackBar(
        title: 'Permission Denied',
        message: 'You do not have permission to update achievements',
      );
      return;
    }

    try {
      isLoading.value = true;
      await _achievementRepo.updateAchievementForAdmin(achievement);

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Achievement updated successfully',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to update achievement: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Get achievement count by type
  int getAchievementCountByType(String type) {
    if (type == 'all') {
      return allAchievements.length;
    }
    return allAchievements.where((achievement) =>
    achievement.achievementType.value == type
    ).length;
  }

  // Statistics Methods
  Map<String, int> getCompletionStats(AchievementModel achievement) {
    final now = DateTime.now();

    if (achievement.achievementType == AchievementType.periodic) {
      final participants = userAchievements.where((ua) =>
      ua.achievement.achievementId == achievement.achievementId &&
          (ua.status == AchievementStatus.inProgress || ua.status == AchievementStatus.completed)
      ).toList();

      final uniqueUserIds = participants.map((ua) => ua.userAchievementId.split('_')[1]).toSet();
      final totalParticipants = uniqueUserIds.length;

      final todayParticipantIds = participants.where((ua) =>
      ua.startedAt.day == now.day &&
          ua.startedAt.month == now.month &&
          ua.startedAt.year == now.year
      ).map((ua) => ua.userAchievementId.split('_')[1]).toSet();

      final todayParticipants = todayParticipantIds.length;

      return {
        'total': totalParticipants,
        'recent': todayParticipants,
      };
    } else {
      final completions = userAchievements.where((ua) =>
      ua.achievement.achievementId == achievement.achievementId &&
          ua.status == AchievementStatus.completed
      ).toList();

      final uniqueUserIds = completions.map((ua) => ua.userAchievementId.split('_')[1]).toSet();
      final totalCompletions = uniqueUserIds.length;

      final thisMonthCompletions = completions.where((ua) =>
      ua.completedAt!.month == now.month &&
          ua.completedAt!.year == now.year
      ).map((ua) => ua.userAchievementId.split('_')[1]).toSet();

      final thisMonthCount = thisMonthCompletions.length;

      return {
        'total': totalCompletions,
        'recent': thisMonthCount,
      };
    }
  }

  int getLevelCompletions(String achievementId, String targetLevel) {
    final achievement = allAchievements.firstWhere(
            (a) => a.achievementId == achievementId,
        orElse: () => throw Exception('Achievement not found')
    );

    final relevantUserAchievements = userAchievements.where((ua) =>
    ua.achievement.achievementId == achievementId
    ).toList();

    if (achievement.achievementType == AchievementType.periodic) {
      final levelHierarchy = [UserAchievementLevel.bronze, UserAchievementLevel.silver, UserAchievementLevel.gold];
      final targetLevelEnum = UserAchievementLevel.fromString(targetLevel.toLowerCase());
      final targetLevelIndex = levelHierarchy.indexOf(targetLevelEnum);

      if (targetLevelIndex == -1) return 0;

      return relevantUserAchievements.where((ua) {
        final userLevelIndex = levelHierarchy.indexOf(ua.currentLevel);
        return userLevelIndex != -1 && userLevelIndex >= targetLevelIndex;
      }).length;
    } else {
      final targetLevelEnum = UserAchievementLevel.fromString(targetLevel.toLowerCase());
      return relevantUserAchievements.where((ua) =>
      ua.currentLevel == targetLevelEnum
      ).length;
    }
  }

  void showCompletionBreakdown(AchievementModel achievement) {
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
}