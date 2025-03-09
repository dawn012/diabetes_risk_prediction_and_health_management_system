import 'package:flutter/material.dart';

import 'round_like_icon.dart';

class PostStats extends StatelessWidget {
  const PostStats({super.key, required this.likes});

  final List<String> likes;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const RoundLikeIcon(),
        const SizedBox(width: 5),
        Text('${likes.length}'),
      ],
    );
  }
}
