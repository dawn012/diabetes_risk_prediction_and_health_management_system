import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../common/loaders/circular_loader.dart';
import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/search_bar/search_bar_widget.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/my_post_controller.dart';
import '../create_post/create_post_screen.dart';
import '../../../../common/widgets/filter_chip/filter_chips_widget.dart';
import '../posts/widgets/post_tile.dart';

class MyPostsScreen extends StatelessWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MyPostController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: darkMode ? TColors.dark : TColors.light,
      appBar: TAppBar(
        backgroundColor: darkMode ? TColors.darkContainer : TColors.white,
        showBackArrow: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'My Posts',
              style: TextStyle(
                color: darkMode ? TColors.white : TColors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Obx(() => Text(
              '${controller.myPosts.length} ${controller.myPosts.length == 1 ? 'Post' : 'Posts'}',
              style: TextStyle(
                color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                fontSize: 12,
              ),
            )),
          ],
        ),
        actions: [
          // Status filter button
          PopupMenuButton<String>(
            icon: Stack(
              children: [
                Icon(
                  Icons.filter_list,
                  color: darkMode ? TColors.white : TColors.black,
                ),
                Obx(() {
                  if (controller.selectedStatus.value != 'all') {
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
                            color: darkMode ? TColors.darkContainer : TColors.white,
                            width: 1,
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
            tooltip: 'Filter by Status',
            onSelected: controller.filterByStatus,
            itemBuilder: (context) => controller.statusFilters.map((status) {
              return PopupMenuItem<String>(
                value: status,
                child: Row(
                  children: [
                    if (status != 'all')
                      Icon(
                        status == 'active' ? Icons.check_circle : Icons.block,
                        size: 18,
                        color: status == 'active' ? TColors.success : TColors.error,
                      ),
                    if (status != 'all') const SizedBox(width: 8),
                    Text(controller.getStatusLabel(status)),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshPosts,
        color: TColors.primary,
        child: CustomScrollView(
          controller: controller.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Search Bar
            SliverToBoxAdapter(
              child: SearchBarWidget(
                controller: controller.searchController,
                onChanged: (value) {
                  controller.performSearch(value);
                },
                onClear: () {
                  controller.clearSearch();
                },
                hintText: 'Search your posts...',
              ),
            ),

            // Filter Chips with horizontal scroll
            SliverToBoxAdapter(
              child: FilterChipsWidget(
                filters: controller.postTypeFilters,
                selectedFilter: controller.selectedPostType,
                onFilterSelected: controller.filterByPostType,
                getFilterLabel: controller.getPostTypeLabel,
              ),
            ),

            // Content based on state
            Obx(() {
              // Show loading indicator when loading
              if (controller.isLoadingPosts.value && controller.myPosts.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: CircularLoader(message: 'Loading your posts...'),
                );
              }

              // Show empty state when no posts
              if (!controller.isLoadingPosts.value && controller.myPosts.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(context, darkMode, controller),
                );
              }

              // Show posts list
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    if (index == 0) {
                      return const SizedBox(height: 8);
                    }

                    final postIndex = (index - 1) ~/ 2;

                    if (index.isOdd) {
                      // Post item
                      if (postIndex >= controller.myPosts.length) {
                        // Loading more indicator
                        if (controller.isLoadingMore.value) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: TColors.primary,
                              ),
                            ),
                          );
                        }
                        return const SizedBox(height: 80);
                      }

                      final post = controller.myPosts[postIndex];
                      return PostTile(post: post, isInMyPosts: true);
                    } else {
                      // Separator
                      return const SizedBox(height: 8);
                    }
                  },
                  childCount: (controller.myPosts.length * 2) + 2 +
                      (controller.isLoadingMore.value ? 1 : 0),
                ),
              );
            }),
          ],
        ),
      ),

      // Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const CreatePostScreen()),
        backgroundColor: TColors.primary,
        icon: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        label: const Text(
          'Create Post',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 4,
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, bool darkMode, MyPostController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 80,
              color: darkMode ? TColors.darkGrey : TColors.grey,
            ),
            const SizedBox(height: TSizes.spaceBtwItems),
            Text(
              _getEmptyStateTitle(controller),
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TSizes.sm),
            Text(
              _getEmptyStateMessage(controller),
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TSizes.spaceBtwSections),
            if (controller.selectedPostType.value != 'all' ||
                controller.selectedStatus.value != 'all' ||
                controller.searchQuery.value.isNotEmpty)
              OutlinedButton.icon(
                onPressed: controller.resetFilters,
                icon: const Icon(Icons.refresh),
                label: const Text('Clear Filters'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TSizes.lg,
                    vertical: TSizes.md,
                  ),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () => Get.to(() => const CreatePostScreen()),
                icon: const Icon(Icons.add),
                label: const Text('Create Your First Post'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TSizes.lg,
                    vertical: TSizes.md,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getEmptyStateTitle(MyPostController controller) {
    if (controller.selectedPostType.value != 'all' ||
        controller.selectedStatus.value != 'all' ||
        controller.searchQuery.value.isNotEmpty) {
      return 'No Posts Found';
    }
    return 'No Posts Yet';
  }

  String _getEmptyStateMessage(MyPostController controller) {
    if (controller.selectedPostType.value != 'all' ||
        controller.selectedStatus.value != 'all' ||
        controller.searchQuery.value.isNotEmpty) {
      return 'Try adjusting your filters or search to see more posts';
    }
    return 'Start sharing your thoughts, tips, and stories with the community!';
  }
}