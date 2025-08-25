import 'package:diabetes_risk_prediction_and_health_management_system/src/features/community/views/comments/comments_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

import '../../../../../common/widgets/buttons/icon_text_button.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../personalization/controllers/user_controller.dart';
import '../../../controllers/post_controller.dart';
import '../../../models/post_model.dart';

class PostButtons extends StatelessWidget {
  const PostButtons({super.key, required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final controller = PostController.instance;
    final userController = Get.put(UserController());
    final isLiked = post.likes.contains(userController.user.value.userId);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        IconTextButton(
          icon: isLiked
              ? FontAwesomeIcons.solidThumbsUp
              : FontAwesomeIcons.thumbsUp,
          color: isLiked ? TColors.primary : TColors.black,
          label: TTexts.like,
          onPressed: () => controller.toggleLike(post.postId, post.likes),
        ),
        IconTextButton(
          icon: FontAwesomeIcons.solidMessage,
          label: TTexts.comment,
          onPressed: () {
            Get.to(() => CommentsScreen(postId: post.postId));
          },
        ),
        const IconTextButton(icon: FontAwesomeIcons.share, label: TTexts.share),
      ],
    );
  }
}
