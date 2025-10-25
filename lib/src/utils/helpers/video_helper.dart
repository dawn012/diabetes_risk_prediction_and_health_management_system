import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;

class VideoHelper {
  VideoHelper._();

  // File size limits
  static const int maxVideoSize = 20 * 1024 * 1024; // 20MB

  /// Pick video from gallery
  static Future<File?> pickVideo() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (file != null) {
        return File(file.path);
      }
      return null;
    } catch (e) {
      print('Error picking video: $e');
      return null;
    }
  }

  /// Record video with camera
  static Future<File?> recordVideo() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );

      if (file != null) {
        return File(file.path);
      }
      return null;
    } catch (e) {
      print('Error recording video: $e');
      return null;
    }
  }

  /// Check if file is a video
  static bool isVideoFile(String filePath) {
    final lowerPath = filePath.toLowerCase();

    // 检查是否包含视频扩展名
    final isVideo = lowerPath.contains('.mp4') ||
        lowerPath.contains('.mov') ||
        lowerPath.contains('.avi') ||
        lowerPath.contains('.mkv') ||
        lowerPath.contains('.m4v') ||
        lowerPath.contains('.3gp') ||
        lowerPath.contains('.mpeg');

    return isVideo;
  }

  /// Check video file size
  static bool isVideoSizeValid(File file) {
    final fileSize = file.lengthSync();
    return fileSize <= maxVideoSize;
  }

  /// Compress and convert video to MP4
  static Future<File?> compressVideoToMP4(File videoFile) async {
    try {
      final info = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (info != null && info.file != null) {
        return info.file!;
      }
      return null;
    } catch (e) {
      print('Error compressing video: $e');
      return null;
    }
  }

  /// Get video thumbnail as File
  static Future<File?> getVideoThumbnailFile(File videoFile) async {
    try {
      final tempDir = await _getTemporaryDirectory();

      // 使用 video_thumbnail 包生成缩略图
      final thumbnailPath = await vt.VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        thumbnailPath: tempDir,
        imageFormat: vt.ImageFormat.JPEG,
        maxWidth: 300, // 设置最大宽度
        quality: 75,
      );

      if (thumbnailPath != null) {
        final thumbnailFile = File(thumbnailPath);
        if (thumbnailFile.existsSync()) {
          return thumbnailFile;
        }
      }

      print('Thumbnail generation failed');
      return null;
    } catch (e) {
      print('Error getting video thumbnail: $e');
      return null;
    }
  }

  /// Get video thumbnail as Uint8List (用于网络显示)
  static Future<Uint8List?> getVideoThumbnailBytes(String videoPath) async {
    try {
      final uint8list = await vt.VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: vt.ImageFormat.JPEG,
        maxWidth: 300,
        quality: 50,
      );
      return uint8list;
    } catch (e) {
      print('Error getting video thumbnail bytes: $e');
      return null;
    }
  }

  /// Get temporary directory for thumbnails
  static Future<String> _getTemporaryDirectory() async {
    final tempDir = Directory.systemTemp;
    final thumbDir = Directory('${tempDir.path}/video_thumbnails');
    if (!thumbDir.existsSync()) {
      thumbDir.createSync(recursive: true);
    }
    return thumbDir.path;
  }

  /// Get video duration
  static Future<Duration?> getVideoDuration(File videoFile) async {
    try {
      final info = await VideoCompress.getMediaInfo(videoFile.path);
      return Duration(milliseconds: info.duration?.toInt() ?? 0);
    } catch (e) {
      print('Error getting video duration: $e');
      return null;
    }
  }

  /// Clean up temporary compressed files
  static Future<void> cleanupTempFiles() async {
    try {
      await VideoCompress.deleteAllCache();
    } catch (e) {
      print('Error cleaning up temp files: $e');
    }
  }

  /// Get file size in MB
  static double getFileSizeInMB(File file) {
    final bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}