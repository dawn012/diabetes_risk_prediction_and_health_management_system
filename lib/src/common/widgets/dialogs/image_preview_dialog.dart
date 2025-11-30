import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../utils/constants/admin_colors.dart';
import '../../../utils/helpers/helper_functions.dart';

class ImagePreviewDialog extends StatelessWidget {
  final ImageProvider image;
  final String? title;
  final String? subtitle;
  final double maxWidth;
  final double maxHeight;
  final bool showCloseButton;
  final bool showTitle;

  const ImagePreviewDialog({
    super.key,
    required this.image,
    this.title,
    this.subtitle,
    this.maxWidth = 600,
    this.maxHeight = 600,
    this.showCloseButton = true,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: () => Get.back(),
        child: Stack(
          alignment: Alignment.center, // 改为 center 让内容居中
          children: [
            // Background click area
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
            ),

            // Main content - 使用 Align 确保内容在中央
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min, // 使用 min 让内容自适应高度
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showTitle && title != null) ...[
                    _buildTitleSection(title!, subtitle, darkMode),
                    const SizedBox(height: 16),
                  ],

                  // Image container with zoom capability
                  _buildZoomableImageContainer(darkMode),

                  // Bottom hint
                  const SizedBox(height: 16),
                  _buildHintText(darkMode),
                ],
              ),
            ),

            // Close button - 调整位置
            if (showCloseButton)
              Positioned(
                top: 40,
                right: 20,
                child: _buildCloseButton(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomableImageContainer(bool darkMode) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InteractiveViewer(
          panEnabled: true, // 允许拖拽
          scaleEnabled: true, // 允许缩放
          minScale: 0.5, // 最小缩放比例
          maxScale: 4.0, // 最大缩放比例
          boundaryMargin: const EdgeInsets.all(20), // 边界边距
          child: Image(
            image: image,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorWidget(darkMode);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildLoadingWidget(loadingProgress);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection(String title, String? subtitle, bool darkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorWidget(bool darkMode) {
    return Container(
      width: 200,
      height: 200,
      color: TAdminColors.getSurfaceColor(darkMode),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.gallery_remove_bold,
            size: 48,
            color: TAdminColors.getOnSurfaceVariantColor(darkMode),
          ),
          const SizedBox(height: 12),
          Text(
            'Failed to load image',
            style: TextStyle(
              color: TAdminColors.getOnSurfaceVariantColor(darkMode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget(ImageChunkEvent loadingProgress) {
    return Container(
      width: 200,
      height: 200,
      color: Colors.black26,
      child: Center(
        child: CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
              : null,
          valueColor: AlwaysStoppedAnimation<Color>(TAdminColors.primary),
        ),
      ),
    );
  }

  Widget _buildHintText(bool darkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Tap outside to close • Pinch to zoom',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return IconButton(
      onPressed: () => Get.back(),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.close,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  // Static methods for easy calling
  static void show({
    required BuildContext context,
    required ImageProvider image,
    String? title,
    String? subtitle,
    double maxWidth = 600,
    double maxHeight = 600,
    bool showCloseButton = true,
    bool showTitle = true,
  }) {
    Get.dialog(
      ImagePreviewDialog(
        image: image,
        title: title,
        subtitle: subtitle,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        showCloseButton: showCloseButton,
        showTitle: showTitle,
      ),
      barrierDismissible: true,
      barrierColor: Colors.black87,
    );
  }

  // Convenience method for network images
  static void showNetworkImage({
    required BuildContext context,
    required String imageUrl,
    String? title,
    String? subtitle,
    double maxWidth = 600,
    double maxHeight = 600,
  }) {
    show(
      context: context,
      image: NetworkImage(imageUrl),
      title: title,
      subtitle: subtitle,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }

  // Convenience method for asset images
  static void showAssetImage({
    required BuildContext context,
    required String assetPath,
    String? title,
    String? subtitle,
    double maxWidth = 600,
    double maxHeight = 600,
  }) {
    show(
      context: context,
      image: AssetImage(assetPath),
      title: title,
      subtitle: subtitle,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }

  // Convenience method for memory images
  static void showMemoryImage({
    required BuildContext context,
    required Uint8List imageBytes,
    String? title,
    String? subtitle,
    double maxWidth = 600,
    double maxHeight = 600,
  }) {
    show(
      context: context,
      image: MemoryImage(imageBytes),
      title: title,
      subtitle: subtitle,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }
}