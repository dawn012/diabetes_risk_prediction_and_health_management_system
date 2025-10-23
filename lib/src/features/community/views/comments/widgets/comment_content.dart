import 'package:flutter/material.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../models/comment_model.dart';

class CommentContent extends StatelessWidget {
  const CommentContent({super.key, required this.comment});

  final CommentModel comment;

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);

    return Padding(
      padding: const EdgeInsets.only(left: 44), // Align with username
      child: Text(
        comment.content,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isDark ? TColors.lightGrey : TColors.textPrimary,
          height: 1.4,
        ),
      ),
    );
  }
}