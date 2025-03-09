import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../controllers/comment_controller.dart';
import '../../../models/comment_model.dart';
import '../reply_screen.dart';
import 'comment_footer.dart';
import 'comment_header.dart';

class CommentTile extends StatelessWidget {
  const CommentTile({super.key, required this.comment, this.showReplyCount = true});

  final CommentModel comment;
  final bool showReplyCount;

  @override
  Widget build(BuildContext context) {
    final controller = CommentController.instance;
    final replyCount = comment.replyCount;

    return GestureDetector(
      onTap: () => controller.handleCommentNavigation(() => Get.to(() => ReplyScreen(parentComment: comment))),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Comment Header
            CommentHeader(
              comment: comment,
            ),
      
            const SizedBox(height: TSizes.spaceBtwItems),
      
            /// Comment Footer
            CommentFooter(
              comment: comment,
            ),

            /// Show Reply Count (if any)
            if (showReplyCount && replyCount > 0) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 63),
                child: GestureDetector(
                  onTap: () => controller.handleCommentNavigation(() => Get.to(() => ReplyScreen(parentComment: comment))),
                  child: Text(
                    "$replyCount ${replyCount == 1 ? "reply" : "replies"} >",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: TColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
