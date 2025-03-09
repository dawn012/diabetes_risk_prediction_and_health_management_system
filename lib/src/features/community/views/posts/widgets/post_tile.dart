import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../controllers/post_controller.dart';
import 'post_buttons.dart';
import 'post_image_video_view.dart';
import 'post_info_tile.dart';
import 'post_stats.dart';

class PostTile extends StatelessWidget {
  const PostTile({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    final controller = PostController.instance;
    final post = controller.posts.firstWhereOrNull(
        (p) => p.postId == postId); // 查找第一个符合条件的元素，如果找不到，返回 null

    if (post == null) {
      return const SizedBox.shrink(); // 什么都不显示
    }

    return Container(
      color: TColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Post Header
          PostInfoTile(datePublished: post.createdAt, userId: post.posterId),

          /// Post Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Text(post.content),
          ),

          /// Post Image / Video
          PostImageVideoView(
            fileUrl: post.fileUrl,
            fileType: post.postType,
          ),

          /// Post Stats and Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            child: Column(
              children: [
                PostStats(
                  likes: post.likes,
                ),
                const Divider(),

                /// Post Buttons
                PostButtons(post: post),
              ],
            ),
          )
        ],
      ),
    );
  }
}
