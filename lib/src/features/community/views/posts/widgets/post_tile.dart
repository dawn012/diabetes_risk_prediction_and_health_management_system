import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../models/post_model.dart';
import 'post_buttons.dart';
import 'post_header.dart';
import 'post_media_view.dart';
import 'post_stats.dart';

class PostTile extends StatelessWidget {
  const PostTile({super.key, required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkContainer : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
        border: Border.all(
          color: isDark
              ? TColors.borderPrimary.withOpacity(0.1)
              : TColors.borderPrimary.withOpacity(0.3),
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
          // Post Header
          PostHeader(post: post),

          // Post Content
          if (post.postContent.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm),
              child: Text(
                post.postContent,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? TColors.lightGrey : TColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),

          // Post Media
          if (post.mediaUrls.isNotEmpty)
            PostMediaView(mediaUrls: post.mediaUrls),

          // Post Stats and Buttons
          Padding(
            padding: const EdgeInsets.all(TSizes.md),
            child: Column(
              children: [
                PostStats(post: post),
                const SizedBox(height: TSizes.sm),
                const Divider(height: 1),
                const SizedBox(height: TSizes.sm),
                PostButtons(post: post),
              ],
            ),
          ),
        ],
      ),
    );
  }
}