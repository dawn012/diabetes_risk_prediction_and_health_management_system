import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Character limits
  static const int maxCommentLength = 250;
  static const int maxReplyLength = 250;

  @override
  Widget build(BuildContext context) {
    final controller = CommentController.instance;
    final userController = UserController.instance;
    final isDark = THelperFunctions.isDarkMode(context);
    final maxLength = parentCommentId != null ? maxReplyLength : maxCommentLength;

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
          final currentLength = controller.commentText.text.length;
          final remaining = maxLength - currentLength;
          final isNearLimit = remaining <= 50;
          final isOverLimit = remaining < 0;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Character counter (show when near limit or editing)
              if (isNearLimit || isEditing)
                Padding(
                  padding: const EdgeInsets.only(bottom: TSizes.xs),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '$remaining',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverLimit
                              ? TColors.error
                              : (isNearLimit ? TColors.warning : TColors.textSecondary),
                          fontWeight: isOverLimit ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),

              // Input row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // User profile image
                  TCircularImage(
                    image: user.profileImg.isNotEmpty ? user.profileImg : TImages.user,
                    width: 32,
                    height: 32,
                    padding: 0,
                    backgroundColor: isDark ? TColors.darkGrey : TColors.lightGrey,
                    isNetworkImage: user.profileImg.isNotEmpty,
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
                          color: isOverLimit
                              ? TColors.error
                              : (isEditing
                              ? TColors.primary
                              : (isDark
                              ? TColors.borderPrimary.withOpacity(0.2)
                              : TColors.borderPrimary.withOpacity(0.4))),
                          width: isOverLimit ? 2 : (isEditing ? 2 : 1),
                        ),
                      ),
                      child: TextField(
                        controller: controller.commentText,
                        focusNode: controller.commentFocusNode,
                        maxLines: null,
                        minLines: 1,
                        maxLength: maxLength,
                        buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                          // Hide the default counter
                          return null;
                        },
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(maxLength),
                        ],
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
                  IconButton(
                    onPressed: (controller.isButtonEnabled.value && !isOverLimit)
                        ? () => controller.handleSubmit(parentCommentId: parentCommentId)
                        : null,
                    icon: Icon(
                      isEditing ? Icons.check : Icons.send,
                      color: (controller.isButtonEnabled.value && !isOverLimit)
                          ? TColors.primary
                          : (isDark ? TColors.darkGrey : TColors.grey),
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }
}