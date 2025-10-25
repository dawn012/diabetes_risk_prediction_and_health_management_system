import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../../personalization/controllers/user_controller.dart';
import '../../../controllers/post_controller.dart';
import '../../../controllers/post_share_utils.dart';
import '../../../models/post_model.dart';
import '../../comments/comments_screen.dart';

class PostButtons extends StatelessWidget {
  const PostButtons({super.key, required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final postController = PostController.instance;
    final userController = UserController.instance;
    final isDark = THelperFunctions.isDarkMode(context);
    final isLiked = post.likes.contains(userController.user.value.userId);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // Like button
        _buildActionButton(
          context: context,
          icon: isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
          label: 'Like',
          color: isLiked ? TColors.primary : (isDark ? TColors.lightGrey : TColors.textSecondary),
          onPressed: () => postController.togglePostLike(post.postId, post.likes),
          isDark: isDark,
        ),

        // Comment button
        _buildActionButton(
          context: context,
          icon: Icons.chat_bubble_outline,
          label: 'Comment',
          color: isDark ? TColors.lightGrey : TColors.textSecondary,
          onPressed: () => Get.to(() => CommentsScreen(postId: post.postId)),
          isDark: isDark,
        ),

        // Share button
        _buildActionButton(
          context: context,
          icon: Icons.share_outlined,
          label: 'Share',
          color: isDark ? TColors.lightGrey : TColors.textSecondary,
          onPressed: () {
            PostShareUtils.sharePost(post);
          },
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}