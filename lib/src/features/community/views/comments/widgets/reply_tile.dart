import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../common/loaders/circular_loader.dart';
import '../../../../../common/widgets/bottom_sheets/comment_bottom_sheet.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/extensions/date_time_extension.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../../authentication/models/user_model.dart';
import '../../../../personalization/controllers/user_controller.dart';
import '../../../../personalization/views/widgets/avatar_with_frame.dart';
import '../../../controllers/comment_controller.dart';
import '../../../models/reply_model.dart';

class ReplyTile extends StatelessWidget {
  const ReplyTile({
    super.key,
    required this.reply,
    required this.parentCommentId,
  });

  final ReplyModel reply;
  final String parentCommentId;

  @override
  Widget build(BuildContext context) {
    final controller = CommentController.instance;
    final userController = UserController.instance;
    final isDark = THelperFunctions.isDarkMode(context);

    return Container(
      margin: const EdgeInsets.only(left: TSizes.lg),
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkContainer.withOpacity(0.7) : TColors.lightGrey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
        border: Border.all(
          color: isDark
              ? TColors.borderPrimary.withOpacity(0.1)
              : TColors.borderPrimary.withOpacity(0.2),
        ),
      ),
      child: Obx(() {
        if (userController.userCache.containsKey(reply.authorId)) {
          final user = userController.userCache[reply.authorId]!;
          return _buildReplyContent(context, user, isDark);
        }

        return FutureBuilder<UserModel>(
          future: userController.fetchUserRecordById(reply.authorId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularLoader();
            }

            if (snapshot.hasError || snapshot.data == null) {
              return _buildErrorReply(context, isDark);
            }

            return _buildReplyContent(context, snapshot.data!, isDark);
          },
        );
      }),
    );
  }

  Widget _buildReplyContent(BuildContext context, UserModel user, bool isDark) {
    final controller = CommentController.instance;
    final userController = UserController.instance;
    final isLiked = reply.likes.contains(userController.user.value.userId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AvatarWithFrame(
              profileImageUrl: user.profileImg,
              avatarSize: 24,
              frameSize: 32,
            ),
            const SizedBox(width: TSizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        user.username.isNotEmpty ? user.username : "Anonymous",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? TColors.white : TColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: TSizes.xs),
                      Text(
                        "·",
                        style: TextStyle(
                          color: isDark ? TColors.darkGrey : TColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: TSizes.xs),
                      Text(
                        reply.wasEdited
                            ? '${reply.updatedAt.fromNow()} (edited)'
                            : reply.createdAt.fromNow(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? TColors.darkGrey : TColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  Text(
                    reply.content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? TColors.lightGrey : TColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _showReplyOptions(context),
              icon: Icon(
                Icons.more_vert,
                color: isDark ? TColors.darkGrey : TColors.textSecondary,
                size: 18,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
            ),
          ],
        ),

        const SizedBox(height: TSizes.spaceBtwItems),

        Padding(
          padding: const EdgeInsets.only(left: 30),
          child: GestureDetector(
            onTap: () => controller.toggleReplyLike(reply, parentCommentId),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    color: isLiked ? TColors.primary : (isDark ? TColors.darkGrey : TColors.textSecondary),
                    size: 14,
                  ),
                  if (reply.likes.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      reply.likes.length.toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isLiked ? TColors.primary : (isDark ? TColors.darkGrey : TColors.textSecondary),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorReply(BuildContext context, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AvatarWithFrame(
          profileImageUrl: '',
          avatarSize: 24,
          frameSize: 32,
        ),
        const SizedBox(width: TSizes.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Unknown User",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? TColors.darkGrey : TColors.textSecondary,
                ),
              ),
              Text(
                reply.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? TColors.lightGrey : TColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showReplyOptions(BuildContext context) {
    final controller = CommentController.instance;
    final isDark = THelperFunctions.isDarkMode(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? TColors.darkContainer : TColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return CommentBottomSheet(
          title: "Reply Options",
          options: [
            if (controller.isOwner(reply.authorId)) ...[
              BottomSheetOption(
                text: "Edit",
                icon: Icons.edit_outlined,
                iconColor: isDark ? TColors.white : TColors.black,
                onTap: () => controller.editReply(reply, parentCommentId),
              ),
              BottomSheetOption(
                text: "Delete",
                icon: Icons.delete_outline,
                iconColor: TColors.error,
                onTap: () => controller.deleteReplyDialog(reply, parentCommentId),
              ),
            ] else ...[
              BottomSheetOption(
                text: "Report",
                icon: Icons.flag_outlined,
                iconColor: TColors.warning,
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ],
        );
      },
    );
  }
}