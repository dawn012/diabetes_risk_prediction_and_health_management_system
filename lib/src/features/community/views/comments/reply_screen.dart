import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/loaders/circular_loader.dart';
import '../../controllers/comment_controller.dart';
import '../../models/comment_model.dart';
import 'widgets/comment_text_field.dart';
import 'widgets/comment_tile.dart';

class ReplyScreen extends StatelessWidget {
  const ReplyScreen({super.key, required this.parentComment});

  final CommentModel parentComment;

  @override
  Widget build(BuildContext context) {
    final controller = CommentController.instance;

    // 进入页面时，自动 fetch replies
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchReplies(parentComment.commentId);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("Replies"),
      ),
      body: Column(
        children: [
          /// 原始评论（父级评论）
          CommentTile(comment: parentComment, showReplyCount: false),

          /// 分割线
          const Divider(),

          Expanded(
            child: Obx(() {
              // 监听加载状态
              if (controller.loadingReplies[parentComment.commentId] == true) {
                return const CircularLoader();
              }

              // 获取 Firestore 实时更新的数据
              final replies = controller.replies[parentComment.commentId];

              // 如果还未加载或没有回复
              if (replies == null || replies.isEmpty) {
                return const Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 50),
                    child: Text("No replies yet"),
                  ),
                );
              }

              return ListView.builder(
                itemCount: replies.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 50),
                    child: CommentTile(comment: replies[index], showReplyCount: false),
                  );
                },
              );
            }),
          ),

          /// 回复输入框
          CommentTextField(parentCommentId: parentComment.commentId),
        ],
      ),
    );
  }
}
