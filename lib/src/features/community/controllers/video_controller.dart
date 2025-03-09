import 'dart:io';

import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class VideoController extends GetxController {
  late VideoPlayerController videoPlayerController;  // 用于控制视频播放
  final isPlaying = false.obs;
  final isInitialized = false.obs;  // 表示视频是否初始化完成

  // void initializeVideo(File video) {
  //   videoPlayerController = VideoPlayerController.file(video)
  //       ..initialize().then((_) {  // 初始化播放器
  //         isInitialized.value = true;  // 初始化完成后，将 isInitialized.value 设为 true，通知 UI 组件可以开始播放
  //       });
  // }

  void initializeVideo({File? video, String? videoUrl}) {
    if (video != null) {
      // 本地文件
      videoPlayerController = VideoPlayerController.file(video);
    } else if (videoUrl != null) {
      // 网络 URL
      videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    } else {
      return;
    }

    // 初始化
    videoPlayerController.initialize().then((_) {
      isInitialized.value = true;  // 初始化完成后，将 isInitialized.value 设为 true，通知 UI 组件可以开始播放
    });
  }

  void togglePlayPause() {
    if (isPlaying.value) {
      videoPlayerController.pause();
    } else {
      videoPlayerController.play();
    }
    isPlaying.toggle();
  }

  // @override
  // void onInit() {
  //   if (videoFile.value != null) {
  //     initializeVideo(videoFile.value!);
  //   }
  //   super.onInit();
  // }

  @override
  void onClose() {
    videoPlayerController.dispose();
    super.onClose();
  }
}