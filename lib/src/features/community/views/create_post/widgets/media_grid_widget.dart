import 'package:flutter/material.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../controllers/post_create_controller.dart';
import '../../../models/post_media_item.dart';

class MediaGridWidget extends StatelessWidget {
  final List<PostMediaItem> mediaItems;
  final Function(int) onMediaTap;
  final Function(String) onMediaDelete;
  final bool showAddButton;
  final VoidCallback? onAddMedia;
  final int maxMediaCount;

  const MediaGridWidget({
    super.key,
    required this.mediaItems,
    required this.onMediaTap,
    required this.onMediaDelete,
    this.showAddButton = true,
    this.onAddMedia,
    this.maxMediaCount = 10,
  });

  @override
  Widget build(BuildContext context) {
    if (mediaItems.isEmpty && !showAddButton) {
      return SizedBox.shrink();
    }

    // Calculate item width: (screen width - padding - gaps) / 3
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = TSizes.defaultSpace * 2; // Left and right padding
    final totalGapWidth = TSizes.sm * 2; // 2 gaps between 3 items
    final itemWidth = (screenWidth - horizontalPadding - totalGapWidth) / 3;

    // Combine media items and add button into one list
    final List<Widget> allItems = [
      ...mediaItems.asMap().entries.map((entry) {
        final index = entry.key;
        final mediaItem = entry.value;
        return _buildMediaThumbnail(mediaItem, index, itemWidth);
      }),
      if (showAddButton && mediaItems.length < PostCreateController.maxMediaCount)
        _buildAddMediaButton(itemWidth),
    ];

    return Wrap(
      spacing: TSizes.sm,
      runSpacing: TSizes.sm,
      children: allItems,
    );
  }

  Widget _buildMediaThumbnail(PostMediaItem mediaItem, int index, double size) {
    return GestureDetector(
      onTap: () => onMediaTap(index),
      child: Hero(
        tag: 'media_${mediaItem.id}',
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
            border: Border.all(
              color: Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Media thumbnail
                _buildThumbnail(mediaItem),

                // Overlay for processing/error states
                _buildOverlay(mediaItem),

                // Media type indicator
                _buildMediaTypeIndicator(mediaItem),

                // Delete button
                _buildDeleteButton(mediaItem),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(PostMediaItem mediaItem) {
    try {
      // 如果是现有媒体项（编辑模式），显示网络图片
      if (mediaItem.isExisting && mediaItem.existingUrl != null) {
        return _buildNetworkThumbnail(mediaItem);
      }

      // 否则显示本地文件
      final thumbnail = mediaItem.displayThumbnail;
      if (thumbnail != null && thumbnail.existsSync()) {
        return Image.file(
          thumbnail,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildErrorThumbnail(),
        );
      } else {
        return _buildErrorThumbnail();
      }
    } catch (e) {
      return _buildErrorThumbnail();
    }
  }

  Widget _buildNetworkThumbnail(PostMediaItem mediaItem) {
    print('=== DEBUG NETWORK THUMBNAIL ===');
    print('Media ID: ${mediaItem.id}');
    print('Media Type: ${mediaItem.type}');
    print('Is Video: ${mediaItem.isVideo}');
    print('Existing URL: ${mediaItem.existingUrl}');

    // 🔥 关键修复：对于视频，使用与 Post List 相同的逻辑
    if (mediaItem.isVideo && mediaItem.existingUrl != null) {
      final thumbnailUrl = _generateThumbnailUrl(mediaItem.existingUrl!);
      print('🎥 Video - Generated thumbnail URL: $thumbnailUrl');

      if (thumbnailUrl != null) {
        return _buildNetworkImageWithFallback(thumbnailUrl);
      } else {
        print('❌ Failed to generate thumbnail URL');
      }
    }

    // 如果是图片，使用原始URL
    if (mediaItem.isImage && mediaItem.existingUrl != null) {
      print('🖼️ Image - Using original URL: ${mediaItem.existingUrl}');
      return _buildNetworkImageWithFallback(mediaItem.existingUrl!);
    }

    print('❌ No suitable URL found');
    return _buildErrorThumbnail();
  }

  /// 🔥 复制 Post List 中的缩略图生成逻辑
  String? _generateThumbnailUrl(String videoUrl) {
    try {
      print('🔄 Generating thumbnail URL from: $videoUrl');

      if (!videoUrl.contains('firebasestorage.googleapis.com')) {
        print('❌ Not a Firebase Storage URL');
        return null;
      }

      final uri = Uri.parse(videoUrl);
      final pathSegments = uri.pathSegments;

      final oIndex = pathSegments.indexOf('o');
      if (oIndex == -1 || oIndex + 1 >= pathSegments.length) {
        print('❌ Could not find "o" in path segments');
        return null;
      }

      final encodedPath = pathSegments[oIndex + 1];
      final decodedPath = Uri.decodeComponent(encodedPath);
      print('Decoded path: $decodedPath');

      final segments = decodedPath.split('/');
      if (segments.length < 3 || !segments.last.contains('.')) {
        print('❌ Invalid path structure');
        return null;
      }

      final fileNameWithExt = segments.last;
      final dotIndex = fileNameWithExt.lastIndexOf('.');
      if (dotIndex == -1) {
        print('❌ No file extension found');
        return null;
      }

      final fileName = fileNameWithExt.substring(0, dotIndex);
      print('Extracted filename: $fileName');

      final thumbnailPath = 'community/thumbnails/$fileName.webp';
      final encodedThumbPath = Uri.encodeComponent(thumbnailPath);

      final thumbnailUrl = 'https://firebasestorage.googleapis.com/v0/b/diabetes-health-system.firebasestorage.app/o/$encodedThumbPath?alt=media';

      print('✅ Generated thumbnail URL: $thumbnailUrl');
      return thumbnailUrl;

    } catch (e) {
      print('❌ Error generating thumbnail URL: $e');
      return null;
    }
  }

  Widget _buildNetworkImageWithFallback(String imageUrl) {
    print('🔄 Loading network image: $imageUrl');

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          print('✅ Image loaded successfully: $imageUrl');
          return child;
        }
        print('⏳ Loading image... ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
        return _buildLoadingIndicator();
      },
      errorBuilder: (context, error, stackTrace) {
        print('❌ IMAGE LOAD ERROR:');
        print('URL: $imageUrl');
        print('Error: $error');

        return Container(
          color: Colors.grey[200],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.grey[500], size: 24),
              SizedBox(height: 8),
              Text(
                'Load Failed\n$imageUrl',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 8,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(
        color: Colors.blue,
        strokeWidth: 2,
      ),
    );
  }

  Widget _buildErrorThumbnail() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.grey[400],
            size: 24,
          ),
          SizedBox(height: 4),
          Text(
            'Error',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay(PostMediaItem mediaItem) {
    Color? overlayColor;
    Widget? overlayContent;

    if (mediaItem.isProcessing) {
      overlayColor = Colors.black54;
      overlayContent = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Processing...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else if (mediaItem.hasError) {
      overlayColor = TColors.error.withOpacity(0.8);
      overlayContent = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 20,
          ),
          SizedBox(height: 2),
          Text(
            'Failed',
            style: TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    if (overlayColor != null && overlayContent != null) {
      return Container(
        color: overlayColor,
        child: Center(child: overlayContent),
      );
    }

    return SizedBox.shrink();
  }

  Widget _buildMediaTypeIndicator(PostMediaItem mediaItem) {
    if (mediaItem.isProcessing || mediaItem.hasError) {
      return SizedBox.shrink();
    }

    return Positioned(
      bottom: 4,
      left: 4,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              mediaItem.isVideo ? Icons.play_arrow : Icons.image,
              color: Colors.white,
              size: 12,
            ),
            if (mediaItem.isVideo && mediaItem.duration != null) ...[
              SizedBox(width: 2),
              Text(
                mediaItem.formattedDuration,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButton(PostMediaItem mediaItem) {
    return Positioned(
      top: 4,
      right: 4,
      child: GestureDetector(
        onTap: () => onMediaDelete(mediaItem.id),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: TColors.error,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Icon(
            Icons.close,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildAddMediaButton(double size) {
    final isDisabled = mediaItems.length >= maxMediaCount;

    return GestureDetector(
      onTap: isDisabled ? null : onAddMedia,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isDisabled ? Colors.grey[200] : Colors.grey[100],
            borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
            border: Border.all(
              color: isDisabled
                  ? Colors.grey.withOpacity(0.3)
                  : TColors.primary.withOpacity(0.3),
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isDisabled ? Icons.block : Icons.add_photo_alternate_outlined,
                color: isDisabled ? Colors.grey : TColors.primary,
                size: 32,
              ),
              SizedBox(height: 4),
              Text(
                isDisabled ? 'Limit Reached' : 'Add Media',
                style: TextStyle(
                  color: isDisabled ? Colors.grey : TColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (!isDisabled)
                Text(
                  '${maxMediaCount - mediaItems.length} left',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 8,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}