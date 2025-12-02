import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../features/personalization/controllers/avatar_frame_controller.dart';
import '../../../features/personalization/controllers/user_controller.dart';
import '../../../features/personalization/views/widgets/avatar_with_frame.dart';
import '../../../utils/constants/colors.dart';
import '../shimmer/shimmer.dart';

class TUserProfileTile extends StatelessWidget {
  const TUserProfileTile({
    super.key,
    required this.onPressed,
    this.showEditButton = true,
    this.isLoading = false,
    this.customSubtitle,
    this.showDefaultSubtitle = true,
    this.avatarSize = 60,
    this.frameSize = 80,
  });

  final VoidCallback onPressed;
  final bool showEditButton;
  final bool isLoading;
  final Widget? customSubtitle;
  final bool showDefaultSubtitle;
  final double avatarSize; // 头像大小
  final double frameSize;  // 头像框大小

  @override
  Widget build(BuildContext context) {
    final controller = UserController.instance;
    final frameController = AvatarFrameController.instance;

    return Obx(() {
      final user = controller.user.value;
      final imageUrl = user.profileImg;
      final isUserLoading = controller.profileLoading.value || isLoading;
      final currentFrame = frameController.getCurrentFrame();
      final frameIconUrl = currentFrame?.reward.icon;

      if (isUserLoading) {
        return _buildShimmerProfileTile();
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Avatar
            AvatarWithFrame(
              profileImageUrl: imageUrl,
              frameIconUrl: frameIconUrl,
              avatarSize: avatarSize,
              frameSize: frameSize,
            ),

            SizedBox(width: 14), // 间距

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username.isNotEmpty ? user.username : 'User',
                    style: Theme.of(context).textTheme.headlineSmall!.apply(color: TColors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (customSubtitle != null || showDefaultSubtitle) ...[
                    SizedBox(height: 2),
                    customSubtitle ??
                        (showDefaultSubtitle
                            ? Text(
                          user.email,
                          style: Theme.of(context).textTheme.bodyMedium!.apply(
                            color: TColors.white.withOpacity(0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                            : const SizedBox.shrink()),
                  ],
                ],
              ),
            ),

            // Edit Button
            if (showEditButton) ...[
              SizedBox(width: 8),
              IconButton(
                onPressed: onPressed,
                icon: const Icon(Iconsax.edit_bold, color: TColors.white),
                tooltip: 'Edit Profile',
              ),
            ],
          ],
        ),
      );
    });
  }

  /// Shimmer loading effect
  Widget _buildShimmerProfileTile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const TShimmerEffect(width: 50, height: 50, radius: 25),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TShimmerEffect(width: 120, height: 16, radius: 4),
                SizedBox(height: 4),
                const TShimmerEffect(width: 160, height: 14, radius: 4),
              ],
            ),
          ),
          if (showEditButton) ...[
            SizedBox(width: 8),
            const TShimmerEffect(width: 24, height: 24, radius: 12),
          ],
        ],
      ),
    );
  }
}