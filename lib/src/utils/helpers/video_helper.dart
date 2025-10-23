import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:video_compress/video_compress.dart';

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
    final extension = path.extension(filePath).toLowerCase();
    return ['.mp4', '.mov', '.avi', '.mkv', '.m4v', '.3gp'].contains(extension);
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

  /// Get video thumbnail
  static Future<File?> getVideoThumbnail(File videoFile) async {
    try {
      final thumbnail = await VideoCompress.getFileThumbnail(videoFile.path);
      return thumbnail;
    } catch (e) {
      print('Error getting video thumbnail: $e');
      return null;
    }
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