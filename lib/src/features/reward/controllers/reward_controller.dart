import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/reward/reward_reporsitory.dart';
import '../../../data/repositories/user/user_repository.dart';
import '../../../utils/constants/enums.dart';
import '../../authentication/models/user_model.dart';
import '../models/reward_model.dart';
import '../models/user_reward_model.dart';

class RewardController extends GetxController {
  static RewardController get instance => Get.find();

  final _rewardRepo = Get.put(RewardRepository());
  final _userRepo = UserRepository.instance;

  final isLoading = false.obs;
  final isRedeeming = false.obs;
  final rewards = <RewardModel>[].obs;
  final userRewardHistory = <UserRewardModel>[].obs;
  final userAvatarFrames = <UserRewardModel>[].obs;
  final userRewardPoints = 0.obs;
  final currentUser = UserModel.empty().obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserData();
    fetchAllRewards();
  }

  /// Fetch current user data
  Future<void> fetchUserData() async {
    try {
      final user = await _userRepo.fetchUserDetails();
      currentUser.value = user;
      userRewardPoints.value = user.rewardPoints;
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to load user data: ${e.toString()}',
      );
    }
  }

  /// Fetch all active rewards
  Future<void> fetchAllRewards() async {
    try {
      isLoading.value = true;
      rewards.value = await _rewardRepo.fetchActiveRewards();
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to load rewards: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch rewards by type
  Future<void> fetchRewardsByType(RewardType type) async {
    try {
      isLoading.value = true;
      rewards.value = await _rewardRepo.fetchActiveRewardsByType(type);
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to load rewards: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Redeem a reward
  Future<bool> redeemReward(RewardModel reward) async {
    try {
      isRedeeming.value = true;

      // Validate user has enough points
      if (userRewardPoints.value < reward.costPoints) {
        TLoaders.errorSnackBar(
          title: 'Insufficient Points',
          message: 'You need ${reward.costPoints} points but only have ${userRewardPoints.value} points.',
        );
        return false;
      }

      // Validate availability
      if (reward.availableQuantity != null && reward.availableQuantity! <= 0) {
        TLoaders.errorSnackBar(
          title: 'Out of Stock',
          message: 'This reward is currently out of stock.',
        );
        return false;
      }

      // Redeem the reward
      await _rewardRepo.redeemReward(
        userId: currentUser.value.userId,
        rewardId: reward.rewardId,
      );

      // Update local state
      userRewardPoints.value -= reward.costPoints;

      // Refresh user data to get updated points
      await fetchUserData();

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Reward redeemed successfully!',
      );

      return true;
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: e.toString(),
      );
      return false;
    } finally {
      isRedeeming.value = false;
    }
  }

  /// Fetch user's reward history
  Future<void> fetchUserRewardHistory() async {
    try {
      isLoading.value = true;
      userRewardHistory.value = await _rewardRepo.fetchUserRewardHistory(
        currentUser.value.userId,
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to load reward history: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Check if user owns this reward (for avatar frames)
  bool hasReward(String rewardId) {
    return userAvatarFrames.any((frame) => frame.reward.rewardId == rewardId);
  }
}