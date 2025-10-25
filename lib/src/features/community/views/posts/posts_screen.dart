import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../utils/constants/colors.dart';
import '../../controllers/post_controller.dart';
import 'widgets/make_post.dart';
import 'widgets/posts_list.dart';

class PostsScreen extends StatelessWidget {
  const PostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PostController());

    return Scaffold(
      body: RefreshIndicator(
        color: TColors.primary,
        onRefresh: () async {
          // 触发下拉刷新
          await controller.refreshPosts();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const FeedMakePostWidget(),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            const PostsList(),
          ],
        ),
      ),
    );
  }
}