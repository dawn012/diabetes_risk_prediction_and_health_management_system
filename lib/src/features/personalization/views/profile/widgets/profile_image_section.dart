import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../common/loaders/loaders.dart';
import '../../../../../common/widgets/camera/media_picker.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/enums.dart';
import '../../../../../utils/constants/image_strings.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/image_helper.dart';
import '../../../controllers/update_profile_controller.dart';
import '../../../controllers/user_controller.dart';
import '../../widgets/avatar_with_frame.dart';

/// Profile Image Section with tap to view and change
class ProfileImageSection extends StatelessWidget {
  const ProfileImageSection({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = UserController.instance;
    final updateController = UpdateProfileController.instance;

    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          Obx(() {
            final pendingImage = updateController.pendingProfileImage.value;
            final currentImageUrl = userController.user.value.profileImg;

            return Stack(
              children: [
                // Profile Image with Frame - 替换为 AvatarWithFrame
                GestureDetector(
                  onTap: () => _showFullScreenImage(
                    context,
                    pendingImage,
                    currentImageUrl,
                  ),
                  child: Hero(
                    tag: 'profile_image',
                    child: pendingImage != null
                        ? Container(
                      width: 120, // 调整大小以适应头像框
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: FileImage(pendingImage),
                          fit: BoxFit.cover,
                        ),
                        border: Border.all(
                          color: TColors.primary,
                          width: 3,
                        ),
                      ),
                    )
                        : AvatarWithFrame(
                      profileImageUrl: currentImageUrl,
                      avatarSize: 100,  // 头像大小
                      frameSize: 120,   // 头像框大小
                    ),
                  ),
                ),

                // Pending change indicator
                if (pendingImage != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: TColors.warning,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Iconsax.clock_bold,
                        color: TColors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            );
          }),

          const SizedBox(height: TSizes.sm),

          // Change Profile Picture Button
          TextButton.icon(
            onPressed: () => _handleChangeProfilePicture(context, updateController),
            icon: const Icon(Iconsax.camera_bold, size: 16),
            label: const Text('Change Profile Picture'),
          ),

          // Pending changes hint
          Obx(() {
            if (updateController.pendingProfileImage.value != null) {
              return Container(
                margin: const EdgeInsets.only(top: TSizes.xs),
                padding: const EdgeInsets.symmetric(
                  horizontal: TSizes.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: TColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
                ),
                child: const Text(
                  'Tap ✓ above to save',
                  style: TextStyle(
                    fontSize: 12,
                    color: TColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  /// Handle change profile picture
  Future<void> _handleChangeProfilePicture(
      BuildContext context,
      UpdateProfileController updateController,
      ) async {
    try {
      // Show media picker
      final option = await MediaPicker.showImagePickerOptions(context: context);

      if (option == null) return;

      File? imageFile;

      // Handle selected option
      switch (option.type) {
        case MediaOptionType.gallery:
          imageFile = await ImageHelper.pickImage();
          break;
        case MediaOptionType.camera:
          imageFile = await ImageHelper.takePhoto();
          break;
        default:
          break;
      }

      // Update pending image if file was selected
      if (imageFile != null) {
        updateController.updatePendingProfileImage(imageFile);
      }
    } catch (e) {
      print('Error changing profile picture: $e');
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to select image. Please try again.',
      );
    }
  }

  /// Show full screen image
  void _showFullScreenImage(
      BuildContext context,
      File? pendingImage,
      String currentImageUrl,
      ) {
    // Don't show if no image
    if (pendingImage == null && currentImageUrl.isEmpty) {
      return;
    }

    Get.to(
          () => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ),
        body: GestureDetector(
          onTap: () => Get.back(),
          child: Stack(
            children: [
              // 黑色背景，覆盖整个屏幕
              Positioned.fill(
                child: Container(
                  color: Colors.black,
                ),
              ),
              // 图片内容
              Center(
                child: Hero(
                  tag: 'profile_image',
                  child: GestureDetector(
                    // 阻止图片区域的点击事件冒泡到父级 GestureDetector
                    onTap: () {},
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: pendingImage != null
                          ? Image.file(
                        pendingImage,
                        fit: BoxFit.contain,
                      )
                          : currentImageUrl.isNotEmpty
                          ? Image.network(
                        currentImageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                                  : null,
                              color: TColors.primary,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 50,
                            ),
                          );
                        },
                      )
                          : Image.asset(
                        TImages.user,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      transition: Transition.fade,
      fullscreenDialog: true,
    );
  }
}