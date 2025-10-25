import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../common/widgets/images/t_circular_image.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/image_strings.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../../personalization/controllers/user_controller.dart';
import '../../create_post/create_post_screen.dart';

class FeedMakePostWidget extends StatelessWidget {
  const FeedMakePostWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = Get.put(UserController());
    final isDark = THelperFunctions.isDarkMode(context);

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: const EdgeInsets.all(TSizes.md),
        decoration: BoxDecoration(
          color: isDark ? TColors.darkContainer : TColors.white,
          borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
          border: Border.all(
            color: isDark
                ? TColors.borderPrimary.withOpacity(0.1)
                : TColors.borderPrimary.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Obx(() {
          final user = userController.user.value;

          return Row(
            children: [
              // User profile image
              TCircularImage(
                image: user.profileImg.isNotEmpty ? user.profileImg : TImages.user,
                width: 40,
                height: 40,
                padding: 0,
                backgroundColor: isDark ? TColors.darkGrey : TColors.lightGrey,
                isNetworkImage: user.profileImg.isNotEmpty,
              ),
              const SizedBox(width: TSizes.md),

              // Post input field
              Expanded(
                child: GestureDetector(
                  onTap: () => Get.to(() => const CreatePostScreen()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? TColors.darkGrey.withOpacity(0.3) : TColors.lightGrey,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isDark
                            ? TColors.borderPrimary.withOpacity(0.2)
                            : TColors.borderPrimary.withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      "What's on your mind, ${user.username}?",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? TColors.darkGrey : TColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: TSizes.sm),

              // Media button
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.photo_camera,
                  color: TColors.success,
                  size: 20,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}