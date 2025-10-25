import 'package:flutter/material.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../../../utils/helpers/media_helper.dart';
import 'media_gallery_viewer.dart';
import 'video_player_widget.dart';

class PostMediaView extends StatelessWidget {
  const PostMediaView({super.key, required this.mediaUrls});

  final List<String> mediaUrls;

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);

    if (mediaUrls.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      child: _buildMediaLayout(context, isDark),
    );
  }

  Widget _buildMediaLayout(BuildContext context, bool isDark) {
    if (mediaUrls.length == 1) {
      return _buildSingleMedia(context, mediaUrls.first, isDark);
    } else if (mediaUrls.length == 2) {
      return _buildTwoMedia(context, isDark);
    } else if (mediaUrls.length == 3) {
      return _buildThreeMedia(context, isDark);
    } else {
      return _buildMultipleMedia(context, isDark);
    }
  }

  Widget _buildSingleMedia(BuildContext context, String mediaUrl, bool isDark) {
    final isVideo = MediaUtils.getMediaType(mediaUrl) == 'video';

    return GestureDetector(
      onTap: () => _openMediaGallery(context, 0),
      child: SizedBox(
        width: double.infinity,
        height: 300,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
          child: isVideo
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

  Widget _buildTwoMedia(BuildContext context, bool isDark) {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: _buildMediaItem(context, 0, isDark),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: _buildMediaItem(context, 1, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildThreeMedia(BuildContext context, bool isDark) {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildMediaItem(context, 0, isDark),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _buildMediaItem(context, 1, isDark),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: _buildMediaItem(context, 2, isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleMedia(BuildContext context, bool isDark) {
    final remainingCount = mediaUrls.length - 3;

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildMediaItem(context, 0, isDark),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _buildMediaItem(context, 1, isDark),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openMediaGallery(context, 2),
                    child: Stack(
                      children: [
                        _buildMediaItem(context, 2, isDark, clickable: false),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaItem(BuildContext context, int index, bool isDark, {bool clickable = true}) {
    if (index >= mediaUrls.length) return const SizedBox.shrink();

    final mediaUrl = mediaUrls[index];
    final isVideo = MediaUtils.getMediaType(mediaUrl) == 'video';

    Widget mediaWidget = Container(
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
              _buildVideoThumbnailWidget(mediaUrl, isDark)
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

            if (isVideo)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_filled,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (clickable) {
      return GestureDetector(
        onTap: () => _openMediaGallery(context, index),
        child: mediaWidget,
      );
    }

    return mediaWidget;
  }

  Widget _buildVideoThumbnailWidget(String videoUrl, bool isDark) {
    final thumbnailUrl = _generateThumbnailUrl(videoUrl);

    return StatefulBuilder(
      builder: (context, setState) {
        bool hasError = false;

        return GestureDetector(
          onTap: hasError ? () => setState(() => hasError = false) : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              hasError
                  ? _buildVideoPlaceholder(isDark)
                  : Image.network(
                thumbnailUrl ?? videoUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildLoadingIndicator(isDark);
                },
                errorBuilder: (context, error, stackTrace) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted && !hasError) {
                      setState(() => hasError = true);
                    }
                  });
                  return _buildVideoPlaceholder(isDark);
                },
              ),

              if (!hasError)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoPlaceholder(bool isDark) {
    return Container(
      color: isDark ? TColors.darkerGrey : TColors.grey,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam,
              color: isDark ? TColors.lightGrey : TColors.darkGrey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Video',
              style: TextStyle(
                color: isDark ? TColors.lightGrey : TColors.darkGrey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _generateThumbnailUrl(String videoUrl) {
    try {
      if (!videoUrl.contains('firebasestorage.googleapis.com')) {
        return null;
      }

      final uri = Uri.parse(videoUrl);
      final pathSegments = uri.pathSegments;

      final oIndex = pathSegments.indexOf('o');
      if (oIndex == -1 || oIndex + 1 >= pathSegments.length) {
        return null;
      }

      final encodedPath = pathSegments[oIndex + 1];
      final decodedPath = Uri.decodeComponent(encodedPath);

      final segments = decodedPath.split('/');
      if (segments.length < 3 || !segments.last.contains('.')) {
        return null;
      }

      final fileNameWithExt = segments.last;
      final dotIndex = fileNameWithExt.lastIndexOf('.');
      final fileName = fileNameWithExt.substring(0, dotIndex);

      final thumbnailPath = 'community/thumbnails/$fileName.webp';
      return 'https://firebasestorage.googleapis.com/v0/b/diabetes-health-system.firebasestorage.app/o/${Uri.encodeComponent(thumbnailPath)}?alt=media';

    } catch (e) {
      return null;
    }
  }

  // 优化后的 Loading 指示器 - 移除背景色
  Widget _buildLoadingIndicator(bool isDark) {
    return Center(
      child: CircularProgressIndicator(
        color: TColors.primary,
        strokeWidth: 2.5,
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
              color: isDark ? TColors.lightGrey : TColors.darkGrey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              'Failed to load',
              style: TextStyle(
                color: isDark ? TColors.lightGrey : TColors.darkGrey,
                fontSize: 10,
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