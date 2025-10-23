import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/images/t_circular_image.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../../utils/helpers/media_helper.dart';
import '../../../personalization/controllers/user_controller.dart';
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
      controller.initializeForEditing(postToEdit!);
    }

    return WillPopScope(
      onWillPop: () async {
        return await controller.checkUnsavedChanges();
      },
      child: Scaffold(
        backgroundColor: darkMode ? TColors.dark : TColors.light,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: darkMode ? TColors.dark : TColors.white,
          leading: IconButton(
            onPressed: () async {
              final canPop = await controller.checkUnsavedChanges();
              if (canPop) Get.back();
            },
            icon: Icon(
              Icons.close,
              color: darkMode ? TColors.white : TColors.black,
            ),
          ),
          title: Text(
            'Create Post',
            style: TextStyle(
              color: darkMode ? TColors.white : TColors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            Obx(() => TextButton(
              onPressed: controller.isCreatingPost.value
                  ? null
                  : controller.createPost,
              child: controller.isCreatingPost.value
                  ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(TColors.primary),
                ),
              )
                  : Text(
                'Post',
                style: TextStyle(
                  color: TColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )),
            SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
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
    );
  }

  Widget _buildProfileSection(UserController userController, bool darkMode) {
    return Obx(() {
      final user = userController.user.value;
      return Row(
        children: [
          TCircularImage(
            image: user.profileImg.isNotEmpty
                ? user.profileImg
                : TImages.user,
            isNetworkImage: user.profileImg.isNotEmpty,
            width: 48,
            height: 48,
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

  Widget _buildPostTypeSelector(PostCreateController controller, bool darkMode) {
    return GestureDetector(
      onTap: controller.showPostTypeSelector,
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
              color: darkMode ? TColors.darkGrey : TColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentInput(PostCreateController controller, bool darkMode) {
    return Container(
      padding: EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: darkMode ? TColors.darkContainer : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
        border: Border.all(
          color: darkMode ? TColors.darkGrey : TColors.borderPrimary,
        ),
      ),
      child: TextField(
        controller: controller.contentController,
        maxLines: null,
        minLines: 4,
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
    );
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

        // Processing indicator
        Obx(() => controller.isProcessingMedia.value
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
                'Processing media files...',
                style: TextStyle(
                  color: TColors.info,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        )
            : SizedBox.shrink()),
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