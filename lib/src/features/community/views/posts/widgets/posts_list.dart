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
    final controller = Get.find<PostController>();
    final isDark = THelperFunctions.isDarkMode(context);

    return SliverToBoxAdapter(
      child: Obx(() {
        // 新帖子横幅
        final newPostsBanner = controller.hasNewPosts.value
            ? Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: TColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => controller.loadNewPosts(),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward,
                        color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${controller.newPostsCount.value} new post${controller.newPostsCount.value > 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close,
                          color: Colors.white, size: 20),
                      onPressed: () => controller.dismissNewPostsBanner(),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
            : SizedBox.shrink();

        // Loading
        if (controller.isLoadingPosts.value && controller.posts.isEmpty) {
          return Column(
            children: [
              newPostsBanner,
              CircularLoader(),
            ],
          );
        }

        // Error
        if (controller.postsError.isNotEmpty && controller.posts.isEmpty) {
          return Column(
            children: [
              newPostsBanner,
              ErrorRetryScreen(
                message: controller.postsError.value,
                onRetry: () => controller.refreshPosts(),
              ),
            ],
          );
        }

        // Empty
        if (controller.posts.isEmpty) {
          return Column(
            children: [
              newPostsBanner,
              Container(
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
                      style:
                      Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: isDark
                            ? TColors.lightGrey
                            : TColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Be the first to share something with the community!",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? TColors.darkGrey
                            : TColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        // Posts list
        return Column(
          children: [
            newPostsBanner,
            ...controller.posts.map((post) => Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: PostTile(post: post, isInMyPosts: false,),
            )),
            if (controller.isLoadingMore.value)
              Container(
                padding: const EdgeInsets.all(16),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        );
      }),
    );
  }
}