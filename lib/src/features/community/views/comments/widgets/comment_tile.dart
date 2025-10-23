import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/comment_controller.dart';
import '../../../models/comment_model.dart';
import '../reply_screen.dart';
import 'comment_content.dart';
import 'comment_header.dart';
import 'comment_actions.dart';

class CommentTile extends StatelessWidget {
  const CommentTile({super.key, required this.comment});

  final CommentModel comment;

  @override
  Widget build(BuildContext context) {
    final controller = CommentController.instance;
    final isDark = THelperFunctions.isDarkMode(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: TSizes.sm),
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkContainer : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
        border: Border.all(
          color: isDark
              ? TColors.borderPrimary.withOpacity(0.1)
              : TColors.borderPrimary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comment header (user info, time, options)
          CommentHeader(comment: comment),

          // const SizedBox(height: TSizes.sm),

          // Comment content
          CommentContent(comment: comment),

          const SizedBox(height: TSizes.spaceBtwItems),

          // Comment actions (like, reply)
          CommentActions(comment: comment),

          const SizedBox(height: TSizes.sm),

          // Reply count and navigation
          if (comment.replyCount > 0) ...[
            const SizedBox(height: TSizes.sm),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: GestureDetector(
                onTap: () => controller.handleNavigation(
                      () => Get.to(() => ReplyScreen(parentComment: comment)),
                ),
                child: Text(
                  "${comment.replyCount} ${comment.replyCount == 1 ? 'reply' : 'replies'}",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: TColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}