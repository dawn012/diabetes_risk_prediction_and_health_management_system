import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../common/loaders/circular_loader.dart';
import '../../../../../common/widgets/error_screen/error_retry_screen.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/comment_controller.dart';
import 'comment_tile.dart';

class CommentsList extends StatelessWidget {
  const CommentsList({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CommentController.instance;
    final isDark = THelperFunctions.isDarkMode(context);

    return Obx(() {
      if (controller.isLoadingComments.value && controller.comments.isEmpty) {
        return const Center(child: CircularLoader());
      }

      if (controller.commentsError.isNotEmpty && controller.comments.isEmpty) {
        return ErrorRetryScreen(
          message: controller.commentsError.value,
          onRetry: () => controller.fetchComments(refresh: true),
        );
      }

      if (controller.comments.isEmpty) {
        return Align(
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.all(TSizes.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: isDark ? TColors.darkGrey : TColors.grey,
                ),
                const SizedBox(height: TSizes.md),
                Text(
                  "No comments yet",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: isDark
                        ? TColors.lightGrey
                        : TColors.textSecondary,
                  ),
                ),
                const SizedBox(height: TSizes.xs),
                Text(
                  "Be the first to comment!",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? TColors.darkGrey
                        : TColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      final comments = controller.comments;

      return RefreshIndicator(
        onRefresh: () => controller.fetchComments(refresh: true),
        color: TColors.primary,
        child: ListView.separated(
          controller: controller.scrollController, // 用 controller 的
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 100,
          ),
          itemCount:
          comments.length + (controller.hasMoreComments.value ? 1 : 0),
          separatorBuilder: (context, index) => const SizedBox.shrink(),
          itemBuilder: (context, index) {
            // 尾部 loading item
            if (index >= comments.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(TColors.primary),
                      ),
                    ),
                  ),
                ),
              );
            }

            final comment = comments[index];
            return CommentTile(comment: comment);
          },
        ),
      );
    });
  }
}