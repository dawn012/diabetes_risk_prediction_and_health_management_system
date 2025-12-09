import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../../personalization/controllers/user_controller.dart';
import '../../../models/post_model.dart';
import 'disabled_post_banner.dart';
import 'post_buttons.dart';
import 'post_header.dart';
import 'post_media_view.dart';
import 'post_stats.dart';

class PostTile extends StatelessWidget {
  const PostTile({super.key, required this.post, required this.isInMyPosts});

  final PostModel post;
  final bool isInMyPosts; // 标识是否在"My Posts"页

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    final isCurrentUserPost = post.posterId == Get.find<UserController>().user.value.userId;
    final isDisabled = post.isDisable;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkContainer : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
        border: Border.all(
          color: isDisabled
              ? TColors.error.withOpacity(0.3)
              : (isDark
              ? TColors.borderPrimary.withOpacity(0.1)
              : TColors.borderPrimary.withOpacity(0.3)),
          width: isDisabled ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show disabled banner if post is disabled and user is the owner
          if (isDisabled && isCurrentUserPost)
            DisabledPostBanner(
              reason: isInMyPosts ? 'This post violates community guidelines.' : null,
              onContactAdmin: isInMyPosts ? () {
                // TODO: 实现联系管理员功能
              } : null,
              isCompact: !isInMyPosts,
            ),

          // Post Header
          PostHeader(
            post: post,
          ),

          // Post Content
          if (post.postContent.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TSizes.md,
                vertical: TSizes.sm,
              ),
              child: Text(
                post.postContent,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDisabled
                      ? (isDark ? TColors.darkGrey : TColors.textSecondary)
                      : (isDark ? TColors.lightGrey : TColors.textPrimary),
                  height: 1.4,
                ),
              ),
            ),

          // Post Media (dimmed & non-interactive if disabled)
          if (post.mediaUrls.isNotEmpty)
            IgnorePointer(
              ignoring: isDisabled,        // 禁用时不响应点击，包括播放按钮
              child: Opacity(
                opacity: isDisabled ? 0.5 : 1.0,
                child: PostMediaView(mediaUrls: post.mediaUrls),
              ),
            ),

          // Post Stats and Buttons
          Padding(
            padding: const EdgeInsets.all(TSizes.md),
            child: Column(
              children: [
                PostStats(post: post),
                const SizedBox(height: TSizes.sm),
                const Divider(height: 1),
                const SizedBox(height: TSizes.sm),
                // Disable interactions if post is disabled
                IgnorePointer(
                  ignoring: isDisabled,
                  child: Opacity(
                    opacity: isDisabled ? 0.5 : 1.0,
                    child: PostButtons(post: post),
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