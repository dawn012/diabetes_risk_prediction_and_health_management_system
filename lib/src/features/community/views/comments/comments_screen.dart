import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../controllers/comment_controller.dart';
import 'widgets/comment_text_field.dart';
import 'widgets/comments_list.dart';

class CommentsScreen extends StatelessWidget {
  const CommentsScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CommentController(postId: postId));

    return Scaffold(
      /// **自定义 AppBar（带黑色背景）**
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
              TAppBar(
                title: const Text("${TTexts.comment}s"),
                showBackArrow: true,
                actions: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.sort),
                    offset: const Offset(-15, 40), // 调整位置
                    onSelected: (String value) {
                      controller.sortCommentsBy(value);
                    },
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem(
                        value: 'top',
                        child: Container(
                          color: controller.currentSort.value == 'top' ? Colors.grey[800] : Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Top Comments',
                                  style: TextStyle(
                                    color: controller.currentSort.value == 'top' ? Colors.white : Colors.grey[300],
                                    fontWeight: controller.currentSort.value == 'top' ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (controller.currentSort.value == 'top')
                                const Icon(Icons.check, color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'newest',
                        child: Container(
                          color: controller.currentSort.value == 'newest' ? Colors.grey[800] : Colors.black,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Newest First',
                                  style: TextStyle(
                                    color: controller.currentSort.value == 'newest' ? Colors.white : Colors.grey[300],
                                    fontWeight: controller.currentSort.value == 'newest' ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (controller.currentSort.value == 'newest')
                                const Icon(Icons.check, color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ],
          );
        }),
      ),

      /// **主内容**
      body: Stack(
        children: [
          /// **评论列表**
          Column(
            children: [
              CommentsList(postId: postId),
            ],
          ),

          /// **黑色背景（覆盖 ListView）**
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

          /// **底部输入框**
          Align(
            alignment: Alignment.bottomCenter,
            child: CommentTextField(postId: postId),
          ),
        ],
      ),
    );

  }
}
