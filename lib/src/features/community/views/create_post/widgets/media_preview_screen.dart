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
          child: Image.file(
            mediaItem.file,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => _buildErrorView(),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoViewer(MediaPreviewController controller, PostMediaItem mediaItem, int index) {
    return Obx(() {
      // Only observe if this is the current video
      if (controller.currentIndex.value != index) {
        return Container(color: Colors.black);
      }

      if (controller.videoController == null || !controller.isVideoInitialized.value) {
        return _buildVideoLoadingView();
      }

      return Center(
        child: AspectRatio(
          aspectRatio: controller.videoController!.value.aspectRatio,
          child: Stack(
            children: [
              Hero(
                tag: 'media_${mediaItem.id}',
                child: VideoPlayer(controller.videoController!),
              ),
              _buildVideoControls(controller),
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

  Widget _buildVideoControls(MediaPreviewController controller) {
    return Obx(() => AnimatedOpacity(
      opacity: controller.showControls.value ? 1.0 : 0.0,
      duration: Duration(milliseconds: 300),
      child: Center(
        child: GestureDetector(
          onTap: controller.toggleVideoPlayback,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: Icon(
              controller.isVideoPlaying.value ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
      ),
    ));
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
    // Access currentIndex once to establish dependency
    final currentIdx = controller.currentIndex.value;

    if (items.isEmpty || currentIdx >= items.length) {
      return SizedBox.shrink();
    }

    final currentMedia = items[currentIdx];

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
                currentMedia.isImage ? 'Image' : 'Video',
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