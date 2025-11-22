import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../utils/constants/colors.dart';
import '../../controllers/avatar_frame_controller.dart';
import '../../controllers/user_controller.dart';

class AvatarWithFrame extends StatelessWidget {
  final String profileImageUrl;
  final double avatarSize;
  final double frameSize;
  final String? customFrameId;

  const AvatarWithFrame({
    super.key,
    required this.profileImageUrl,
    this.avatarSize = 60,
    this.frameSize = 80,
    this.customFrameId,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AvatarFrameController>();
    final userController = UserController.instance;

    return Obx(() {
      final frameId = customFrameId ?? userController.user.value.currentAvatarFrame;
      final currentFrame = frameId != null
          ? controller.getCurrentFrameById(frameId)
          : null;

      return Stack(
        alignment: Alignment.center,
        children: [
          // Profile Image - 先绘制头像
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              image: profileImageUrl.isNotEmpty
                  ? DecorationImage(
                image: NetworkImage(profileImageUrl),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: profileImageUrl.isEmpty
                ? Center(
              child: Icon(
                Iconsax.user_bold,
                size: avatarSize * 0.4,
                color: TColors.primary,
              ),
            )
                : null,
          ),

          // Frame - 后绘制头像框，会覆盖在头像上面
          if (currentFrame != null)
            Container(
              width: frameSize,
              height: frameSize,
              child: CachedNetworkImage(
                imageUrl: currentFrame.reward.icon,
                fit: BoxFit.contain,
                placeholder: (context, url) => Container(
                  width: frameSize,
                  height: frameSize,
                  decoration: BoxDecoration(
                    color: TColors.darkGrey,
                    shape: BoxShape.circle,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: frameSize,
                  height: frameSize,
                  decoration: BoxDecoration(
                    color: TColors.darkGrey,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Iconsax.frame_bold,
                    color: Colors.white,
                    size: frameSize * 0.4,
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}