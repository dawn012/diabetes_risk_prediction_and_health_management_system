import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/reward/reward_reporsitory.dart';
import '../../authentication/models/user_model.dart';
import '../../reward/models/user_reward_model.dart';
import 'user_controller.dart';

class AvatarFrameController extends GetxController {
  static AvatarFrameController get instance => Get.find();

  final _rewardRepo = Get.put(RewardRepository());

  // 不再需要 UserRepository，直接使用 UserController
  final isLoading = false.obs;
  final userAvatarFrames = <UserRewardModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    initializeData();
  }

  /// 初始化数据
  Future<void> initializeData() async {
    try {
      await fetchUserAvatarFrames();
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to initialize avatar frame data: ${e.toString()}',
      );
    }
  }

  /// 获取当前用户ID
  String get _currentUserId {
    final userController = Get.find<UserController>();
    return userController.user.value.userId;
  }

  /// 获取当前用户信息
  UserModel get _currentUser {
    final userController = Get.find<UserController>();
    return userController.user.value;
  }

  /// Fetch user's avatar frames
  Future<void> fetchUserAvatarFrames() async {
    try {
      isLoading.value = true;

      final frames = await _rewardRepo.fetchUserAvatarFrames(_currentUserId);

      // 使用赋值方式确保 Obx 能检测到变化
      userAvatarFrames.assignAll(frames);

    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to load avatar frames: ${e.toString()}',
      );
      userAvatarFrames.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// Apply avatar frame
  Future<void> applyAvatarFrame(String rewardId) async {
    try {
      await _rewardRepo.applyAvatarFrame(_currentUserId, rewardId);

      // 刷新用户数据（通过 UserController）
      final userController = Get.find<UserController>();
      await userController.fetchUserRecord();

      // 刷新框架列表
      userAvatarFrames.refresh();

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Avatar frame applied successfully!',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to apply avatar frame: ${e.toString()}',
      );
    }
  }

  /// Remove avatar frame
  Future<void> removeAvatarFrame() async {
    try {
      await _rewardRepo.removeAvatarFrame(_currentUserId);

      // 刷新用户数据（通过 UserController）
      final userController = Get.find<UserController>();
      await userController.fetchUserRecord();

      // 刷新框架列表
      userAvatarFrames.refresh();

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Avatar frame removed successfully!',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to remove avatar frame: ${e.toString()}',
      );
    }
  }

  /// Check if this reward is currently applied
  bool isCurrentlyApplied(String rewardId) {
    return _currentUser.currentAvatarFrame == rewardId;
  }

  /// Get current frame
  UserRewardModel? getCurrentFrame() {
    final currentFrameId = _currentUser.currentAvatarFrame;
    if (currentFrameId == null) return null;

    try {
      return userAvatarFrames.firstWhere(
            (frame) => frame.reward.rewardId == currentFrameId,
      );
    } catch (e) {
      return null;
    }
  }

  /// 根据ID获取头像框
  UserRewardModel? getCurrentFrameById(String frameId) {
    try {
      return userAvatarFrames.firstWhere(
            (frame) => frame.reward.rewardId == frameId,
      );
    } catch (e) {
      return null;
    }
  }
}