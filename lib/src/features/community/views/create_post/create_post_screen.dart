import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../common/loaders/loaders.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../../utils/helpers/media_helper.dart';
import '../../../personalization/controllers/avatar_frame_controller.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../../personalization/views/widgets/avatar_with_frame.dart';
import '../../controllers/post_create_controller.dart';
import '../../models/post_model.dart';
import 'widgets/media_grid_widget.dart';

class CreatePostScreen extends StatelessWidget {
  final PostModel? postToEdit;
  final bool isEditing;

  const CreatePostScreen({
    super.key,
    this.postToEdit,
    this.isEditing = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PostCreateController());
    final userController = UserController.instance;
    final darkMode = THelperFunctions.isDarkMode(context);

    // Initialize with existing post data if editing
    if (isEditing && postToEdit != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!controller.isEditingMode.value) {
          controller.initializeForEditing(postToEdit!);
        }
      });
    }

    return WillPopScope(
      onWillPop: () async {
        // 只在真正上传时阻止返回
        if (controller.isCreatingPost.value) {
          TLoaders.warningSnackBar(
            title: 'Please Wait',
            message: 'Please wait for the upload to complete.',
          );
          return false;
        }
        final canPop = await controller.checkUnsavedChanges();
        if (canPop && controller.isEditingMode.value) {
          controller.resetEditingState(); // 离开时重置编辑状态
        }
        return canPop;
      },
      child: Scaffold(
        backgroundColor: darkMode ? TColors.dark : TColors.light,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: darkMode ? TColors.dark : TColors.white,
          leading: IconButton(
            onPressed: () async {
              // 只在真正上传时禁用关闭按钮
              if (controller.isCreatingPost.value) {
                TLoaders.warningSnackBar(
                  title: 'Please Wait',
                  message: 'Please wait for the upload to complete.',
                );
                return;
              }
              final canPop = await controller.checkUnsavedChanges();
              if (canPop) Get.back();
            },
            icon: Icon(
              Iconsax.arrow_left_2_outline,
              color: darkMode ? TColors.white : TColors.black,
            ),
          ),
          title: Obx(() => Text(
            controller.isEditingMode.value ? 'Edit Post' : 'Create Post',
            style: TextStyle(
              color: darkMode ? TColors.white : TColors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          )),
          actions: [
            Obx(() {
              final isUploading = controller.isCreatingPost.value;
              final canSubmitNow = controller.canSubmit.value; // Use the reactive canSubmit

              return Container(
                constraints: BoxConstraints(maxWidth: 80),
                child: TextButton(
                  onPressed: isUploading || !canSubmitNow ? null : controller.submitPost,
                  child: isUploading
                      ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(TColors.primary),
                    ),
                  )
                      : Text(
                    controller.isEditingMode.value ? 'Update' : 'Post',
                    style: TextStyle(
                      color: canSubmitNow ? TColors.primary : TColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }),
            SizedBox(width: 4),
          ],
        ),
        body: Obx(() {
          // 只在真正创建/更新帖子时禁用界面
          final isUploading = controller.isCreatingPost.value;

          return Stack(
            children: [
              // 主要内容
              Opacity(
                opacity: isUploading ? 0.5 : 1.0,
                child: IgnorePointer(
                  ignoring: isUploading,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(TSizes.defaultSpace),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Section
                        _buildProfileSection(userController, darkMode),

                        SizedBox(height: TSizes.spaceBtwSections),

                        // Post Type Selection
                        _buildPostTypeSelector(controller, darkMode),

                        SizedBox(height: TSizes.spaceBtwItems),

                        // Content Input
                        _buildContentInput(controller, darkMode),

                        SizedBox(height: TSizes.spaceBtwItems),

                        // Media Section
                        _buildMediaSection(controller),

                        SizedBox(height: TSizes.spaceBtwSections),

                        // Media Info
                        _buildMediaInfo(darkMode),
                      ],
                    ),
                  ),
                ),
              ),

              // 上传遮罩层 - 只在真正上传时显示
              if (isUploading) _buildUploadOverlay(controller),
            ],
          );
        }),
      ),
    );
  }

  // 添加上传遮罩层
  Widget _buildUploadOverlay(PostCreateController controller) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: Container(
            padding: EdgeInsets.all(TSizes.lg),
            decoration: BoxDecoration(
              color: Get.theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
              boxShadow: [
                BoxShadow(
                  blurRadius: 10,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(TColors.primary),
                  ),
                ),
                SizedBox(height: TSizes.md),
                Text(
                  controller.isEditingMode.value
                      ? 'Updating Post...'
                      : 'Creating Post...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: TSizes.sm),
                Text(
                  'Please wait while we process your content',
                  style: TextStyle(
                    fontSize: 14,
                    color: TColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 内容输入框，只在真正上传时禁用
  Widget _buildContentInput(PostCreateController controller, bool darkMode) {
    const int maxPostLength = 5000;

    return Obx(() {
      final isUploading = controller.isCreatingPost.value;
      // 使用响应式字符计数
      final currentLength = controller.characterCount.value;
      final remaining = maxPostLength - currentLength;
      final isNearLimit = remaining <= 200;
      final isOverLimit = remaining < 0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Character counter
          if (isNearLimit || currentLength > 0) // 使用 currentLength 替代 controller.contentController.text.isNotEmpty
            Padding(
              padding: EdgeInsets.only(bottom: TSizes.xs),
              child: Text(
                '$remaining characters remaining',
                style: TextStyle(
                  fontSize: 12,
                  color: isOverLimit
                      ? TColors.error
                      : (isNearLimit ? TColors.warning : TColors.textSecondary),
                  fontWeight: isOverLimit ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),

          // Text field
          Container(
            padding: EdgeInsets.all(TSizes.md),
            decoration: BoxDecoration(
              color: darkMode ? TColors.darkContainer : TColors.white,
              borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
              border: Border.all(
                color: isOverLimit
                    ? TColors.error
                    : (darkMode ? TColors.darkGrey : TColors.borderPrimary),
                width: isOverLimit ? 2 : 1,
              ),
            ),
            child: TextField(
              controller: controller.contentController,
              maxLines: null,
              minLines: 4,
              maxLength: maxPostLength,
              enabled: !isUploading,
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                // Hide the default counter
                return null;
              },
              inputFormatters: [
                LengthLimitingTextInputFormatter(maxPostLength),
              ],
              style: TextStyle(
                fontSize: 16,
                color: darkMode ? TColors.white : TColors.black,
              ),
              decoration: InputDecoration(
                hintText: "What's on your mind?",
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: darkMode ? TColors.darkGrey : TColors.textSecondary,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      );
    });
  }

  // 媒体选择器，只在真正上传时禁用
  Widget _buildPostTypeSelector(PostCreateController controller, bool darkMode) {
    return Obx(() {
      final isUploading = controller.isCreatingPost.value;

      return GestureDetector(
        onTap: isUploading ? null : controller.showPostTypeSelector,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: TSizes.md,
            vertical: TSizes.md,
          ),
          decoration: BoxDecoration(
            color: darkMode ? TColors.darkContainer : TColors.lightContainer,
            borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
            border: Border.all(
              color: darkMode ? TColors.darkGrey : TColors.borderPrimary,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.category_outlined,
                color: TColors.primary,
                size: 20,
              ),
              SizedBox(width: TSizes.sm),
              Expanded(
                child: Obx(() => Text(
                  controller.selectedPostType.value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: darkMode ? TColors.white : TColors.black,
                  ),
                )),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                color: isUploading
                    ? TColors.textSecondary.withOpacity(0.5)
                    : darkMode ? TColors.darkGrey : TColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildProfileSection(UserController userController, bool darkMode) {
    final frameController = AvatarFrameController.instance;

    return Obx(() {
      final user = userController.user.value;
      final currentFrame = frameController.getCurrentFrame();
      final frameIconUrl = currentFrame?.reward.icon;

      return Row(
        children: [
          AvatarWithFrame(
            profileImageUrl: user.profileImg,
            frameIconUrl: frameIconUrl,
            avatarSize: 48,  // 头像大小
            frameSize: 58,   // 头像框大小
          ),
          SizedBox(width: TSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username.isNotEmpty ? user.username : 'Anonymous',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: darkMode ? TColors.white : TColors.black,
                  ),
                ),
                Text(
                  'Public',
                  style: TextStyle(
                    fontSize: 14,
                    color: darkMode ? TColors.darkGrey : TColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildMediaSection(PostCreateController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Media',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Obx(() => Text(
              '${controller.mediaItems.length}/${MediaUtils.maxMediaCount}',
              style: TextStyle(
                fontSize: 12,
                color: TColors.textSecondary,
              ),
            )),
          ],
        ),
        SizedBox(height: TSizes.sm),

        Obx(() {
          final items = controller.mediaItems.toList();

          return MediaGridWidget(
            mediaItems: items,
            onMediaTap: controller.openMediaPreview,
            onMediaDelete: controller.removeMediaItem,
            onAddMedia: controller.showMediaOptions,
            maxMediaCount: MediaUtils.maxMediaCount,
          );
        }),

        // 只有在有媒体正在处理时才显示处理指示器
        Obx(() {
          final hasProcessingMedia = controller.mediaItems.any((item) => item.isProcessing);
          return hasProcessingMedia
              ? Container(
            margin: EdgeInsets.only(top: TSizes.sm),
            padding: EdgeInsets.all(TSizes.sm),
            decoration: BoxDecoration(
              color: TColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
              border: Border.all(
                color: TColors.info.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(TColors.info),
                  ),
                ),
                SizedBox(width: TSizes.sm),
                Text(
                  'Downloading media files...',
                  style: TextStyle(
                    color: TColors.info,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )
              : SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildMediaInfo(bool darkMode) {
    return Container(
      padding: EdgeInsets.fromLTRB(TSizes.md, TSizes.md, TSizes.md, TSizes.xs),
      decoration: BoxDecoration(
        color: TColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
        border: Border.all(
          color: TColors.info.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: TColors.info,
                size: 16,
              ),
              SizedBox(width: TSizes.xs),
              Text(
                'Media Guidelines',
                style: TextStyle(
                  color: TColors.info,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: TSizes.xs),
          Text(
            '• Images: Max 5MB\n'
                '• Videos: Max 20MB\n'
                '• Maximum ${MediaUtils.maxMediaCount} files per post\n',
            style: TextStyle(
              color: TColors.info,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}