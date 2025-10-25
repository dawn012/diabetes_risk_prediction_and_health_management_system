import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/dialogs/dialog.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/comment_controller.dart';
import '../../models/comment_model.dart';
import 'widgets/comment_text_field.dart';
import 'widgets/comment_tile.dart';
import 'widgets/reply_tile.dart';

class ReplyScreen extends StatelessWidget {
  const ReplyScreen({super.key, required this.parentComment});

  final CommentModel parentComment;

  @override
  Widget build(BuildContext context) {
    final controller = CommentController.instance;
    final isDark = THelperFunctions.isDarkMode(context);

    // Fetch replies when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchReplies(parentComment.commentId);
    });

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        // Check if there are unsaved changes
        if (controller.commentText.text.trim().isNotEmpty) {
          final shouldDiscard = await TDialog.keepWriting(
            title: 'Discard Changes?',
            message: 'You have unsaved text. Are you sure you want to leave? Your text will be lost.',
          );

          if (shouldDiscard) {
            controller.clearEditingState();
            Get.back();
          }
        } else {
          controller.clearEditingState();
          Get.back();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? TColors.dark : TColors.primaryBackground,

        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Obx(() {
            final isEditing = controller.isEditing;

            return Stack(
              children: [
                // Dark overlay when editing
                if (isEditing)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    height: kToolbarHeight + MediaQuery.of(context).padding.top,
                  ),

                // App bar
                TAppBar(
                  title: Text(
                    "Replies",
                    style: TextStyle(
                      color: isEditing ? Colors.white : null,
                    ),
                  ),
                  showBackArrow: true,
                  backgroundColor: isEditing ? Colors.transparent : null,
                  iconTheme: IconThemeData(
                    color: isEditing ? Colors.white : null,
                  ),
                ),
              ],
            );
          }),
        ),

        body: Stack(
          children: [
            // Main content
            Column(
              children: [
                // Original comment (parent)
                Container(
                  color: isDark ? TColors.darkContainer : TColors.white,
                  child: Column(
                    children: [
                      CommentTile(comment: parentComment, showReplyActions: false,),
                      Divider(
                        color: isDark
                            ? TColors.borderPrimary.withOpacity(0.1)
                            : TColors.borderPrimary.withOpacity(0.3),
                        thickness: 8,
                        height: 8,
                      ),
                    ],
                  ),
                ),

                // Replies list
                Expanded(
                  child: Obx(() {
                    final replies = controller.getReplies(parentComment.commentId);
                    final isLoading = controller.areRepliesLoading(parentComment.commentId);

                    if (isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (replies.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(TSizes.xl),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.reply_outlined,
                              size: 64,
                              color: isDark ? TColors.darkGrey : TColors.grey,
                            ),
                            const SizedBox(height: TSizes.md),
                            Text(
                              "No replies yet",
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: isDark ? TColors.lightGrey : TColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: TSizes.xs),
                            Text(
                              "Be the first to reply!",
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isDark ? TColors.darkGrey : TColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(TSizes.sm),
                      itemCount: replies.length,
                      separatorBuilder: (context, index) => const SizedBox(height: TSizes.sm),
                      itemBuilder: (context, index) {
                        final reply = replies[index];
                        return ReplyTile(
                          reply: reply,
                          parentCommentId: parentComment.commentId,
                        );
                      },
                    );
                  }),
                ),
              ],
            ),

            // Dark overlay when editing (excludes text field area)
            Obx(() {
              final isEditing = controller.isEditing;
              return isEditing
                  ? Positioned.fill(
                child: GestureDetector(
                  onTap: () => controller.cancelEdit(),
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    margin: const EdgeInsets.only(bottom: 80),
                  ),
                ),
              )
                  : const SizedBox.shrink();
            }),

            // Bottom text field
            Align(
              alignment: Alignment.bottomCenter,
              child: CommentTextField(parentCommentId: parentComment.commentId),
            ),
          ],
        ),
      ),
    );
  }
}