import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../common/loaders/circular_loader.dart';
import '../../../../../common/widgets/dialogs/dialog.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/extensions/date_time_extension.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../../authentication/models/user_model.dart';
import '../../../../personalization/controllers/avatar_frame_controller.dart';
import '../../../../personalization/controllers/user_controller.dart';
import '../../../../personalization/views/widgets/avatar_with_frame.dart';
import '../../../controllers/post_controller.dart';
import '../../../controllers/post_share_utils.dart';
import '../../../models/post_model.dart';
import '../../create_post/create_post_screen.dart';
import '../report_post_dialog.dart';

class PostHeader extends StatelessWidget {
  const PostHeader({super.key, required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final userController = UserController.instance;
    final postController = PostController.instance;
    final frameController = AvatarFrameController.instance;
    final isDark = THelperFunctions.isDarkMode(context);

    return Padding(
      padding: const EdgeInsets.all(TSizes.md),
      child: Obx(() {
        if (userController.userCache.containsKey(post.posterId)) {
          final user = userController.userCache[post.posterId]!;
          return _buildHeader(context, user, postController, frameController, isDark);
        }

        return FutureBuilder<UserModel>(
          future: userController.fetchUserRecordById(post.posterId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularLoader();
            }

            if (snapshot.hasError || snapshot.data == null) {
              return _buildErrorHeader(context, postController, isDark);
            }

            return _buildHeader(context, snapshot.data!, postController, frameController, isDark);
          },
        );
      }),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel user, PostController postController, AvatarFrameController frameController, bool isDark) {
    final currentUserId = UserController.instance.user.value.userId;
    final isOwnPost = currentUserId == post.posterId;
    final isEdited = post.updatedAt.isAfter(post.createdAt);

    // 1. 取发帖人的当前 frameId
    final frameId = user.currentAvatarFrame;
    String? frameIconUrl;

    if (frameId != null) {
      // 2. 优先用多用户缓存
      final frame = frameController.getUserFrameById(user.userId, frameId);
      if (frame != null) {
        frameIconUrl = frame.reward.icon;
      } else if (user.userId == currentUserId) {
        // 3. fallback: 自己的帖子，用 getCurrentFrame()
        final currentFrame = frameController.getCurrentFrame();
        frameIconUrl = currentFrame?.reward.icon;
      }
    }

    return Row(
      children: [
        AvatarWithFrame(
          profileImageUrl: user.profileImg,
          frameIconUrl: frameIconUrl,
          avatarSize: 40,  // 头像大小
          frameSize: 50,   // 头像框大小
        ),
        const SizedBox(width: TSizes.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      user.username.isNotEmpty ? user.username : "Anonymous",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isDark ? TColors.white : TColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: TSizes.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: post.postType.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: post.postType.color.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      post.postType.shortLabel,
                      style: TextStyle(
                        color: post.postType.color,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isOwnPost) ...[
                    const SizedBox(width: TSizes.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: TColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: TColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'Your Post',
                        style: TextStyle(
                          color: TColors.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                "${post.updatedAt.fromNow()}${isEdited ? " (edited)" : ""}",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: isDark ? TColors.darkGrey : TColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (isOwnPost) ...[
          IconButton(
            onPressed: () => _editPost(),
            icon: Icon(
              Icons.edit_outlined,
              color: isDark ? TColors.darkGrey : TColors.textSecondary,
              size: 20,
            ),
            tooltip: 'Edit Post',
          ),
        ],
        IconButton(
          onPressed: () => _showPostOptions(context, isOwnPost, postController, isDark),
          icon: Icon(
            Icons.more_vert,
            color: isDark ? TColors.darkGrey : TColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorHeader(BuildContext context, PostController postController, bool isDark) {
    final currentUserId = UserController.instance.user.value.userId;
    final isOwnPost = currentUserId == post.posterId;

    return Row(
      children: [
        // 错误状态下也使用 AvatarWithFrame
        AvatarWithFrame(
          profileImageUrl: '', // 空字符串会显示默认用户图标
          avatarSize: 40,
          frameSize: 50,
        ),
        const SizedBox(width: TSizes.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "Unknown User",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isDark ? TColors.darkGrey : TColors.textSecondary,
                    ),
                  ),
                  if (isOwnPost) ...[
                    const SizedBox(width: TSizes.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: TColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: TColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'Your Post',
                        style: TextStyle(
                          color: TColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                post.createdAt.fromNow(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? TColors.darkGrey : TColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (isOwnPost) ...[
          IconButton(
            onPressed: () => _editPost(),
            icon: Icon(
              Icons.edit_outlined,
              color: isDark ? TColors.darkGrey : TColors.textSecondary,
              size: 20,
            ),
            tooltip: 'Edit Post',
          ),
          const SizedBox(width: TSizes.xs),
        ],
        IconButton(
          onPressed: () => _showPostOptions(context, isOwnPost, postController, isDark),
          icon: Icon(
            Icons.more_vert,
            color: isDark ? TColors.darkGrey : TColors.textSecondary,
          ),
        ),
      ],
    );
  }

  void _showPostOptions(BuildContext context, bool isOwnPost, PostController postController, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: THelperFunctions.isDarkMode(context) ? TColors.dark : TColors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(TSizes.cardRadiusLg),
            topRight: Radius.circular(TSizes.cardRadiusLg),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: TSizes.md),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: TColors.grey.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: TSizes.md),
            if (isOwnPost) ...[
              _buildOptionItem(
                context,
                icon: Icons.edit,
                title: 'Edit Post',
                color: TColors.primary,
                onTap: () {
                  Get.back();
                  _editPost();
                },
              ),
              _buildOptionItem(
                context,
                icon: Icons.delete,
                title: 'Delete Post',
                color: TColors.error,
                onTap: () {
                  Get.back();
                  _deletePost(postController);
                },
              ),
              Divider(
                height: 1,
                color: isDark ? TColors.darkGrey.withOpacity(0.3) : TColors.grey.withOpacity(0.7),
              ),
            ],
            _buildOptionItem(
              context,
              icon: Icons.share,
              title: 'Share Post',
              color: TColors.info,
              onTap: () {
                Get.back();
                _sharePost();
              },
            ),
            _buildOptionItem(
              context,
              icon: Icons.link,
              title: 'Copy Post Link',
              color: TColors.success,
              onTap: () {
                Get.back();
                _copyPostLink();
              },
            ),
            // 只在不是自己的帖子时显示举报选项
            if (!isOwnPost) ...[
              Divider(
                height: 1,
                color: isDark ? TColors.darkGrey.withOpacity(0.3) : TColors.grey.withOpacity(0.7),
              ),
              _buildOptionItem(
                context,
                icon: Icons.report,
                title: 'Report Post',
                color: TColors.warning,
                onTap: () {
                  Get.back();
                  _reportPost();
                },
              ),
            ],
            const SizedBox(height: TSizes.md),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required Color color,
        required VoidCallback onTap,
      }) {
    final isDark = THelperFunctions.isDarkMode(context);

    return ListTile(
      leading: Icon(
        icon,
        color: color,
        size: 20,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isDark ? TColors.white : TColors.textPrimary,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: TSizes.lg),
      minLeadingWidth: 0,
    );
  }

  void _editPost() {
    Get.to(() => CreatePostScreen(
      isEditing: true,
      postToEdit: post,
    ));
  }

  void _deletePost(PostController postController) {
    TDialog.deleteDialog(
      title: 'Delete Post',
      message: 'Are you sure you want to delete this post? This action cannot be undone.',
      onConfirm: () {
        postController.deletePost(post.postId);
      },
    );
  }

  void _reportPost() {
    Get.dialog(
      ReportPostDialog(postId: post.postId),
      barrierDismissible: true,
    );
  }

  void _sharePost() {
    PostShareUtils.sharePost(post);
  }

  void _copyPostLink() {
    PostShareUtils.copyPostLink(post.postId);
  }
}