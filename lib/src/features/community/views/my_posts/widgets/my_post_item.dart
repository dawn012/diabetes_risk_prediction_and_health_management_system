import 'package:diabetes_risk_prediction_and_health_management_system/src/utils/extensions/date_time_extension.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/my_post_controller.dart';
import '../../../models/post_model.dart';

class MyPostItem extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onTap;

  const MyPostItem({
    super.key,
    required this.post,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final controller = MyPostController.instance;
    final darkMode = THelperFunctions.isDarkMode(context);
    final isDisabled = post.isDisable;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: TSizes.md),
        decoration: BoxDecoration(
          color: isDisabled
              ? (darkMode
              ? TColors.postDisabledBgDark.withOpacity(0.3)
              : TColors.postDisabledBg)
              : (darkMode ? TColors.dark : TColors.white),
          borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
          border: Border.all(
            color: isDisabled
                ? (darkMode ? TColors.postDisabledDark : TColors.postDisabled)
                : (darkMode ? TColors.darkGrey : TColors.grey),
            width: isDisabled ? 2 : 1,
          ),
          boxShadow: isDisabled
              ? []
              : [
            BoxShadow(
              color: darkMode
                  ? Colors.black26
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Status Badge + Actions
            Container(
              padding: EdgeInsets.all(TSizes.sm),
              decoration: BoxDecoration(
                color: isDisabled
                    ? (darkMode
                    ? TColors.postDisabled.withOpacity(0.2)
                    : TColors.postDisabledLight)
                    : (darkMode
                    ? TColors.success.withOpacity(0.1)
                    : TColors.successLight.withOpacity(0.3)),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(TSizes.cardRadiusLg),
                  topRight: Radius.circular(TSizes.cardRadiusLg),
                ),
              ),
              child: Row(
                children: [
                  // Status Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: TSizes.sm,
                      vertical: TSizes.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isDisabled
                          ? TColors.postDisabled
                          : TColors.success,
                      borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDisabled ? Icons.block : Icons.check_circle,
                          size: 14,
                          color: TColors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          isDisabled ? 'Disabled' : 'Active',
                          style: TextStyle(
                            color: TColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: TSizes.sm),

                  // Post Type Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: TSizes.sm,
                      vertical: TSizes.xs,
                    ),
                    decoration: BoxDecoration(
                      color: post.postType.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
                      border: Border.all(
                        color: post.postType.color,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      post.postType.shortLabel,
                      style: TextStyle(
                        color: post.postType.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  Spacer(),

                  // Actions Menu
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: darkMode ? TColors.white : TColors.black,
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'toggle':
                          controller.togglePostStatus(post);
                          break;
                        case 'edit':
                        // TODO: Navigate to edit post
                          break;
                        case 'delete':
                          _showDeleteConfirmation(context, controller);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              isDisabled
                                  ? Iconsax.eye_bold
                                  : Iconsax.eye_slash_bold,
                              size: 18,
                            ),
                            SizedBox(width: TSizes.sm),
                            Text(isDisabled ? 'Enable Post' : 'Disable Post'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Iconsax.edit_bold, size: 18),
                            SizedBox(width: TSizes.sm),
                            Text('Edit Post'),
                          ],
                        ),
                      ),
                      PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.trash_bold,
                              size: 18,
                              color: TColors.error,
                            ),
                            SizedBox(width: TSizes.sm),
                            Text(
                              'Delete Post',
                              style: TextStyle(color: TColors.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(TSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post Content
                  Text(
                    post.postContent,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: isDisabled
                          ? (darkMode
                          ? TColors.darkGrey
                          : TColors.darkerGrey)
                          : null,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (post.mediaUrls.isNotEmpty) ...[
                    SizedBox(height: TSizes.sm),
                    // Media Preview
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: darkMode ? TColors.darkerGrey : TColors.grey,
                        borderRadius:
                        BorderRadius.circular(TSizes.borderRadiusMd),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius:
                            BorderRadius.circular(TSizes.borderRadiusMd),
                            child: Image.network(
                              post.mediaUrls.first,
                              width: double.infinity,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: TColors.darkGrey,
                                    size: 40,
                                  ),
                                );
                              },
                            ),
                          ),
                          if (post.mediaUrls.length > 1)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: TSizes.sm,
                                  vertical: TSizes.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(
                                      TSizes.borderRadiusSm),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.collections,
                                      size: 14,
                                      color: TColors.white,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '+${post.mediaUrls.length - 1}',
                                      style: TextStyle(
                                        color: TColors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: TSizes.md),

                  // Stats Row
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.favorite,
                        label: post.likes.length.toString(),
                        color: TColors.error,
                      ),
                      SizedBox(width: TSizes.sm),
                      _StatChip(
                        icon: Icons.comment,
                        label: post.commentCount.toString(),
                        color: TColors.info,
                      ),
                      Spacer(),
                      Text(
                        post.createdAt.fromNow(),
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: darkMode
                              ? TColors.darkGrey
                              : TColors.darkerGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, MyPostController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Post'),
        content: Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deletePost(post);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TColors.error,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: TSizes.sm,
        vertical: TSizes.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}