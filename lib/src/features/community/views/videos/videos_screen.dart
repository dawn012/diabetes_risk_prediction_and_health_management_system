import 'package:flutter/material.dart';

import 'widgets/videos_list.dart';

class VideosScreen extends StatelessWidget {
  const VideosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Displays list of videos
        VideosList(),
      ],
    );
  }
}
