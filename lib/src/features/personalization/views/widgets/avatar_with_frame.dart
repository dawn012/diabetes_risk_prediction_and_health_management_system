import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../utils/constants/colors.dart';

class AvatarWithFrame extends StatelessWidget {
  final String profileImageUrl;   // 头像
  final String? frameIconUrl;     // 头像框图标，可为空
  final double avatarSize;
  final double frameSize;

  const AvatarWithFrame({
    super.key,
    required this.profileImageUrl,
    this.frameIconUrl,
    this.avatarSize = 60,
    this.frameSize = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 头像
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

        // 头像框
        if (frameIconUrl != null && frameIconUrl!.isNotEmpty)
          SizedBox(
            width: frameSize,
            height: frameSize,
            child: CachedNetworkImage(
              imageUrl: frameIconUrl!,
              fit: BoxFit.contain,
              placeholder: (context, url) => Container(
                width: frameSize,
                height: frameSize,
                decoration: const BoxDecoration(
                  color: TColors.darkGrey,
                  shape: BoxShape.circle,
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: frameSize,
                height: frameSize,
                decoration: const BoxDecoration(
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
  }
}
