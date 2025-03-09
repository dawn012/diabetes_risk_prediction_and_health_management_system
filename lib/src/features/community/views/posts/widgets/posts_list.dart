import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../common/loaders/circular_loader.dart';
import '../../../../../common/widgets/error_screen/error_retry_screen.dart';
import '../../../controllers/post_controller.dart';
import 'post_tile.dart';

class PostsList extends StatelessWidget {
  const PostsList({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PostController());

    return Obx(() {
      if (controller.isFetching.value) {
        return const SliverToBoxAdapter(child: CircularLoader());

      } else if (controller.errorMessage.isNotEmpty) {
        return SliverToBoxAdapter(
          child: ErrorRetryScreen(message: controller.errorMessage.value, onRetry: controller.fetchPosts),
        );

      } else if (controller.posts.isEmpty) {
        return const SliverToBoxAdapter(
          child: Align(
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 50),
              child: Text("No posts available"),
            ),
          ),
        );

      } else {
        return SliverList.separated(
          itemCount: controller.posts.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final postId = controller.posts[index].postId; // 只传 postId
            return PostTile(postId: postId);
          },
        );
      }
    });
  }
}
