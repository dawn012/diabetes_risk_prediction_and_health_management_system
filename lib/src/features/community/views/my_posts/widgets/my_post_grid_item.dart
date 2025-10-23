import 'package:flutter/material.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../models/post_model.dart';

class MyPostGridItem extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;

  const MyPostGridItem({
    super.key,
    required this.post,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);
    final isDisabled = post.isDisable;
    final hasMedia = post.mediaUrls.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDisabled
              ? (darkMode
              ? TColors.darkContainer.withOpacity(0.5)
              : TColors.lightContainer.withOpacity(0.5))
              : (darkMode ? TColors.darkContainer : TColors.white),
          borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
          border: Border.all(
            color: isDisabled
                ? (darkMode ? TColors.error.withOpacity(0.5) : TColors.error.withOpacity(0.3))
                : (darkMode ? TColors.darkGrey : TColors.borderPrimary),
            width: isDisabled ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Media preview or content preview
                Expanded(
                  child: hasMedia
                      ? _buildMediaPreview(darkMode)
                      : _buildContentPreview(darkMode, isDisabled),
                ),

                // Bottom info bar
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: TSizes.xs,
                    vertical: TSizes.xs,
                  ),
                  decoration: BoxDecoration(
                    color: darkMode
                        ? TColors.dark.withOpacity(0.8)
                        : TColors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(TSizes.borderRadiusMd),
                      bottomRight: Radius.circular(TSizes.borderRadiusMd),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Like count
                      Icon(
                        Icons.favorite,
                        size: 12,
                        color: TColors.error.withOpacity(0.8),
                      ),
                      SizedBox(width: 2),
                      Text(
                        '${post.likes.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: darkMode ? TColors.white : TColors.black,
                        ),
                      ),
                      SizedBox(width: TSizes.xs),
                      // Comment count
                      Icon(
                        Icons.comment,
                        size: 12,
                        color: TColors.info.withOpacity(0.8),
                      ),
                      SizedBox(width: 2),
                      Text(
                        '${post.commentCount}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: darkMode ? TColors.white : TColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Status badge (top-left)
            if (isDisabled)
              Positioned(
                top: TSizes.xs,
                left: TSizes.xs,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: TSizes.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: TColors.error,
                    borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.block,
                        size: 10,
                        color: TColors.white,
                      ),
                      SizedBox(width: 2),
                      Text(
                        'Disabled',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: TColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Post type badge (top-right)
            Positioned(
              top: TSizes.xs,
              right: TSizes.xs,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: TSizes.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: post.postType.color.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
                ),
                child: Text(
                  post.postType.shortLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: TColors.white,
                  ),
                ),
              ),
            ),

            // Multiple media indicator
            if (hasMedia && post.mediaUrls.length > 1)
              Positioned(
                top: TSizes.xs,
                right: TSizes.xs + 40, // Position next to type badge
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.collections,
                        size: 10,
                        color: TColors.white,
                      ),
                      SizedBox(width: 2),
                      Text(
                        '${post.mediaUrls.length}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: TColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview(bool darkMode) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(TSizes.borderRadiusMd),
        topRight: Radius.circular(TSizes.borderRadiusMd),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            post.mediaUrls.first,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: darkMode ? TColors.darkerGrey : TColors.grey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image,
                      color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                      size: 32,
                    ),
                    SizedBox(height: TSizes.xs),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: TSizes.xs),
                      child: Text(
                        post.postContent,
                        style: TextStyle(
                          fontSize: 10,
                          color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: darkMode ? TColors.darkerGrey : TColors.grey,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                    color: TColors.primary,
                  ),
                ),
              );
            },
          ),
          // Gradient overlay for better badge visibility
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentPreview(bool darkMode, bool isDisabled) {
    return Container(
      padding: EdgeInsets.all(TSizes.sm),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            post.postType.color.withOpacity(0.1),
            post.postType.color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(TSizes.borderRadiusMd),
          topRight: Radius.circular(TSizes.borderRadiusMd),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20), // Space for badges
          Expanded(
            child: Text(
              post.postContent,
              style: TextStyle(
                fontSize: 11,
                height: 1.3,
                color: isDisabled
                    ? (darkMode ? TColors.darkGrey : TColors.darkerGrey)
                    : (darkMode ? TColors.white : TColors.black),
              ),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}