import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../../../../common/loaders/circular_loader.dart';
import '../../../controllers/video_controller.dart';

class VideoView extends StatelessWidget {
  const VideoView({super.key, this.video, this.videoUrl});

  final String? videoUrl;
  final File? video;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VideoController());

    // 选择初始化方式
    if (video != null) {
      controller.initializeVideo(video: video);
    } else if (videoUrl != null) {
      controller.initializeVideo(videoUrl: videoUrl);
    } else {
      return const Center(child: Text("No video source provided"));
    }

    return Obx(
          () => controller.isInitialized.value
          ? AspectRatio(
        aspectRatio: controller.videoPlayerController.value.aspectRatio,
        child: Stack(
          children: [
            VideoPlayer(controller.videoPlayerController),
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              right: 0,
              child: IconButton(
                onPressed: controller.togglePlayPause,
                icon: Icon(
                  controller.isPlaying.value
                      ? Icons.pause_circle
                      : Icons.play_circle,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      )
          : const CircularLoader(),
    );
  }
}
