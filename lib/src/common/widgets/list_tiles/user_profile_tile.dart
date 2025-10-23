import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../features/personalization/controllers/user_controller.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/image_strings.dart';
import '../images/t_circular_image.dart';
import '../shimmer/shimmer.dart';

class TUserProfileTile extends StatelessWidget {
  const TUserProfileTile({
    super.key,
    required this.onPressed,
    this.showEditButton = true,
    this.isLoading = false,
  });

  final VoidCallback onPressed;
  final bool showEditButton;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final controller = UserController.instance;

    return Obx(() {
      final user = controller.user.value;
      final imageUrl = user.profileImg;
      final isUserLoading = controller.profileLoading.value || isLoading;

      // Show shimmer effect when loading
      if (isUserLoading) {
        return _buildShimmerProfileTile();
      }

      return ListTile(
        leading: TCircularImage(
          image: imageUrl.isNotEmpty ? imageUrl : TImages.user,
          width: 50,
          height: 50,
          padding: 0,
          isNetworkImage: imageUrl.isNotEmpty,
        ),
        title: Text(
          user.username.isNotEmpty ? user.username : 'User',
          style: Theme.of(context).textTheme.headlineSmall!.apply(color: TColors.white),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          user.email,
          style: Theme.of(context).textTheme.bodyMedium!.apply(color: TColors.white.withOpacity(0.8)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: showEditButton
            ? IconButton(
          onPressed: onPressed,
          icon: const Icon(Iconsax.edit_bold, color: TColors.white),
          tooltip: 'Edit Profile',
        )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onPressed,
      );
    });
  }

  /// Shimmer loading effect for user profile tile
  Widget _buildShimmerProfileTile() {
    return ListTile(
      leading: const TShimmerEffect(width: 50, height: 50, radius: 25),
      title: const TShimmerEffect(width: 120, height: 16, radius: 4),
      subtitle: const TShimmerEffect(width: 160, height: 14, radius: 4),
      trailing: showEditButton
          ? const TShimmerEffect(width: 24, height: 24, radius: 12)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}