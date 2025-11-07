import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/achievement/achievement_repository.dart';
import '../../../utils/constants/enums.dart';
import '../models/achievement_model.dart';

class AchievementController extends GetxController {
  static AchievementController get instance => Get.find();

  final AchievementRepository _achievementRepository =
  Get.put(AchievementRepository());

  // Observable achievements list (from stream)
  final allAchievements = <AchievementModel>[].obs;

  // Loading state
  final isLoading = false.obs;

  // Error message
  final errorMessage = RxString('');

  @override
  void onInit() {
    super.onInit();
    _setupAchievementsStream();
  }

  /// Setup real-time achievements stream
  void _setupAchievementsStream() {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      _achievementRepository.getAllAchievementsStream().listen(
            (achievements) {
          allAchievements.value = achievements;
          isLoading.value = false;
        },
        onError: (error) {
          errorMessage.value = 'Failed to load achievements: ${error.toString()}';
          isLoading.value = false;
          TLoaders.errorSnackBar(
            title: 'Error',
            message: errorMessage.value,
          );
        },
      );
    } catch (e) {
      errorMessage.value = 'Failed to setup achievements stream: ${e.toString()}';
      isLoading.value = false;
      TLoaders.errorSnackBar(
        title: 'Error',
        message: errorMessage.value,
      );
    }
  }

  // ---------- Public Query Methods ----------

  /// Get achievement by ID
  AchievementModel? getAchievementById(String achievementId) {
    return allAchievements.firstWhereOrNull(
          (achievement) => achievement.achievementId == achievementId,
    );
  }

  /// Get achievements by type
  List<AchievementModel> getAchievementsByType(AchievementType type) {
    return allAchievements
        .where((achievement) =>
    achievement.achievementType == type && achievement.isActive)
        .toList();
  }

  /// Get all active achievements
  List<AchievementModel> getActiveAchievements() {
    return allAchievements.where((achievement) => achievement.isActive).toList();
  }

  /// Get periodic achievements
  List<AchievementModel> get periodicAchievements =>
      getAchievementsByType(AchievementType.periodic);

  /// Get permanent achievements
  List<AchievementModel> get permanentAchievements =>
      getAchievementsByType(AchievementType.permanent);

  /// Refresh achievements (force reload from Firestore)
  Future<void> refreshAchievements() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Stream will automatically update the allAchievements list
      // Just show a success message
      await Future.delayed(Duration(milliseconds: 500));

      isLoading.value = false;
      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Achievements refreshed',
      );
    } catch (e) {
      errorMessage.value = 'Failed to refresh achievements: ${e.toString()}';
      isLoading.value = false;
      TLoaders.errorSnackBar(
        title: 'Error',
        message: errorMessage.value,
      );
    }
  }

  /// Check if achievement exists
  bool achievementExists(String achievementId) {
    return getAchievementById(achievementId) != null;
  }

  /// Get achievement by title (for search/filter)
  List<AchievementModel> searchAchievements(String query) {
    if (query.isEmpty) return allAchievements;

    final lowerQuery = query.toLowerCase();
    return allAchievements
        .where((achievement) =>
    achievement.achievementTitle.toLowerCase().contains(lowerQuery) ||
        achievement.description.toLowerCase().contains(lowerQuery))
        .toList();
  }

  // ---------- Admin Methods ----------

  /// Create a new achievement (Admin only)
  Future<void> createAchievement(AchievementModel achievement) async {
    try {
      isLoading.value = true;
      await _achievementRepository.createAchievement(achievement);
      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Achievement created successfully',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to create achievement: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Update an achievement (Admin only)
  Future<void> updateAchievement(AchievementModel achievement) async {
    try {
      isLoading.value = true;
      await _achievementRepository.updateAchievement(achievement);
      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Achievement updated successfully',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to update achievement: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete an achievement (Admin only)
  Future<void> deleteAchievement(String achievementId) async {
    try {
      isLoading.value = true;
      await _achievementRepository.deleteAchievement(achievementId);
      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Achievement deleted successfully',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to delete achievement: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }
}