import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

class WebImageHelper {
  WebImageHelper._();

  // File size limits
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB

  /// Pick single image from gallery (Web 专用)
  static Future<Uint8List?> pickImage() async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: ImageSource.gallery,
        maxHeight: 1920,
        maxWidth: 1920,
        imageQuality: 85,
      );

      if (xfile != null) {
        return await xfile.readAsBytes();
      }
      return null;
    } catch (e) {
      print('Error picking image on web: $e');
      return null;
    }
  }

  /// Pick multiple images (Web 专用)
  static Future<List<Uint8List>> pickMultipleImages({int limit = 10}) async {
    try {
      final picker = ImagePicker();
      final files = await picker.pickMultipleMedia(limit: limit);

      final List<Uint8List> images = [];
      for (final file in files) {
        final bytes = await file.readAsBytes();
        images.add(bytes);
      }
      return images;
    } catch (e) {
      print('Error picking multiple images on web: $e');
      return [];
    }
  }

  /// Check image bytes size (Web 专用)
  static bool isImageSizeValid(Uint8List bytes) {
    return bytes.length <= maxImageSize; // 5MB
  }

  /// Check if bytes represent a valid image (Web 专用)
  static bool isImageBytes(Uint8List bytes) {
    if (bytes.length < 8) return false;

    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;

    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E &&
        bytes[3] == 0x47 && bytes[4] == 0x0D && bytes[5] == 0x0A &&
        bytes[6] == 0x1A && bytes[7] == 0x0A) return true;

    // GIF: 47 49 46 38
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x38) return true;

    // BMP: 42 4D
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) return true;

    // WebP: RIFF header + WEBP
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) return true;

    return false;
  }

  /// Compress image bytes to WebP (Web 专用)
  static Future<Uint8List?> compressImageToWebP(Uint8List bytes) async {
    try {
      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        quality: 85,
        format: CompressFormat.webp,
        minWidth: 1080,
        minHeight: 1080,
      );
      return compressedBytes;
    } catch (e) {
      print('Error compressing image on web: $e');
      return null;
    }
  }

  /// Format bytes size for display (Web 专用)
  static String formatBytesSize(Uint8List bytes) {
    final size = bytes.length;
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}