import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../personalization/controllers/user_controller.dart';
import '../../../controllers/comment_controller.dart';
import '../../../models/comment_model.dart';

class CommentFooter extends StatelessWidget {
  const CommentFooter({super.key, required this.comment});

  final CommentModel comment;

  @override
  @override
  Widget build(BuildContext context) {
    final controller = CommentController.instance;
    final isLiked = comment.likes.contains(UserController.instance.user.value.uid);

    return Row(
      children: [
        const SizedBox(width: 50),

        /// Like Button
        IconButton(
          onPressed: () => controller.toggleLike(
              comment.commentId, comment.likes, comment.parentCommentId),
          icon: Icon(
            isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
            color: isLiked ? TColors.primary : TColors.darkGrey,
            size: 20,
          ),
        ),

        /// Like Count
        Text(
          comment.likes.length.toString(),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(width: TSizes.spaceBtwSections),

        /// Reply Button
        IconButton(
          onPressed: () {
            // 这里可以添加点击回复的逻辑
          },
          icon: FaIcon(
            FontAwesomeIcons.reply,
            color: TColors.darkGrey,
            size: 18,
          ),
        ),
      ],
    );
  }
}
