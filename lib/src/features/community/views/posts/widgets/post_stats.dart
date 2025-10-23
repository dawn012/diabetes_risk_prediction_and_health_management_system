import 'package:flutter/material.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../models/post_model.dart';

class PostStats extends StatelessWidget {
  const PostStats({super.key, required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    final hasLikes = post.likes.isNotEmpty;
    final hasComments = post.commentCount > 0;

    if (!hasLikes && !hasComments) return const SizedBox.shrink();

    return Row(
      children: [
        // Likes
        if (hasLikes) ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: TColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.thumb_up,
                  color: Colors.white,
                  size: 12,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${post.likes.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? TColors.lightGrey : TColors.textSecondary,
                ),
              ),
            ],
          ),
        ],

        const Spacer(),

        // Comments
        if (hasComments)
          Text(
            '${post.commentCount} ${post.commentCount == 1 ? 'comment' : 'comments'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? TColors.lightGrey : TColors.textSecondary,
            ),
          ),
      ],
    );
  }
}