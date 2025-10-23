import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../common/widgets/images/t_circular_image.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/image_strings.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../../personalization/controllers/user_controller.dart';
import '../../../controllers/comment_controller.dart';

class CommentTextField extends StatelessWidget {
  const CommentTextField({super.key, this.parentCommentId});

  final String? parentCommentId;

  @override
  Widget build(BuildContext context) {
    final controller = CommentController.instance;
    final userController = UserController.instance;
    final isDark = THelperFunctions.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkContainer : TColors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? TColors.borderPrimary.withOpacity(0.1)
                : TColors.borderPrimary.withOpacity(0.3),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Obx(() {
          final user = userController.user.value;
          final isEditing = controller.isEditing;
          final submitText = controller.submitButtonText;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // User profile image
              TCircularImage(
                image: user.profileImg.isNotEmpty ? user.profileImg : TImages.user,
                width: 32,
                height: 32,
                padding: 0,
                backgroundColor: isDark ? TColors.darkGrey : TColors.lightGrey,
              ),
              const SizedBox(width: TSizes.sm),

              // Text input field
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 100),
                  decoration: BoxDecoration(
                    color: isDark ? TColors.darkGrey.withOpacity(0.3) : TColors.lightGrey,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isEditing
                          ? TColors.primary
                          : (isDark
                          ? TColors.borderPrimary.withOpacity(0.2)
                          : TColors.borderPrimary.withOpacity(0.4)),
                      width: isEditing ? 2 : 1,
                    ),
                  ),
                  child: TextField(
                    controller: controller.commentText,
                    focusNode: controller.commentFocusNode,
                    maxLines: null,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: parentCommentId != null ? 'Write a reply...' : TTexts.writeComment,
                      hintStyle: TextStyle(
                        color: isDark ? TColors.darkGrey : TColors.textSecondary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: TextStyle(
                      color: isDark ? TColors.lightGrey : TColors.textPrimary,
                    ),
                    onSubmitted: (_) => controller.handleSubmit(parentCommentId: parentCommentId),
                  ),
                ),
              ),

              const SizedBox(width: TSizes.xs),

              // Submit/Cancel buttons
              if (isEditing) ...[
                // Cancel button
                IconButton(
                  onPressed: controller.cancelEdit,
                  icon: Icon(
                    Icons.close,
                    color: isDark ? TColors.darkGrey : TColors.textSecondary,
                  ),
                ),
                const SizedBox(width: TSizes.xs),
              ],

              // Submit button
              Obx(() => IconButton(
                onPressed: controller.isButtonEnabled.value
                    ? () => controller.handleSubmit(parentCommentId: parentCommentId)
                    : null,
                icon: Icon(
                  isEditing ? Icons.check : Icons.send,
                  color: controller.isButtonEnabled.value
                      ? TColors.primary
                      : (isDark ? TColors.darkGrey : TColors.grey),
                ),
              )),
            ],
          );
        }),
      ),
    );
  }
}