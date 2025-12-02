import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../common/loaders/circular_loader.dart';
import '../../../common/widgets/appbar/appbar.dart';
import '../../../common/widgets/dialogs/dialog.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../../achievement/views/leaderboard_rewards_info_screen.dart';
import '../../personalization/controllers/avatar_frame_controller.dart';
import '../../personalization/controllers/user_controller.dart';
import '../controllers/reward_controller.dart';
import '../models/reward_model.dart';
import 'reward_history_screen.dart';

class RewardShopScreen extends StatelessWidget {
  const RewardShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RewardController());
    final avatarFrameController = Get.put(AvatarFrameController());
    final userController = UserController.instance;
    final isDark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : Colors.grey[50],
      appBar: TAppBar(
        backgroundColor: TColors.primary,
        showBackArrow: true,
        title: Text(
          'Reward Shop',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: TColors.white),
        actions: [
          // Reward History
          IconButton(
            icon: Icon(Icons.history, color: Colors.white),
            onPressed: () => Get.to(() => const RewardHistoryScreen()),
            tooltip: 'Reward History',
          ),
        ],
        // flexibleSpace: Container(
        //   decoration: BoxDecoration(
        //     gradient: LinearGradient(
        //       begin: Alignment.topLeft,
        //       end: Alignment.bottomRight,
        //       colors: [
        //         TColors.primary,
        //         TColors.primary.withOpacity(0.8),
        //       ],
        //     ),
        //   ),
        // ),
      ),
      body: Column(
        children: [
          // Points Display Card
          _buildPointsCard(controller, isDark),

          // Rewards Grid
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(
                    child: CircularLoader(message: 'Loading rewards...'));
              }

              if (controller.rewards.isEmpty) {
                return _buildEmptyState(isDark);
              }

              return RefreshIndicator(
                onRefresh: () => controller.fetchAllRewards(),
                child: GridView.builder(
                  padding: EdgeInsets.all(TSizes.defaultSpace),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                    THelperFunctions.screenWidth() > 600 ? 3 : 2,
                    crossAxisSpacing: TSizes.md,
                    mainAxisSpacing: TSizes.md,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: controller.rewards.length,
                  itemBuilder: (context, index) {
                    final reward = controller.rewards[index];
                    return _buildRewardCard(
                      reward,
                      controller,
                      avatarFrameController,
                      userController,
                      isDark,
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsCard(RewardController controller, bool isDark) {
    return Container(
      margin: EdgeInsets.all(TSizes.defaultSpace),
      padding: EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            TColors.warning,
            TColors.warning.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: TColors.warning.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Iconsax.coin_1_bold,
              color: Colors.white,
              size: 32,
            ),
          ),
          SizedBox(width: TSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Reward Points',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Obx(() => Text(
                  '${controller.userRewardPoints.value}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                )),
              ],
            ),
          ),
          // Leaderboard Rewards Info
          IconButton(
            icon: Icon(Iconsax.award_bold, color: Colors.white),
            onPressed: () => Get.to(() => const LeaderboardRewardsInfoScreen()),
            tooltip: 'Reward Rules',
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard(
      RewardModel reward,
      RewardController controller,
      AvatarFrameController avatarFrameController,
      UserController userController,
      bool isDark,
      ) {
    final isOutOfStock =
        reward.availableQuantity != null && reward.availableQuantity! <= 0;
    final canAfford = controller.userRewardPoints.value >= reward.costPoints;

    return Obx(() {
      // Check if user already owns this frame
      final isOwned = avatarFrameController.userAvatarFrames
          .any((frame) => frame.reward.rewardId == reward.rewardId);

      return Container(
        decoration: BoxDecoration(
          color: isDark ? TColors.dark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOwned
                ? TColors.success.withOpacity(0.5)
                : isOutOfStock
                ? TColors.error.withOpacity(0.3)
                : canAfford
                ? TColors.success.withOpacity(0.3)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isOutOfStock
                ? null
                : () => _showRewardDetails(
              reward,
              controller,
              avatarFrameController,
              userController,
              isDark,
              isOwned,
            ),
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image
                    AspectRatio(
                      aspectRatio: 1.3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? TColors.darkGrey : Colors.grey[100],
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: reward.icon,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                color: TColors.primary,
                                strokeWidth: 2,
                              ),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Iconsax.gallery_slash_bold,
                              color: TColors.darkGrey,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Details
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: EdgeInsets.all(TSizes.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Title
                            Text(
                              reward.title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : TColors.black,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            // Price & Stock
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Iconsax.coin_1_bold,
                                      color: TColors.warning,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '${reward.costPoints}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isOwned
                                            ? TColors.success
                                            : canAfford
                                            ? TColors.success
                                            : TColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                                if (reward.availableQuantity != null) ...[
                                  SizedBox(height: 4),
                                  Text(
                                    '${reward.availableQuantity} left',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isOutOfStock
                                          ? TColors.error
                                          : isDark
                                          ? TColors.darkGrey
                                          : TColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Owned Badge
                if (isOwned)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: TColors.success,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: TColors.success.withOpacity(0.4),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.tick_circle_bold,
                            color: Colors.white,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'OWNED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Out of Stock Badge
                if (isOutOfStock)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: TColors.error,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'OUT OF STOCK',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.shop_bold,
            size: 80,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          SizedBox(height: TSizes.spaceBtwItems),
          Text(
            'No Rewards Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          SizedBox(height: TSizes.sm),
          Text(
            'Check back later for new rewards!',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[500] : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _showRewardDetails(
      RewardModel reward,
      RewardController controller,
      AvatarFrameController avatarFrameController,
      UserController userController,
      bool isDark,
      bool isOwned,
      ) {
    // Local state for preview
    final previewFrameId = Rx<String?>(null);

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(TSizes.defaultSpace),
        decoration: BoxDecoration(
          color: isDark ? TColors.dark : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Preview Section with Frame
              _buildAvatarPreview(
                userController,
                reward,
                previewFrameId,
                isDark,
              ),

              SizedBox(height: TSizes.spaceBtwItems),

              // Image
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? TColors.darkGrey : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: reward.icon,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(color: TColors.primary),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: isDark ? TColors.darkGrey : Colors.grey[200],
                      child: Icon(
                        Iconsax.gallery_slash_bold,
                        color: TColors.darkGrey,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: TSizes.spaceBtwItems),

              // Title
              Text(
                reward.title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : TColors.black,
                ),
              ),

              SizedBox(height: TSizes.sm),

              // Description
              Text(
                reward.description,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? TColors.darkGrey : TColors.textSecondary,
                  height: 1.5,
                ),
              ),

              SizedBox(height: TSizes.spaceBtwItems),

              // Price & Stock Info
              Container(
                padding: EdgeInsets.all(TSizes.md),
                decoration: BoxDecoration(
                  color: isDark
                      ? TColors.darkGrey.withOpacity(0.3)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cost:',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? TColors.lightGrey
                                : TColors.textSecondary,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Iconsax.coin_1_bold,
                              color: TColors.warning,
                              size: 20,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${reward.costPoints}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : TColors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (reward.availableQuantity != null) ...[
                      SizedBox(height: TSizes.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Available:',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? TColors.lightGrey
                                  : TColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${reward.availableQuantity} left',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : TColors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (isOwned) ...[
                      SizedBox(height: TSizes.sm),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: TColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: TColors.success.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.tick_circle_bold,
                              color: TColors.success,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'You already own this item',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: TColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: TSizes.spaceBtwSections),

              // Redeem Button
              if (!isOwned)
                Obx(() {
                  final canAfford =
                      controller.userRewardPoints.value >= reward.costPoints;
                  final isRedeeming = controller.isRedeeming.value;

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canAfford && !isRedeeming
                          ? () => TDialog.confirmDialog(
                        title: 'Confirm Redemption',
                        message:
                        'Are you sure you want to redeem "${reward.title}" for ${reward.costPoints} points?',
                        onConfirm: () async {
                          final success =
                          await controller.redeemReward(reward);
                          if (success) {
                            // Refresh avatar frames
                            await avatarFrameController
                                .fetchUserAvatarFrames();

                            // Close bottom sheet
                            if (Get.context != null) {
                              Navigator.of(Get.context!,
                                  rootNavigator: true)
                                  .pop(true);
                            }
                            controller
                                .fetchAllRewards(); // Refresh rewards
                          }
                        },
                        confirmButtonColor: TColors.primary,
                      )
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canAfford
                            ? TColors.primary
                            : TColors.buttonDisabled,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isRedeeming
                          ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : Text(
                        canAfford
                            ? 'Redeem Now'
                            : 'Insufficient Points',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildAvatarPreview(
      UserController userController,
      RewardModel reward,
      Rx<String?> previewFrameId,
      bool isDark,
      ) {
    return Container(
      padding: EdgeInsets.all(TSizes.md),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? TColors.darkGrey.withOpacity(0.3) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Preview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : TColors.black,
            ),
          ),
          SizedBox(height: TSizes.md),

          Container(
            height: 180,
            child: Stack(
              children: [
                // 头像预览区域
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Obx(() {
                    final showPreview = previewFrameId.value != null;
                    final profileImage = userController.user.value.profileImg;

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Profile Image
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            image: profileImage.isNotEmpty
                                ? DecorationImage(
                              image: NetworkImage(profileImage),
                              fit: BoxFit.cover,
                            )
                                : null,
                          ),
                          child: profileImage.isEmpty
                              ? Center(
                            child: Icon(
                              Iconsax.user_bold,
                              size: 40,
                              color: TColors.primary,
                            ),
                          )
                              : null,
                        ),

                        // Frame overlay
                        if (showPreview)
                          Container(
                            width: 120,
                            height: 120,
                            child: CachedNetworkImage(
                              imageUrl: reward.icon,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => Container(),
                              errorWidget: (context, url, error) => Container(),
                            ),
                          ),
                      ],
                    );
                  }),
                ),

                // 按钮区域 - 使用 Center 包裹保持原始宽度
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Obx(() {
                      final showPreview = previewFrameId.value != null;
                      return OutlinedButton.icon(
                        onPressed: () {
                          if (showPreview) {
                            previewFrameId.value = null;
                          } else {
                            previewFrameId.value = reward.rewardId;
                          }
                        },
                        icon: Icon(
                          showPreview ? Iconsax.eye_slash_bold : Iconsax.eye_bold,
                          size: 18,
                        ),
                        label: Text(
                          showPreview ? 'Hide Preview' : 'Show Preview',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          side: BorderSide(
                            color: TColors.primary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}