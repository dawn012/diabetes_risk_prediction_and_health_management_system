import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../controllers/media_preview_controller.dart';
import '../../../models/post_media_item.dart';

class MediaPreviewScreen extends StatelessWidget {
  final List<PostMediaItem> mediaItems;
  final int initialIndex;
  final Function(String) onDeleteMedia;

  const MediaPreviewScreen({
    super.key,
    required this.mediaItems,
    required this.initialIndex,
    required this.onDeleteMedia,
  });

  @override
  Widget build(BuildContext context) {
    // Set full screen mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    final controller = Get.put(MediaPreviewController(
      mediaItems: mediaItems,
      initialIndex: initialIndex,
      onDeleteMedia: onDeleteMedia,
    ), tag: 'media_preview_${DateTime.now().millisecondsSinceEpoch}');

    return WillPopScope(
      onWillPop: () async {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Obx(() {
          // Watch for media items changes
          final items = controller.mediaItems;

          return Stack(
            children: [
              // Main media viewer
              _buildMediaViewer(controller, items),

              // Top app bar
              _buildTopAppBar(controller, items),

              // Bottom info panel
              _buildBottomInfoPanel(controller, items),

              // Navigation arrows (for web/desktop)
              if (items.length > 1) ...[
                _buildNavigationArrow(controller, isLeft: true),
                _buildNavigationArrow(controller, isLeft: false),
              ],
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMediaViewer(MediaPreviewController controller, List<PostMediaItem> items) {
    if (items.isEmpty) {
      return SizedBox.shrink();
    }

    return GestureDetector(
      onTap: controller.toggleControlsVisibility,
      child: PageView.builder(
        controller: controller.pageController,
        onPageChanged: controller.onPageChanged,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final mediaItem = items[index];

          if (mediaItem.isImage) {
            return _buildImageViewer(mediaItem);
          } else if (mediaItem.isVideo) {
            return _buildVideoViewer(controller, mediaItem, index);
          }

          return _buildErrorView();
        },
      ),
    );
  }

  Widget _buildImageViewer(PostMediaItem mediaItem) {
    return Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Hero(
          tag: 'media_${mediaItem.id}',
          child: mediaItem.isExisting && mediaItem.existingUrl != null
              ? _buildNetworkImage(mediaItem) // 网络图片
              : _buildLocalImage(mediaItem),  // 本地图片
        ),
      ),
    );
  }

  Widget _buildNetworkImage(PostMediaItem mediaItem) {
    return Image.network(
      mediaItem.existingUrl!,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
            color: TColors.primary,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _buildErrorView(),
    );
  }

  Widget _buildLocalImage(PostMediaItem mediaItem) {
    if (mediaItem.file == null || !mediaItem.file!.existsSync()) {
      return _buildErrorView();
    }

    return Image.file(
      mediaItem.file!,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => _buildErrorView(),
    );
  }

  Widget _buildVideoViewer(MediaPreviewController controller, PostMediaItem mediaItem, int index) {
    return Obx(() {
      // Only observe if this is the current video
      if (controller.currentIndex.value != index) {
        return Container(
          color: Colors.black,
          child: Center(
            child: Icon(
              Icons.play_circle_outline,
              color: Colors.white54,
              size: 64,
            ),
          ),
        );
      }

      // 检查视频控制器是否初始化
      final isInitialized = controller.isVideoInitialized.value;
      final videoController = controller.videoController;

      if (videoController == null || !isInitialized) {
        return _buildVideoLoadingView();
      }

      return Center(
        child: AspectRatio(
          aspectRatio: videoController.value.aspectRatio,
          child: Stack(
            children: [
              // Video player
              VideoPlayer(videoController),

              // Controls
              _buildVideoControls(controller, videoController),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildVideoLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: TColors.primary,
            strokeWidth: 3,
          ),
          SizedBox(height: TSizes.md),
          Text(
            'Loading video...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoControls(MediaPreviewController controller, VideoPlayerController videoController) {
    return Obx(() => GestureDetector(
      onTap: controller.toggleControlsVisibility,
      child: AnimatedOpacity(
        opacity: controller.showControls.value ? 1.0 : 0.0,
        duration: Duration(milliseconds: 300),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Play/Pause button (center)
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: controller.toggleVideoPlayback,
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        controller.isVideoPlaying.value ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 56,
                      ),
                    ),
                  ),
                ),
              ),

              // Progress bar
              _buildVideoProgressBar(controller, videoController),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildVideoProgressBar(MediaPreviewController controller, VideoPlayerController videoController) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Slider
          VideoProgressIndicator(
            videoController,
            allowScrubbing: true,
            colors: VideoProgressColors(
              playedColor: TColors.primary,
              bufferedColor: Colors.white.withOpacity(0.3),
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
            padding: EdgeInsets.symmetric(vertical: 8),
          ),

          // Time display
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(videoController.value.position),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDuration(videoController.value.duration),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  Widget _buildTopAppBar(MediaPreviewController controller, List<PostMediaItem> items) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Obx(() => AnimatedOpacity(
        opacity: controller.showControls.value ? 1.0 : 0.0,
        duration: Duration(milliseconds: 300),
        child: SafeArea(
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black54,
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              children: [
                // Close button
                IconButton(
                  onPressed: () {
                    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                    Get.back();
                  },
                  icon: Icon(Icons.close, color: Colors.white, size: 24),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black26,
                    minimumSize: Size(44, 44),
                  ),
                ),

                Spacer(),

                // Media counter
                if (items.length > 1)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${controller.currentIndex.value + 1} / ${items.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),

                Spacer(),

                // Delete button
                IconButton(
                  onPressed: controller.deleteCurrentMedia,
                  icon: Icon(Icons.delete_outline, color: Colors.white, size: 24),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black26,
                    minimumSize: Size(44, 44),
                  ),
                ),
              ],
            ),
          ),
        ),
      )),
    );
  }

  Widget _buildBottomInfoPanel(MediaPreviewController controller, List<PostMediaItem> items) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Obx(() => AnimatedOpacity(
        opacity: controller.showControls.value ? 1.0 : 0.0,
        duration: Duration(milliseconds: 300),
        child: SafeArea(
          child: Container(
            padding: EdgeInsets.all(TSizes.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black54,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Media info
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(TSizes.md),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildMediaInfo(controller, items),
                ),

                // Swipe hint (only show for first few seconds)
                if (items.length > 1)
                  Padding(
                    padding: EdgeInsets.only(top: TSizes.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.swipe_left,
                          color: Colors.white70,
                          size: 16,
                        ),
                        SizedBox(width: TSizes.xs),
                        Text(
                          'Swipe to navigate',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(width: TSizes.xs),
                        Icon(
                          Icons.swipe_right,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      )),
    );
  }

  Widget _buildMediaInfo(MediaPreviewController controller, List<PostMediaItem> items) {
    final currentIdx = controller.currentIndex.value;

    if (items.isEmpty || currentIdx >= items.length) {
      return SizedBox.shrink();
    }

    final currentMedia = items[currentIdx];

    String mediaSource = 'Local';
    if (currentMedia.isExisting && currentMedia.existingUrl != null) {
      mediaSource = 'Network';
    }

    return Row(
      children: [
        // Media type icon
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: TColors.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            currentMedia.isImage ? Icons.image : Icons.videocam,
            color: TColors.primary,
            size: 20,
          ),
        ),

        SizedBox(width: TSizes.md),

        // Media details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${currentMedia.isImage ? 'Image' : 'Video'} • $mediaSource',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 2),
              Text(
                controller.currentMediaInfo,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // Processing indicator
        if (currentMedia.isProcessing)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: TColors.warning,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  'Processing...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        // Error indicator
        if (currentMedia.hasError)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: TColors.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 12),
                SizedBox(width: 4),
                Text(
                  'Error',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNavigationArrow(MediaPreviewController controller, {required bool isLeft}) {
    return Positioned(
      left: isLeft ? 20 : null,
      right: isLeft ? null : 20,
      top: 0,
      bottom: 0,
      child: Obx(() => AnimatedOpacity(
        opacity: controller.showControls.value ? 1.0 : 0.0,
        duration: Duration(milliseconds: 300),
        child: Center(
          child: IconButton(
            onPressed: isLeft
                ? (controller.canNavigatePrevious ? controller.navigatePrevious : null)
                : (controller.canNavigateNext ? controller.navigateNext : null),
            icon: Icon(
              isLeft ? Icons.chevron_left : Icons.chevron_right,
              color: Colors.white,
              size: 32,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black26,
              minimumSize: Size(48, 48),
            ),
          ),
        ),
      )),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.white70,
            size: 48,
          ),
          SizedBox(height: TSizes.md),
          Text(
            'Failed to load media',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}