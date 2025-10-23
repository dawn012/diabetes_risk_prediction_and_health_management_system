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
      return Image.file(
        mediaItem.displayThumbnail,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorThumbnail(),
      );
    } catch (e) {
      return _buildErrorThumbnail();
    }
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
    return GestureDetector(
      onTap: onAddMedia,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
          border: Border.all(
            color: TColors.primary.withOpacity(0.3),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: TColors.primary,
              size: 32,
            ),
            SizedBox(height: 4),
            Text(
              'Add Media',
              style: TextStyle(
                color: TColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
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
    );
  }
}