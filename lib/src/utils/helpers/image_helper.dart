import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';

import '../../common/widgets/camera/custom_camera_screen.dart';

class ImageHelper {
  ImageHelper._();

  // File size limits
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB

  /// Pick single image from gallery
  static Future<File?> pickImage() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxHeight: 1920,
        maxWidth: 1920,
        imageQuality: 85,
      );

      if (file != null) {
        return File(file.path);
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  /// Take photo with camera
  static Future<File?> takePhoto() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.camera,
        maxHeight: 1920,
        maxWidth: 1920,
        imageQuality: 85,
      );

      if (file != null) {
        return File(file.path);
      }
      return null;
    } catch (e) {
      print('Error taking photo: $e');
      return null;
    }
  }

  /// Open custom camera screen
  static Future<File?> openCustomCamera() async {
    try {
      final result = await Get.to<File?>(
            () => CustomCameraScreen(),
        transition: Transition.cupertino,
        fullscreenDialog: true,
      );

      return result;
    } catch (e) {
      print('Error opening custom camera: $e');
      return null;
    }
  }

  /// Pick multiple media from gallery (images and videos)
  static Future<List<File>> pickMultipleMedia({int limit = 10}) async {
    try {
      final picker = ImagePicker();

      // 确保 limit 至少为 2
      final effectiveLimit = limit >= 2 ? limit : 2;

      final files = await picker.pickMultipleMedia(limit: effectiveLimit);
      return files.map((file) => File(file.path)).toList();
    } catch (e) {
      print('Error picking multiple media: $e');
      return [];
    }
  }

  static Future<File?> pickSingleMedia() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      return file != null ? File(file.path) : null;
    } catch (e) {
      print('Error picking single media: $e');
      return null;
    }
  }

  /// Check if file is an image
  static bool isImageFile(String filePath) {
    final lowerPath = filePath.toLowerCase();

    final isImage = lowerPath.contains('.jpg') ||
        lowerPath.contains('.jpeg') ||
        lowerPath.contains('.png') ||
        lowerPath.contains('.gif') ||
        lowerPath.contains('.bmp') ||
        lowerPath.contains('.webp');

    return isImage;
  }

  /// Check image file size
  static bool isImageSizeValid(File file) {
    final fileSize = file.lengthSync();
    return fileSize <= maxImageSize;
  }

  /// Compress and convert image to WebP
  static Future<File?> compressImageToWebP(File imageFile) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(
        tempDir.path,
        '${DateTime.now().millisecondsSinceEpoch}.webp',
      );

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: 85,
        format: CompressFormat.webp,
        minWidth: 1080,
        minHeight: 1080,
      );

      if (compressedFile != null) {
        return File(compressedFile.path);
      }
      return null;
    } catch (e) {
      print('Error compressing image: $e');
      return null;
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