import 'package:flutter/material.dart';
import 'widgets/make_post.dart';
import 'widgets/posts_list.dart';

class PostsScreen extends StatelessWidget {
  const PostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      slivers: [
        FeedMakePostWidget(),
        SliverToBoxAdapter(child: SizedBox(height: 8)),
        PostsList(),
      ],
    );
  }
}