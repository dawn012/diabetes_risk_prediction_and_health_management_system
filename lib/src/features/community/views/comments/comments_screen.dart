import 'package:flutter/material.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/constants/text_strings.dart';
import 'widgets/comment_text_field.dart';
import 'widgets/comments_list.dart';

class CommentsScreen extends StatelessWidget {
  const CommentsScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TAppBar(
        title: const Text("${TTexts.comment}s"),
        showBackArrow: true,
      ),
      body: Column(
        children: [
          /// Comments List
          CommentsList(postId: postId),

          /// Comments Text Field
          CommentTextField(postId: postId),
        ],
      ),
    );
  }
}
