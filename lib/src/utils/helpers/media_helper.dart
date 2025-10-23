import 'dart:io';

import 'image_helper.dart';
import 'video_helper.dart';

class MediaUtils {
  MediaUtils._();

  static const int maxMediaCount = 10;

  /// Get media type from file path
  static String getMediaType(String filePath) {
    if (ImageHelper.isImageFile(filePath)) return 'image';
    if (VideoHelper.isVideoFile(filePath)) return 'video';
    return 'unknown';
  }

  /// Validate media file
  static Future<String?> validateMediaFile(File file) async {
    final filePath = file.path;
    final isImage = ImageHelper.isImageFile(filePath);
    final isVideo = VideoHelper.isVideoFile(filePath);

    if (!isImage && !isVideo) {
      return 'Unsupported file format. Please select an image or video file.';
    }

    if (isImage && !ImageHelper.isImageSizeValid(file)) {
      final actualSize = ImageHelper.formatFileSize(file.lengthSync());
      return 'Image size ($actualSize) exceeds the maximum allowed size of 5MB.';
    }

    if (isVideo && !VideoHelper.isVideoSizeValid(file)) {
      final actualSize = VideoHelper.formatFileSize(file.lengthSync());
      return 'Video size ($actualSize) exceeds the maximum allowed size of 20MB.';
    }

    return null; // No error
  }
}