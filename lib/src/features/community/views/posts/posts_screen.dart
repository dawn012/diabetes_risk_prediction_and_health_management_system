import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/search_bar/search_bar_widget.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/post_controller.dart';
import '../create_post/create_post_screen.dart';
import '../../../../common/widgets/filter_chip/filter_chips_widget.dart';
import 'widgets/posts_list.dart';

class PostsScreen extends StatelessWidget {
  const PostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PostController>();
    final isDark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : TColors.light,
      body: RefreshIndicator(
        color: TColors.primary,
        onRefresh: () async {
          await controller.refreshPosts();
        },
        child: CustomScrollView(
          controller: controller.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Search Bar
            SliverToBoxAdapter(
              child: Obx(() => SearchBarWidget(
                controller: controller.searchController,
                onChanged: (value) {
                  controller.performSearch(value);
                },
                onClear: () {
                  controller.clearSearch();
                },
                hintText: 'Search posts or users...',
                hasText: controller.searchQuery.isNotEmpty,
              )),
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

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Posts List
            const PostsList(),
          ],
        ),
      ),

      // Floating Action Button for Create Post
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
}