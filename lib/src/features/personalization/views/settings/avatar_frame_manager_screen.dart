import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../common/loaders/circular_loader.dart';
import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/dialogs/dialog.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../../reward/models/user_reward_model.dart';
import '../../controllers/avatar_frame_controller.dart';

class AvatarFrameManagerScreen extends StatelessWidget {
  const AvatarFrameManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AvatarFrameController());
    final userController = UserController.instance;
    final isDark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : Colors.grey[50],
      appBar: TAppBar(
        backgroundColor: TColors.primary,
        showBackArrow: true,
        title: Text(
          'Avatar Frames',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: TColors.white),
      ),
      body: Obx(() {
        return Column(
          children: [
            // Current Frame Display
            _buildCurrentFrameSection(controller, userController, isDark),

            // Divider
            _buildDividerSection(isDark),

            SizedBox(height: TSizes.md),

            // Frames Grid
            Expanded(
              child: _buildFramesGrid(controller, isDark, context),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildCurrentFrameSection(AvatarFrameController controller, UserController userController, bool isDark) {
    return Container(
      margin: EdgeInsets.all(TSizes.defaultSpace),
      padding: EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            TColors.primary,
            TColors.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: TColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar Preview with Frame
          Stack(
            alignment: Alignment.center,
            children: [
              // Profile Image
              Obx(() {
                return Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    image: userController.user.value.profileImg.isNotEmpty
                        ? DecorationImage(
                      image: NetworkImage(
                        userController.user.value.profileImg,
                      ),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: userController.user.value.profileImg.isEmpty
                      ? Center(
                    child: Icon(
                      Iconsax.user_bold,
                      size: 24,
                      color: TColors.primary,
                    ),
                  )
                      : null,
                );
              }),

              // Frame
              Obx(() {
                final currentFrameId = userController.user.value.currentAvatarFrame;
                final currentFrame = currentFrameId != null
                    ? controller.getCurrentFrameById(currentFrameId)
                    : null;

                return currentFrame != null
                    ? Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: CachedNetworkImage(
                    imageUrl: currentFrame.reward.icon,
                    fit: BoxFit.contain, // 改为 contain 确保完整显示
                  ),
                )
                    : Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ],
          ),

          SizedBox(width: TSizes.md),

          // Text Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Frame',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 4),
                Obx(() {
                  final currentFrameId = userController.user.value.currentAvatarFrame;
                  final currentFrame = currentFrameId != null
                      ? controller.getCurrentFrameById(currentFrameId)
                      : null;

                  return Text(
                    currentFrame?.reward.title ?? 'No Frame',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  );
                }),
              ],
            ),
          ),

          // Remove Button
          Obx(() {
            final hasCurrentFrame = userController.user.value.currentAvatarFrame != null;
            return hasCurrentFrame
                ? IconButton(
              onPressed: () => TDialog.confirmDialog(
                title: 'Remove Frame',
                message: 'Are you sure you want to remove your current avatar frame?',
                onConfirm: () => controller.removeAvatarFrame(),
                confirmText: 'Remove',
                confirmButtonColor: TColors.error,
              ),
              icon: Icon(
                Iconsax.close_circle_bold,
                color: Colors.white,
                size: 28,
              ),
              tooltip: 'Remove Frame',
            )
                : SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildDividerSection(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: isDark ? TColors.darkGrey : Colors.grey[300],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: TSizes.md),
            child: Text(
              'YOUR FRAMES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? TColors.darkGrey : TColors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: isDark ? TColors.darkGrey : Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFramesGrid(AvatarFrameController controller, bool isDark, BuildContext context) {
    if (controller.isLoading.value) {
      return Center(
        child: CircularLoader(message: 'Loading frames...'),
      );
    }

    if (controller.userAvatarFrames.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return RefreshIndicator(
      onRefresh: () => controller.fetchUserAvatarFrames(),
      child: GridView.builder(
        padding: EdgeInsets.all(TSizes.defaultSpace),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: THelperFunctions.screenWidth() > 600 ? 4 : 3,
          crossAxisSpacing: TSizes.md,
          mainAxisSpacing: TSizes.md,
          childAspectRatio: 0.85,
        ),
        itemCount: controller.userAvatarFrames.length,
        itemBuilder: (context, index) {
          final userReward = controller.userAvatarFrames[index];
          return _buildFrameCard(userReward, controller, isDark);
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.frame_bold,
            size: 80,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          SizedBox(height: TSizes.spaceBtwItems),
          Text(
            'No Frames Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          SizedBox(height: TSizes.sm),
          Text(
            'Redeem frames from the reward shop!',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[500] : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrameCard(UserRewardModel userReward, AvatarFrameController controller, bool isDark) {
    final reward = userReward.reward;

    return Obx(() {
      final userController = Get.find<UserController>();
      final currentIsApplied = userController.user.value.currentAvatarFrame == reward.rewardId;

      return Container(
        decoration: BoxDecoration(
          color: isDark ? TColors.dark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: currentIsApplied
                ? TColors.primary
                : Colors.transparent,
            width: 2,
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
            onTap: currentIsApplied
                ? null
                : () => TDialog.confirmDialog(
              title: 'Apply Frame',
              message: 'Do you want to apply "${reward.title}" as your avatar frame?',
              onConfirm: () => controller.applyAvatarFrame(reward.rewardId),
              confirmText: 'Apply',
              confirmButtonColor: TColors.primary,
            ),
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Column(
                  children: [
                    // Frame Image
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? TColors.darkGrey : Colors.grey[100],
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: reward.icon,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                color: TColors.primary,
                                strokeWidth: 2,
                              ),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Iconsax.gallery_slash_bold,
                              color: TColors.darkGrey,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Title
                    Padding(
                      padding: EdgeInsets.all(TSizes.sm),
                      child: Text(
                        reward.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : TColors.black,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Applied Badge
                if (currentIsApplied)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: TColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: TColors.primary.withOpacity(0.4),
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
                            'Applied',
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
              ],
            ),
          ),
        ),
      );
    });
  }
}