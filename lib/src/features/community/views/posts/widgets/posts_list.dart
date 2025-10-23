import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../common/loaders/circular_loader.dart';
import '../../../../../common/widgets/error_screen/error_retry_screen.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/post_controller.dart';
import 'post_tile.dart';

class PostsList extends StatelessWidget {
  const PostsList({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PostController());
    final isDark = THelperFunctions.isDarkMode(context);

    return Obx(() {
      if (controller.isLoadingPosts.value && controller.posts.isEmpty) {
        return const SliverToBoxAdapter(child: CircularLoader());
      }

      if (controller.postsError.isNotEmpty && controller.posts.isEmpty) {
        return SliverToBoxAdapter(
          child: ErrorRetryScreen(
            message: controller.postsError.value,
            onRetry: () => controller.fetchPosts(refresh: true),
          ),
        );
      }

      if (controller.posts.isEmpty) {
        return SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.forum_outlined,
                  size: 64,
                  color: isDark ? TColors.darkGrey : TColors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  "No posts yet",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: isDark ? TColors.lightGrey : TColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Be the first to share something with the community!",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? TColors.darkGrey : TColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return SliverList.separated(
        itemCount: controller.posts.length + (controller.isLoadingMore.value ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          // Show loading indicator at the end
          if (index >= controller.posts.length) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          final post = controller.posts[index];
          return PostTile(post: post);
        },
      );
    });
  }
}