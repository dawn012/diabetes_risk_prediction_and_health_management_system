import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../models/post_media_item.dart';
import '../../../utils/constants/colors.dart';
import '../../../common/loaders/loaders.dart';

class MediaPreviewController extends GetxController {
  final int initialIndex;
  final Function(String) onDeleteMedia;

  MediaPreviewController({
    required List<PostMediaItem> mediaItems,
    required this.initialIndex,
    required this.onDeleteMedia,
  }) {
    this.mediaItems.value = List.from(mediaItems);
  }

  late PageController pageController;
  final currentIndex = 0.obs;
  final mediaItems = <PostMediaItem>[].obs;
  VideoPlayerController? videoController;
  final isVideoInitialized = false.obs;
  final isVideoPlaying = false.obs;
  final showControls = true.obs;

  @override
  void onInit() {
    super.onInit();
    currentIndex.value = initialIndex;
    pageController = PageController(initialPage: initialIndex);
    _initializeCurrentMedia();
  }

  @override
  void onClose() {
    pageController.dispose();
    videoController?.dispose();
    // 恢复系统UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.onClose();
  }

  void _initializeCurrentMedia() {
    if (mediaItems.isEmpty || currentIndex.value >= mediaItems.length) {
      return;
    }

    final currentMedia = mediaItems[currentIndex.value];

    // Dispose previous video controller
    videoController?.dispose();
    videoController = null;
    isVideoInitialized.value = false;
    isVideoPlaying.value = false;

    if (currentMedia.isVideo) {
      _initializeVideo(currentMedia);
    }
  }

  void _initializeVideo(PostMediaItem mediaItem) {
    try {
      if (mediaItem.isExisting && mediaItem.existingUrl != null) {
        // 网络视频
        videoController = VideoPlayerController.network(mediaItem.existingUrl!);
      } else if (mediaItem.file != null && mediaItem.file!.existsSync()) {
        // 本地视频
        videoController = VideoPlayerController.file(mediaItem.file!);
      } else {
        throw Exception('No valid video source');
      }

      videoController!.initialize().then((_) {
        isVideoInitialized.value = true;
        // Auto-hide controls after 3 seconds
        _autoHideControls();
      }).catchError((error) {
        print('Video initialization error: $error');
        isVideoInitialized.value = false;
        TLoaders.errorSnackBar(
          title: 'Video Error',
          message: 'Failed to load video',
        );
      });

      // Listen to video state changes
      videoController!.addListener(() {
        if (videoController != null) {
          isVideoPlaying.value = videoController!.value.isPlaying;
        }
      });
    } catch (e) {
      print('Error initializing video: $e');
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to initialize video player',
      );
    }
  }

  void onPageChanged(int index) {
    if (index >= 0 && index < mediaItems.length) {
      currentIndex.value = index;
      _initializeCurrentMedia();
    }
  }

  void deleteCurrentMedia() {
    if (mediaItems.isEmpty) return;

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: TColors.error),
            SizedBox(width: 8),
            Text('Delete Media'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete this ${mediaItems[currentIndex.value].type}?'),
            SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _performDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TColors.error,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 0)
            ),
            child: Text('Delete', style: TextStyle(fontSize: 14),),
          ),
        ],
      ),
    );
  }

  void _performDelete() {
    if (mediaItems.isEmpty) return;

    final currentIdx = currentIndex.value;
    final mediaId = mediaItems[currentIdx].id;

    // Determine navigation direction before deletion
    bool shouldNavigateNext = currentIdx < mediaItems.length - 1;

    // Animate to next/previous page first to show deletion effect
    if (mediaItems.length > 1) {
      if (shouldNavigateNext) {
        // Navigate to next item with animation
        pageController.nextPage(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ).then((_) {
          // After animation completes, perform deletion
          _completeDelete(mediaId, currentIdx);
        });
      } else {
        // Navigate to previous item with animation
        pageController.previousPage(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ).then((_) {
          // After animation completes, perform deletion
          _completeDelete(mediaId, currentIdx);
        });
      }
    } else {
      // Only one item, delete immediately and close
      _completeDelete(mediaId, currentIdx);
    }
  }

  void _completeDelete(String mediaId, int deletedIndex) {
    // Call the parent delete callback
    onDeleteMedia(mediaId);

    // Remove from local observable list
    mediaItems.removeAt(deletedIndex);

    // Handle post-deletion state
    if (mediaItems.isEmpty) {
      // No more items, close the preview
      Get.back();
      return;
    }

    // Adjust current index if needed
    if (deletedIndex < currentIndex.value) {
      // Deleted item was before current, decrement index
      currentIndex.value = currentIndex.value - 1;
    } else if (currentIndex.value >= mediaItems.length) {
      // Current index out of bounds, set to last item
      currentIndex.value = mediaItems.length - 1;
    }

    // Initialize the new current media
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCurrentMedia();
    });
  }

  void toggleVideoPlayback() {
    if (videoController != null && isVideoInitialized.value) {
      if (videoController!.value.isPlaying) {
        videoController!.pause();
      } else {
        videoController!.play();
      }
      _showControlsTemporarily();
    }
  }

  void _showControlsTemporarily() {
    showControls.value = true;
    _autoHideControls();
  }

  void _autoHideControls() {
    Future.delayed(Duration(seconds: 3), () {
      if (videoController != null && videoController!.value.isPlaying) {
        showControls.value = false;
      }
    });
  }

  void toggleControlsVisibility() {
    showControls.value = !showControls.value;
    if (showControls.value) {
      _autoHideControls();
    }
  }

  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    if (minutes > 0) {
      return '${minutes}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${seconds}s';
  }

  String get currentMediaInfo {
    if (mediaItems.isEmpty || currentIndex.value >= mediaItems.length) {
      return '';
    }

    final media = mediaItems[currentIndex.value];
    final typeText = media.isImage ? 'Image' : 'Video';
    final sizeText = media.formattedFileSize;
    final sourceText = media.isExisting ? 'Network' : 'Local';

    if (media.isVideo && media.duration != null) {
      return '$typeText • ${media.formattedDuration} • $sizeText • $sourceText';
    }

    return '$typeText • $sizeText • $sourceText';
  }

  bool get canNavigatePrevious => currentIndex.value > 0;
  bool get canNavigateNext => currentIndex.value < mediaItems.length - 1;

  void navigatePrevious() {
    if (canNavigatePrevious) {
      pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void navigateNext() {
    if (canNavigateNext) {
      pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}