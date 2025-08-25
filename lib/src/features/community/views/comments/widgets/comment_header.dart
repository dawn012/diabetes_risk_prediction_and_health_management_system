import 'package:diabetes_risk_prediction_and_health_management_system/src/utils/extensions/date_time_extension.dart';
import 'package:diabetes_risk_prediction_and_health_management_system/src/utils/helpers/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../common/loaders/circular_loader.dart';
import '../../../../../common/widgets/bottom_sheets/comment_bottom_sheet.dart';
import '../../../../../common/widgets/images/t_circular_image.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/image_strings.dart';
import '../../../../authentication/models/user_model.dart';
import '../../../../personalization/controllers/user_controller.dart';
import '../../../controllers/comment_controller.dart';
import '../../../models/comment_model.dart';

class CommentHeader extends StatelessWidget {
  const CommentHeader({super.key, required this.comment, required this.isComment});

  final CommentModel comment;
  final bool isComment;

  @override
  Widget build(BuildContext context) {
    final userController = UserController.instance;

    return Obx(() {
      // 1️⃣ 如果缓存里有用户数据，直接用
      if (userController.userCache.containsKey(comment.authorId)) {
        final user = userController.userCache[comment.authorId]!;
        return _buildUserComment(user);
      } else {
        // 2️⃣ 如果没有，就 fetch
        return FutureBuilder<UserModel>(
          future: userController.fetchUserRecordById(comment.authorId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularLoader(); // 只在首次加载时显示
            }

            if (snapshot.hasError || snapshot.data == null) {
              return const Text("Error loading user info");
            }

            return _buildUserComment(snapshot.data!);
          },
        );
      }
    });
  }

  Widget _buildUserComment(UserModel user) {
    final context = Get.context!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 10),

        /// 用户头像
        TCircularImage(
          image: user.profileImg.isNotEmpty
              ? user.profileImg
              : TImages.user,
          padding: 0,
          width: 35,
          height: 35,
        ),
        const SizedBox(width: 18),

        /// 用户名 + 评论 + 选项菜单
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          user.username.isNotEmpty ? user.username : "Anonymous",
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium,
                        ),
                        const SizedBox(width: 6),
                        const Text("·", style: TextStyle(color: Colors.grey)),
                        const SizedBox(width: 6),
                        Text(
                          comment.createdAt.fromNow(),
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium,
                        ),
                      ],
                    ),
                  ),

                  /// **三点菜单按钮**
                  SizedBox(
                    height: 20,  // 限制高度，防止撑开 Row
                    child: IconButton(
                      padding: EdgeInsets.zero,  // 移除额外的 padding
                      icon: const Icon(Icons.more_vert, size: 20),
                      onPressed: () {
                        _showCommentOptions();
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              /// 评论文本
              Text(
                comment.text,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        )
      ],
    );
  }

  /// 显示 Comment 选项 Bottom Sheet
  void _showCommentOptions() {
    final context = Get.context!;
    final dark = THelperFunctions.isDarkMode(context);
    final commentController = CommentController.instance;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return CommentBottomSheet(
          title: "Comment",
          options: [
            if (commentController.isOwner(comment.authorId)) ...[  // 只有是作者，才显示 Edit 和 Delete
              BottomSheetOption(
                text: "Edit",
                icon: Icons.edit_outlined,
                iconColor: dark ? TColors.white : TColors.black,
                onTap: () => commentController.editComment(comment),
              ),
              BottomSheetOption(
                text: "Delete",
                icon: Icons.delete_outline_outlined,
                iconColor: dark ? TColors.white : TColors.black,
                onTap: () => commentController.deleteCommentWarningPopup(comment, isComment),
              ),
            ],
          ],
        );
      },
    );
  }
}
