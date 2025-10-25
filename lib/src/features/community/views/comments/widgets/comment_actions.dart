import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../../personalization/controllers/user_controller.dart';
import '../../../controllers/comment_controller.dart';
import '../../../models/comment_model.dart';
import '../reply_screen.dart';

class CommentActions extends StatelessWidget {
  const CommentActions(
      {super.key, required this.comment, this.showReplyAction = true});

  final CommentModel comment;
  final bool showReplyAction; // 控制是否显示回复按钮

  @override
  Widget build(BuildContext context) {
    final controller = CommentController.instance;
    final userController = UserController.instance;
    final isDark = THelperFunctions.isDarkMode(context);
    final isLiked = comment.likes.contains(userController.user.value.userId);

    return Padding(
      padding: const EdgeInsets.only(left: 35), // Align with content
      child: Row(
        children: [
          // Like button
          GestureDetector(
            onTap: () => controller.toggleCommentLike(comment),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    color: isLiked
                        ? TColors.primary
                        : (isDark ? TColors.darkGrey : TColors.textSecondary),
                    size: 16,
                  ),
                  if (comment.likes.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      comment.likes.length.toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isLiked
                                ? TColors.primary
                                : (isDark
                                    ? TColors.darkGrey
                                    : TColors.textSecondary),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Reply button - 只在需要时显示
          if (showReplyAction) ...[
            const SizedBox(width: TSizes.sm),
            GestureDetector(
              onTap: () => Get.to(() => ReplyScreen(parentComment: comment)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.reply_outlined,
                      color: isDark ? TColors.darkGrey : TColors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Reply',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? TColors.darkGrey : TColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
