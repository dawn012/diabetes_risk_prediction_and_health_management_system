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
import '../../../models/comment_model.dart';

class CommentHeader extends StatelessWidget {
  const CommentHeader({super.key, required this.comment});

  final CommentModel comment;

  @override
  Widget build(BuildContext context) {
    final userController = UserController.instance;
    final isDark = THelperFunctions.isDarkMode(context);

    return Obx(() {
      if (userController.userCache.containsKey(comment.authorId)) {
        final user = userController.userCache[comment.authorId]!;
        return _buildHeader(context, user, isDark);
      }

      return FutureBuilder<UserModel>(
        future: userController.fetchUserRecordById(comment.authorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularLoader();
          }

          if (snapshot.hasError || snapshot.data == null) {
            return _buildErrorHeader(context, isDark);
          }

          return _buildHeader(context, snapshot.data!, isDark);
        },
      );
    });
  }

  Widget _buildHeader(BuildContext context, UserModel user, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AvatarWithFrame(
          profileImageUrl: user.profileImg,
          avatarSize: 32,
          frameSize: 40,
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
                    comment.wasEdited
                        ? '${comment.updatedAt.fromNow()} (edited)'
                        : comment.createdAt.fromNow(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark ? TColors.darkGrey : TColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _showCommentOptions(context),
          icon: Icon(
            Icons.more_vert,
            color: isDark ? TColors.darkGrey : TColors.textSecondary,
            size: 20,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        ),
      ],
    );
  }

  Widget _buildErrorHeader(BuildContext context, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AvatarWithFrame(
          profileImageUrl: '',
          avatarSize: 32,
          frameSize: 40,
        ),
        const SizedBox(width: TSizes.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Unknown User",
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: isDark ? TColors.darkGrey : TColors.textSecondary,
                ),
              ),
              Text(
                comment.createdAt.fromNow(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? TColors.darkGrey : TColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCommentOptions(BuildContext context) {
    final commentController = CommentController.instance;
    final isDark = THelperFunctions.isDarkMode(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? TColors.darkContainer : TColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return CommentBottomSheet(
          title: "Comment Options",
          options: [
            if (commentController.isOwner(comment.authorId)) ...[
              BottomSheetOption(
                text: "Edit",
                icon: Icons.edit_outlined,
                iconColor: isDark ? TColors.white : TColors.black,
                onTap: () => commentController.editComment(comment),
              ),
              BottomSheetOption(
                text: "Delete",
                icon: Icons.delete_outline,
                iconColor: TColors.error,
                onTap: () => commentController.deleteCommentDialog(comment),
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