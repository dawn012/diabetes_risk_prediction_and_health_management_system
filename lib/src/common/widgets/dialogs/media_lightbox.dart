import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../utils/constants/admin_colors.dart';
import '../../../utils/helpers/helper_functions.dart';

class MediaItem {
  final String type; // 'text', 'image', 'video'
  final String? url;
  final String? content; // for text content
  final String? thumbnail;

  MediaItem({
    required this.type,
    this.url,
    this.content,
    this.thumbnail,
  });
}

class MediaLightboxDialog extends StatefulWidget {
  final List<MediaItem> mediaItems;
  final int initialIndex;

  const MediaLightboxDialog({
    super.key,
    required this.mediaItems,
    this.initialIndex = 0,
  });

  @override
  State<MediaLightboxDialog> createState() => _MediaLightboxDialogState();
}

class _MediaLightboxDialogState extends State<MediaLightboxDialog> {
  late PageController _pageController;
  late int currentIndex;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _initializeCurrentMedia();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _initializeCurrentMedia() {
    final currentMedia = widget.mediaItems[currentIndex];
    if (currentMedia.type == 'video' && currentMedia.url != null) {
      _videoController?.dispose();
      _videoController = VideoPlayerController.networkUrl(Uri.parse(currentMedia.url!));
      _videoController!.initialize();
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      currentIndex = index;
      _videoController?.dispose();
      _videoController = null;
    });
    _initializeCurrentMedia();
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    return Dialog.fullscreen(
      backgroundColor: Colors.black87,
      child: Stack(
        children: [
          // Main content area
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: widget.mediaItems.length,
            itemBuilder: (context, index) {
              final media = widget.mediaItems[index];
              return Center(
                child: _buildMediaContent(media, darkMode),
              );
            },
          ),

          // Close button
          Positioned(
            top: 40,
            right: 24,
            child: IconButton(
              onPressed: () => Get.back(),
              icon: Icon(
                Iconsax.close_circle_bold,
                color: Colors.white,
                size: 32,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
              ),
            ),
          ),

          // Navigation arrows
          if (widget.mediaItems.length > 1) ...[
            Positioned(
              left: 24,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  onPressed: _previousMedia,
                  icon: Icon(
                    Iconsax.arrow_left_2_bold,
                    color: Colors.white,
                    size: 32,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 24,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  onPressed: _nextMedia,
                  icon: Icon(
                    Iconsax.arrow_right_2_bold,
                    color: Colors.white,
                    size: 32,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                ),
              ),
            ),
          ],

          // Bottom info bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(24),
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
                  // Media indicators
                  if (widget.mediaItems.length > 1) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.mediaItems.length,
                            (index) => Container(
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == currentIndex
                                ? Colors.white
                                : Colors.white38,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                  ],

                  // Media counter
                  Text(
                    '${currentIndex + 1} of ${widget.mediaItems.length}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContent(MediaItem media, bool darkMode) {
    switch (media.type) {
      case 'image':
        return Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Image.network(
            media.url!,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  color: TAdminColors.primary,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Iconsax.gallery_slash_bold,
                    size: 48,
                    color: Colors.white60,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Failed to load image',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

      case 'video':
        return Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: _videoController != null
              ? AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: Stack(
              children: [
                VideoPlayer(_videoController!),
                Positioned.fill(
                  child: Center(
                    child: _videoController!.value.isPlaying
                        ? SizedBox.shrink()
                        : IconButton(
                      onPressed: () {
                        setState(() {
                          _videoController!.play();
                        });
                      },
                      icon: Icon(
                        Iconsax.play_bold,
                        size: 64,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
              : Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Iconsax.video_slash_bold,
                  size: 48,
                  color: Colors.white60,
                ),
                SizedBox(height: 16),
                Text(
                  'Failed to load video',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );

      case 'text':
        return Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: TAdminColors.getSurfaceColor(darkMode),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Iconsax.document_text_bold,
                      color: TAdminColors.primary,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Text Content',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: TAdminColors.getOnSurfaceColor(darkMode),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Text(
                  media.content ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: TAdminColors.getOnSurfaceColor(darkMode),
                  ),
                ),
              ],
            ),
          ),
        );

      default:
        return Container(
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Iconsax.document_bold,
                size: 48,
                color: Colors.white60,
              ),
              SizedBox(height: 16),
              Text(
                'Unsupported media type',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
    }
  }

  void _previousMedia() {
    if (currentIndex > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _pageController.animateToPage(
        widget.mediaItems.length - 1,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextMedia() {
    if (currentIndex < widget.mediaItems.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _pageController.animateToPage(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}

// Helper function to show media lightbox
void showMediaLightbox(List<MediaItem> mediaItems, {int initialIndex = 0}) {
  Get.dialog(
    MediaLightboxDialog(
      mediaItems: mediaItems,
      initialIndex: initialIndex,
    ),
  );
}