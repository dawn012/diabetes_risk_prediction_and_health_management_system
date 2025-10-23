import 'package:flutter/material.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../../../utils/helpers/media_helper.dart';
import '../../../controllers/post_controller.dart';
import 'media_gallery_viewer.dart';
import 'video_player_widget.dart';

class PostMediaView extends StatelessWidget {
  const PostMediaView({super.key, required this.mediaUrls});

  final List<String> mediaUrls;

  @override
  Widget build(BuildContext context) {
    final postController = PostController.instance;
    final isDark = THelperFunctions.isDarkMode(context);

    if (mediaUrls.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      child: _buildMediaLayout(context, postController, isDark),
    );
  }

  Widget _buildMediaLayout(BuildContext context, PostController postController, bool isDark) {
    if (mediaUrls.length == 1) {
      return _buildSingleMedia(context, mediaUrls.first, postController, isDark);
    } else if (mediaUrls.length == 2) {
      return _buildTwoMedia(context, postController, isDark);
    } else if (mediaUrls.length == 3) {
      return _buildThreeMedia(context, postController, isDark);
    } else {
      return _buildMultipleMedia(context, postController, isDark);
    }
  }

  Widget _buildSingleMedia(BuildContext context, String mediaUrl, PostController postController, bool isDark) {
    return GestureDetector(
      onTap: () => _openMediaGallery(context, 0),
      child: Container(
        width: double.infinity,
        height: 300,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
          child: MediaUtils.getMediaType(mediaUrl) == 'video'
              ? VideoPlayerWidget(videoUrl: mediaUrl)
              : Image.network(
            mediaUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildLoadingIndicator(isDark);
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorWidget(isDark);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTwoMedia(BuildContext context, PostController postController, bool isDark) {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: _buildMediaItem(context, 0, postController, isDark),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: _buildMediaItem(context, 1, postController, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildThreeMedia(BuildContext context, PostController postController, bool isDark) {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildMediaItem(context, 0, postController, isDark),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _buildMediaItem(context, 1, postController, isDark),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: _buildMediaItem(context, 2, postController, isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleMedia(BuildContext context, PostController postController, bool isDark) {
    final remainingCount = mediaUrls.length - 3;

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildMediaItem(context, 0, postController, isDark),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _buildMediaItem(context, 1, postController, isDark),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Stack(
                    children: [
                      _buildMediaItem(context, 2, postController, isDark),
                      if (remainingCount > 0)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '+$remainingCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaItem(BuildContext context, int index, PostController postController, bool isDark) {
    if (index >= mediaUrls.length) return const SizedBox.shrink();

    final mediaUrl = mediaUrls[index];
    final isVideo = MediaUtils.getMediaType(mediaUrl) == 'video';

    return GestureDetector(
      onTap: () => _openMediaGallery(context, index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isDark ? TColors.darkGrey : TColors.lightGrey,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isVideo)
                VideoPlayerWidget(
                  videoUrl: mediaUrl,
                  autoPlay: false,
                  showControls: false,
                )
              else
                Image.network(
                  mediaUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return _buildLoadingIndicator(isDark);
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return _buildErrorWidget(isDark);
                  },
                ),

              // Video play icon overlay
              if (isVideo)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_filled,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(bool isDark) {
    return Container(
      color: isDark ? TColors.darkGrey : TColors.lightGrey,
      child: Center(
        child: CircularProgressIndicator(
          color: TColors.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorWidget(bool isDark) {
    return Container(
      color: isDark ? TColors.darkGrey : TColors.lightGrey,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: isDark ? TColors.darkGrey : TColors.textSecondary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load',
              style: TextStyle(
                color: isDark ? TColors.darkGrey : TColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openMediaGallery(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaGalleryViewer(
          mediaUrls: mediaUrls,
          initialIndex: initialIndex,
        ),
        fullscreenDialog: true,
      ),
    );
  }
}