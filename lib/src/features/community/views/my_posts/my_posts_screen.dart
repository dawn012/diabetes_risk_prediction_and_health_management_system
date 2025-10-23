import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../common/loaders/circular_loader.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/my_post_controller.dart';
import '../create_post/create_post_screen.dart';
import '../posts/widgets/post_tile.dart';

class MyPostsScreen extends StatelessWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MyPostController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: darkMode ? TColors.dark : TColors.light,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: darkMode ? TColors.dark : TColors.white,
        title: Text(
          'My Posts',
          style: TextStyle(
            color: darkMode ? TColors.white : TColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Filter button
          IconButton(
            icon: Stack(
              children: [
                Icon(
                  Iconsax.filter_bold,
                  color: darkMode ? TColors.white : TColors.black,
                ),
                // Show indicator dot when filters are active
                Obx(() {
                  if (controller.selectedPostType.value != 'all' ||
                      controller.selectedStatus.value != 'all') {
                    return Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: TColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: darkMode ? TColors.dark : TColors.white,
                            width: 1,
                          ),
                        ),
                      ),
                    );
                  }
                  return SizedBox.shrink();
                }),
              ],
            ),
            onPressed: () => _showFilterBottomSheet(context, controller, darkMode),
            tooltip: 'Filter Posts',
          ),
          // Create new post
          IconButton(
            icon: Icon(
              Iconsax.add_circle_bold,
              color: TColors.primary,
            ),
            onPressed: () {
              Get.to(() => CreatePostScreen());
            },
            tooltip: 'Create Post',
          ),
          SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshPosts,
        color: TColors.primary,
        child: Obx(() {
          if (controller.isLoadingPosts.value && controller.myPosts.isEmpty) {
            return CircularLoader(message: 'Loading your posts...');
          }

          if (controller.myPosts.isEmpty) {
            return _buildEmptyState(context, darkMode, controller);
          }

          return CustomScrollView(
            controller: controller.scrollController,
            physics: AlwaysScrollableScrollPhysics(),
            slivers: [
              // Post count header
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.all(TSizes.defaultSpace),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.document_text_bold,
                        size: 20,
                        color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                      ),
                      SizedBox(width: TSizes.xs),
                      Text(
                        '${controller.myPosts.length} ${controller.myPosts.length == 1 ? 'Post' : 'Posts'}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                        ),
                      ),
                      Spacer(),
                      // Active filter indicator
                      if (controller.selectedPostType.value != 'all' ||
                          controller.selectedStatus.value != 'all')
                        GestureDetector(
                          onTap: controller.resetFilters,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: TSizes.sm,
                              vertical: TSizes.xs,
                            ),
                            decoration: BoxDecoration(
                              color: TColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
                              border: Border.all(
                                color: TColors.primary,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Filters Active',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: TColors.primary,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.close,
                                  size: 14,
                                  color: TColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Posts list
              SliverList.separated(
                itemCount: controller.myPosts.length +
                    (controller.isLoadingMore.value ? 1 : 0),
                separatorBuilder: (context, index) => SizedBox(height: 8),
                itemBuilder: (context, index) {
                  // Show loading indicator at the end
                  if (index >= controller.myPosts.length) {
                    return Container(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: TColors.primary,
                        ),
                      ),
                    );
                  }

                  final post = controller.myPosts[index];
                  return PostTile(post: post);
                },
              ),

              // Bottom padding
              SliverToBoxAdapter(
                child: SizedBox(height: TSizes.defaultSpace),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, bool darkMode, MyPostController controller) {
    return CustomScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(TSizes.defaultSpace),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.forum_outlined,
                    size: 80,
                    color: darkMode ? TColors.darkGrey : TColors.grey,
                  ),
                  SizedBox(height: TSizes.spaceBtwItems),
                  Text(
                    _getEmptyStateTitle(controller),
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: TSizes.sm),
                  Text(
                    _getEmptyStateMessage(controller),
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: TSizes.spaceBtwSections),
                  if (controller.selectedPostType.value != 'all' ||
                      controller.selectedStatus.value != 'all')
                    OutlinedButton.icon(
                      onPressed: controller.resetFilters,
                      icon: Icon(Icons.refresh),
                      label: Text('Clear Filters'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: TSizes.lg,
                          vertical: TSizes.md,
                        ),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () {
                        Get.to(() => CreatePostScreen());
                      },
                      icon: Icon(Icons.add),
                      label: Text('Create Your First Post'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: TSizes.lg,
                          vertical: TSizes.md,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getEmptyStateTitle(MyPostController controller) {
    if (controller.selectedPostType.value != 'all' ||
        controller.selectedStatus.value != 'all') {
      return 'No Posts Match Your Filters';
    }
    return 'No Posts Yet';
  }

  String _getEmptyStateMessage(MyPostController controller) {
    if (controller.selectedPostType.value != 'all' ||
        controller.selectedStatus.value != 'all') {
      return 'Try adjusting your filters to see more posts';
    }
    return 'Start sharing your thoughts, tips, and stories with the community!';
  }

  void _showFilterBottomSheet(
      BuildContext context, MyPostController controller, bool darkMode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(TSizes.defaultSpace),
        decoration: BoxDecoration(
          color: darkMode ? TColors.dark : TColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(TSizes.cardRadiusLg),
            topRight: Radius.circular(TSizes.cardRadiusLg),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: TSizes.md),
                decoration: BoxDecoration(
                  color: darkMode ? TColors.darkGrey : TColors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Text(
              'Filter Posts',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: TSizes.spaceBtwItems),

            // Post Type Filter
            Text(
              'Post Type',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: TSizes.sm),
            Obx(() => Wrap(
              spacing: TSizes.sm,
              runSpacing: TSizes.sm,
              children: controller.postTypeFilters.map((type) {
                final isSelected = controller.selectedPostType.value == type;
                return FilterChip(
                  label: Text(controller.getPostTypeLabel(type)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      controller.filterByPostType(type);
                    }
                  },
                  backgroundColor: darkMode
                      ? TColors.darkContainer
                      : TColors.lightContainer,
                  selectedColor: TColors.primary.withOpacity(0.2),
                  checkmarkColor: TColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? TColors.primary
                        : (darkMode ? TColors.white : TColors.black),
                    fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? TColors.primary
                        : (darkMode ? TColors.darkGrey : TColors.grey),
                  ),
                );
              }).toList(),
            )),

            SizedBox(height: TSizes.spaceBtwItems),

            // Status Filter
            Text(
              'Post Status',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: TSizes.sm),
            Obx(() => Wrap(
              spacing: TSizes.sm,
              runSpacing: TSizes.sm,
              children: controller.statusFilters.map((status) {
                final isSelected = controller.selectedStatus.value == status;
                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (status != 'all') ...[
                        Icon(
                          status == 'active'
                              ? Icons.check_circle
                              : Icons.block,
                          size: 16,
                          color: isSelected
                              ? TColors.primary
                              : (status == 'active'
                              ? TColors.success
                              : TColors.error),
                        ),
                        SizedBox(width: 4),
                      ],
                      Text(controller.getStatusLabel(status)),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      controller.filterByStatus(status);
                    }
                  },
                  backgroundColor: darkMode
                      ? TColors.darkContainer
                      : TColors.lightContainer,
                  selectedColor: TColors.primary.withOpacity(0.2),
                  checkmarkColor: TColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? TColors.primary
                        : (darkMode ? TColors.white : TColors.black),
                    fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? TColors.primary
                        : (darkMode ? TColors.darkGrey : TColors.grey),
                  ),
                );
              }).toList(),
            )),

            SizedBox(height: TSizes.spaceBtwSections),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      controller.resetFilters();
                      Get.back();
                    },
                    child: Text('Reset'),
                  ),
                ),
                SizedBox(width: TSizes.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    child: Text('Apply'),
                  ),
                ),
              ],
            ),

            SizedBox(height: TSizes.md),
          ],
        ),
      ),
    );
  }
}