import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../common/loaders/circular_loader.dart';
import '../../../../../common/widgets/error_screen/error_retry_screen.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../controllers/comment_controller.dart';
import 'comment_tile.dart';

class CommentsList extends StatelessWidget {
  const CommentsList({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    final controller = CommentController.instance;

    return Expanded(
      child: Obx(() {
        if (controller.isFetching.value) {
          return const Center(child: CircularLoader());

        } else if (controller.errorMessage.isNotEmpty) {
          return SliverToBoxAdapter(
            child: ErrorRetryScreen(
                message: controller.errorMessage.value,
                onRetry: controller.fetchComments),
          );

        } else if (controller.comments.isEmpty) {
          return const Align(
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 50),
                child: Text("No comments available"),
              ),
            );

        } else {
          return ListView.builder(
            itemCount: controller.comments.length,
            itemBuilder: (context, index) {
              final comment = controller.comments[index];
              return Column(
                children: [
                  CommentTile(comment: comment),
                  const SizedBox(height: TSizes.spaceBtwItems),
                ],
              );
            },
          );
        }
      }),
    );
  }
}
