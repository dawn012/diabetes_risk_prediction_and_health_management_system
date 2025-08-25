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
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Obx(() {
          bool isEditing = controller.editingCommentId.value != null;
          return Stack(
            children: [
              /// **黑色背景**
              if (isEditing)
                Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  height: kToolbarHeight + MediaQuery.of(context).padding.top,
                ),

              /// **原本的 AppBar**
              AppBar(
                title: const Text("Replies"),
              ),
            ],
          );
        }),
      ),

      body: Stack(
        children: [
          /// 主内容（包含 AppBar、评论列表）
          Column(
            children: [
              /// 原始评论（父级评论）
              CommentTile(comment: parentComment, isComment: false),

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
                        child: CommentTile(comment: replies[index], isComment: false),
                      );
                    },
                  );
                }),
              ),
            ],
          ),

          /// 黑色半透明背景（仅在编辑模式下显示，且不会遮住 TextField）
          Obx(() {
            bool isEditing = controller.editingCommentId.value != null;
            return isEditing
                ? Positioned.fill(
              child: GestureDetector(
                onTap: () async {
                  await controller.cancelEdit();
                },
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5), // ✅ 透明黑色背景
                ),
              ),
            )
                : const SizedBox();
          }),

          /// 底部 TextField（不被黑色背景遮挡）
          Align(
            alignment: Alignment.bottomCenter,
            child: CommentTextField(parentCommentId: parentComment.commentId),
          ),
        ],
      ),
    );
  }
}
