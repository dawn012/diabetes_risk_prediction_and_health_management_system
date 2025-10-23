import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/my_post_controller.dart';

class MyPostsStatsCard extends StatelessWidget {
  const MyPostsStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = MyPostController.instance;
    final darkMode = THelperFunctions.isDarkMode(context);

    return Obx(() {
      if (controller.isLoadingStats.value) {
        return _buildLoadingSkeleton(darkMode);
      }

      final stats = controller.stats;
      final totalPosts = stats['totalPosts'] ?? 0;
      final activePosts = stats['activePosts'] ?? 0;
      final disabledPosts = stats['disabledPosts'] ?? 0;
      final totalLikes = stats['totalLikes'] ?? 0;
      final totalComments = stats['totalComments'] ?? 0;

      return Container(
        padding: EdgeInsets.all(TSizes.md),
        decoration: BoxDecoration(
          color: darkMode ? TColors.dark : TColors.white,
          borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
          boxShadow: [
            BoxShadow(
              color: darkMode
                  ? Colors.black26
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Posts Overview',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: TSizes.spaceBtwItems),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.article_outlined,
                    label: 'Total Posts',
                    value: totalPosts.toString(),
                    color: TColors.primary,
                    darkMode: darkMode,
                  ),
                ),
                SizedBox(width: TSizes.sm),
                Expanded(
                  child: _StatItem(
                    icon: Icons.check_circle_outline,
                    label: 'Active',
                    value: activePosts.toString(),
                    color: TColors.success,
                    darkMode: darkMode,
                  ),
                ),
                SizedBox(width: TSizes.sm),
                Expanded(
                  child: _StatItem(
                    icon: Icons.block_outlined,
                    label: 'Disabled',
                    value: disabledPosts.toString(),
                    color: TColors.postDisabled,
                    darkMode: darkMode,
                  ),
                ),
              ],
            ),
            SizedBox(height: TSizes.sm),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.favorite_outline,
                    label: 'Total Likes',
                    value: totalLikes.toString(),
                    color: TColors.error,
                    darkMode: darkMode,
                  ),
                ),
                SizedBox(width: TSizes.sm),
                Expanded(
                  child: _StatItem(
                    icon: Icons.comment_outlined,
                    label: 'Comments',
                    value: totalComments.toString(),
                    color: TColors.info,
                    darkMode: darkMode,
                  ),
                ),
                Expanded(child: SizedBox()), // Empty space for alignment
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLoadingSkeleton(bool darkMode) {
    return Container(
      padding: EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: darkMode ? TColors.dark : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
      ),
      child: Column(
        children: List.generate(3, (index) {
          return Container(
            margin: EdgeInsets.only(bottom: TSizes.sm),
            height: 60,
            decoration: BoxDecoration(
              color: darkMode ? TColors.darkerGrey : TColors.grey,
              borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
            ),
          );
        }),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool darkMode;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(TSizes.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
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
          SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}