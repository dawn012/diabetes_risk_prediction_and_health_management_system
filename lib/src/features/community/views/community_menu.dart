import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../controllers/community_menu_controller.dart';
import '../controllers/post_controller.dart';
import 'my_posts/my_posts_screen.dart';
import 'posts/posts_screen.dart';
import 'videos/videos_screen.dart';

class CommunityMenu extends StatelessWidget {
  const CommunityMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CommunityController());
    final postController = Get.put(PostController());
    final isDark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : TColors.primaryBackground,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? TColors.darkContainer : TColors.white,
        title: Row(
          children: [
            // App icon with gradient background
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [TColors.primary, TColors.primary.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.groups_rounded,
                color: TColors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: TSizes.md),

            // Title with modern typography
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: isDark ? TColors.white : TColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Connect & Share',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? TColors.lightGrey : TColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Custom tab bar as bottom widget
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? TColors.darkContainer : TColors.white,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? TColors.borderPrimary.withOpacity(0.3)
                      : TColors.borderPrimary.withOpacity(0.5),
                  width: 0.5,
                ),
              ),
            ),
            child: _buildModernTabBar(controller, isDark),
          ),
        ),
      ),

      body: Column(
        children: [
          // Filter chips - only show on Posts tab
          Obx(() {
            if (controller.currentIndex.value == 0) {
              return _buildFilterChips(postController, isDark);
            }
            return const SizedBox.shrink();
          }),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: controller.tabController,
              children: const [
                PostsScreen(),
                _FriendsPlaceholder(),
                MyPostsScreen(),
                // VideosScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build modern custom tab bar
  Widget _buildModernTabBar(CommunityController controller, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: TSizes.md),
      child: Obx(() => Row(
        children: [
          _buildTabButton(
            controller: controller,
            index: 0,
            icon: Icons.home_rounded,
            label: 'Posts',
            isDark: isDark,
          ),
          _buildTabButton(
            controller: controller,
            index: 1,
            icon: Icons.people_rounded,
            label: 'Friends',
            isDark: isDark,
          ),
          _buildTabButton(
            controller: controller,
            index: 2,
            icon: Icons.play_circle_rounded,
            label: 'My Posts',
            isDark: isDark,
          ),
        ],
      )),
    );
  }

  /// Build individual tab button
  Widget _buildTabButton({
    required CommunityController controller,
    required int index,
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = controller.currentIndex.value == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          controller.currentIndex.value = index;
          controller.tabController.animateTo(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? TColors.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: TColors.primary.withOpacity(0.3))
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? TColors.primary
                      : (isDark ? TColors.darkGrey.withOpacity(0.3) : TColors.lightGrey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? TColors.white
                      : (isDark ? TColors.lightGrey : TColors.textSecondary),
                  size: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? TColors.primary
                      : (isDark ? TColors.lightGrey : TColors.textSecondary),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build filter chips for post types
  Widget _buildFilterChips(PostController postController, bool isDark) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkContainer : TColors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? TColors.borderPrimary.withOpacity(0.3)
                : TColors.borderPrimary.withOpacity(0.5),
            width: 0.5,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: TSizes.md),
        itemCount: postController.postTypeFilters.length,
        itemBuilder: (context, index) {
          return Obx(() {
            final filterType = postController.postTypeFilters[index];
            final isSelected = postController.selectedPostType.value == filterType;
            final count = postController.getPostTypeCount(filterType);

            return Container(
              margin: const EdgeInsets.only(right: TSizes.sm),
              child: FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      postController.getPostTypeLabel(filterType),
                      style: TextStyle(
                        color: isSelected
                            ? TColors.white
                            : (isDark ? TColors.lightGrey : TColors.textPrimary),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? TColors.white.withOpacity(0.2)
                              : TColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count.toString(),
                          style: TextStyle(
                            color: isSelected
                                ? TColors.white
                                : TColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  postController.filterByPostType(filterType);
                },
                backgroundColor: isDark
                    ? TColors.darkGrey.withOpacity(0.3)
                    : TColors.lightGrey,
                selectedColor: TColors.primary,
                checkmarkColor: Colors.transparent,
                side: BorderSide(
                  color: isSelected
                      ? TColors.primary
                      : (isDark ? TColors.borderPrimary.withOpacity(0.3) : TColors.borderPrimary),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          });
        },
      ),
    );
  }
}

/// Placeholder widget for Friends tab
class _FriendsPlaceholder extends StatelessWidget {
  const _FriendsPlaceholder();

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(TSizes.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration container
          Container(
            width: 120,
            height: 120,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: TColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: TColors.primary.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.people_outline_rounded,
              size: 72,
              color: TColors.primary,
            ),
          ),

          const SizedBox(height: TSizes.lg),

          // Title
          Text(
            'Friends Feature',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: isDark ? TColors.white : TColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: TSizes.sm),

          // Description
          Text(
            'Connect with friends and see their activities.\nThis feature is coming soon!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: isDark ? TColors.lightGrey : TColors.textSecondary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: TSizes.xl),

          // Action button
          SizedBox(
            width: 200,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement friends feature or show more info
                Get.snackbar(
                  'Coming Soon',
                  'The friends feature will be available in the next update!',
                  backgroundColor: TColors.primary.withOpacity(0.1),
                  colorText: TColors.primary,
                  snackPosition: SnackPosition.BOTTOM,
                  margin: const EdgeInsets.all(TSizes.md),
                  borderRadius: 12,
                  duration: const Duration(seconds: 3),
                );
              },
              icon: Icon(
                Icons.notifications_outlined,
                size: 20,
                color: TColors.white,
              ),
              label: Text(
                'Notify Me',
                style: TextStyle(
                  color: TColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}