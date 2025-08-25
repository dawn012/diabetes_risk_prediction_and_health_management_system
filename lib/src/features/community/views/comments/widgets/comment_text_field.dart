import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../common/widgets/images/t_circular_image.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/image_strings.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../../personalization/controllers/user_controller.dart';
import '../../../controllers/comment_controller.dart';

class CommentTextField extends StatelessWidget {
  const CommentTextField({super.key, this.postId, this.parentCommentId});

  final String? postId;  // comment
  final String? parentCommentId;  // reply

  @override
  Widget build(BuildContext context) {
    final controller = CommentController.instance;
    final user = UserController.instance.user.value;
    final dark = THelperFunctions.isDarkMode(context);
    final FocusNode commentNode = FocusNode();

    return PopScope(
      canPop: false, // 控制是否允许返回
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // 已经返回，直接跳过

        controller.handleCommentNavigation(() => Get.back());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        color: TColors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 10),

            /// User Profile Image
            TCircularImage(
              image: user.profileImg.isNotEmpty
                  ? user.profileImg
                  : TImages.user,
              padding: 0,
              width: 35,
              height: 35,
            ),
            const SizedBox(width: 15),

            /// 输入框
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: TColors.softGrey,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: TextField(
                  controller: controller.commentText,
                  focusNode: controller.commentFocusNode,
                  enabled: true,
                  decoration: InputDecoration(
                    hintText: TTexts.writeComment,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onSubmitted: (_) => controller.handleCommentSubmit(postId, parentCommentId),
                ),
              ),
            ),
            const SizedBox(width: 6),

            /// 发送按钮
            Obx(() => IconButton(
              onPressed: controller.isButtonEnabled.value
                  ? () => controller.handleCommentSubmit(postId, parentCommentId)
                  : null, // 按钮禁用
              icon: const Icon(Icons.send),
              color: controller.isButtonEnabled.value
                  ? (dark ? TColors.white : TColors.black) // 启用时正常颜色
                  : Colors.grey, // 禁用时灰色
            )),
          ],
        ),
      ),
    );
  }
}
