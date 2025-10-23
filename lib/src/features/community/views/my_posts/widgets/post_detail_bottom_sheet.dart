import 'package:diabetes_risk_prediction_and_health_management_system/src/utils/extensions/date_time_extension.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../models/post_model.dart';

class PostDetailBottomSheet extends StatelessWidget {
  final PostModel post;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const PostDetailBottomSheet({
    super.key,
    required this.post,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);
    final isDisabled = post.isDisable;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: darkMode ? TColors.dark : TColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(TSizes.cardRadiusLg),
          topRight: Radius.circular(TSizes.cardRadiusLg),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: TSizes.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: darkMode ? TColors.darkGrey : TColors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with actions
          Container(
            padding: EdgeInsets.all(TSizes.md),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: darkMode ? TColors.darkGrey : TColors.borderPrimary,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Post type badge
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
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: post.postType.color,
                    ),
                  ),
                ),

                SizedBox(width: TSizes.sm),

                // Status badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: TSizes.sm,
                    vertical: TSizes.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isDisabled
                        ? TColors.error.withOpacity(0.1)
                        : TColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
                    border: Border.all(
                      color: isDisabled ? TColors.error : TColors.success,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDisabled ? Icons.block : Icons.check_circle,
                        size: 12,
                        color: isDisabled ? TColors.error : TColors.success,
                      ),
                      SizedBox(width: 4),
                      Text(
                        isDisabled ? 'Disabled' : 'Active',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDisabled ? TColors.error : TColors.success,
                        ),
                      ),
                    ],
                  ),
                ),

                Spacer(),

                // Close button
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Get.back(),
                  color: darkMode ? TColors.white : TColors.black,
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(TSizes.defaultSpace),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post content
                  Text(
                    post.postContent,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      height: 1.5,
                    ),
                  ),

                  // Media section
                  if (post.mediaUrls.isNotEmpty) ...[
                    SizedBox(height: TSizes.spaceBtwSections),
                    _buildMediaSection(context, darkMode),
                  ],

                  SizedBox(height: TSizes.spaceBtwSections),

                  // Stats section
                  _buildStatsSection(context, darkMode),

                  SizedBox(height: TSizes.spaceBtwItems),

                  // Metadata
                  _buildMetadataSection(context, darkMode),
                ],
              ),
            ),
          ),

          // Action buttons
          Container(
            padding: EdgeInsets.all(TSizes.defaultSpace),
            decoration: BoxDecoration(
              color: darkMode
                  ? TColors.darkContainer
                  : TColors.lightContainer,
              border: Border(
                top: BorderSide(
                  color: darkMode ? TColors.darkGrey : TColors.borderPrimary,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Edit button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onEdit,
                        icon: Icon(Iconsax.edit_bold, size: 18),
                        label: Text('Edit Post'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TColors.primary,
                          padding: EdgeInsets.symmetric(vertical: TSizes.md),
                        ),
                      ),
                    ),

                    SizedBox(width: TSizes.sm),

                    // Toggle status button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onToggleStatus,
                        icon: Icon(
                          isDisabled
                              ? Iconsax.eye_bold
                              : Iconsax.eye_slash_bold,
                          size: 18,
                        ),
                        label: Text(isDisabled ? 'Enable' : 'Disable'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                          isDisabled ? TColors.success : TColors.warning,
                          side: BorderSide(
                            color: isDisabled
                                ? TColors.success
                                : TColors.warning,
                          ),
                          padding: EdgeInsets.symmetric(vertical: TSizes.md),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: TSizes.sm),

                // Delete button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: Icon(Iconsax.trash_bold, size: 18),
                    label: Text('Delete Post'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TColors.error,
                      side: BorderSide(color: TColors.error),
                      padding: EdgeInsets.symmetric(vertical: TSizes.md),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection(BuildContext context, bool darkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.collections,
              size: 18,
              color: darkMode ? TColors.white : TColors.black,
            ),
            SizedBox(width: TSizes.xs),
            Text(
              'Media (${post.mediaUrls.length})',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: TSizes.sm),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: TSizes.xs,
            mainAxisSpacing: TSizes.xs,
            childAspectRatio: 1,
          ),
          itemCount: post.mediaUrls.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                // TODO: Open media viewer
                _showMediaViewer(context, index);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
                child: Image.network(
                  post.mediaUrls[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: darkMode ? TColors.darkerGrey : TColors.grey,
                      child: Icon(
                        Icons.broken_image,
                        color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, bool darkMode) {
    return Container(
      padding: EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: darkMode
            ? TColors.darkContainer.withOpacity(0.5)
            : TColors.lightContainer,
        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
        border: Border.all(
          color: darkMode ? TColors.darkGrey : TColors.borderPrimary,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context: context,
            icon: Icons.favorite,
            label: 'Likes',
            value: post.likes.length.toString(),
            color: TColors.error,
            darkMode: darkMode,
          ),
          Container(
            height: 40,
            width: 1,
            color: darkMode ? TColors.darkGrey : TColors.borderPrimary,
          ),
          _buildStatItem(
            context: context,
            icon: Icons.comment,
            label: 'Comments',
            value: post.commentCount.toString(),
            color: TColors.info,
            darkMode: darkMode,
          ),
          Container(
            height: 40,
            width: 1,
            color: darkMode ? TColors.darkGrey : TColors.borderPrimary,
          ),
          _buildStatItem(
            context: context,
            icon: Icons.collections,
            label: 'Media',
            value: post.mediaUrls.length.toString(),
            color: TColors.success,
            darkMode: darkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool darkMode,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: TSizes.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.bold,
            color: darkMode ? TColors.white : TColors.black,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataSection(BuildContext context, bool darkMode) {
    return Container(
      padding: EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: darkMode
            ? TColors.darkContainer.withOpacity(0.3)
            : TColors.lightContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
        border: Border.all(
          color: darkMode ? TColors.darkGrey : TColors.borderPrimary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetadataRow(
            context: context,
            icon: Icons.calendar_today,
            label: 'Created',
            value: post.createdAt.yMMMEd(),
            darkMode: darkMode,
          ),
          SizedBox(height: TSizes.sm),
          _buildMetadataRow(
            context: context,
            icon: Icons.update,
            label: 'Last Updated',
            value: post.updatedAt.fromNow(),
            darkMode: darkMode,
          ),
          SizedBox(height: TSizes.sm),
          _buildMetadataRow(
            context: context,
            icon: Icons.folder,
            label: 'Post ID',
            value: post.postId.substring(0, 8) + '...',
            darkMode: darkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required bool darkMode,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
        ),
        SizedBox(width: TSizes.xs),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: darkMode ? TColors.white : TColors.black,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showMediaViewer(BuildContext context, int initialIndex) {
    // TODO: Implement full-screen media viewer
    Get.dialog(
      Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: post.mediaUrls.length,
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  child: Center(
                    child: Image.network(
                      post.mediaUrls[index],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                color: Colors.white54,
                                size: 64,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Failed to load image',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Get.back(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}