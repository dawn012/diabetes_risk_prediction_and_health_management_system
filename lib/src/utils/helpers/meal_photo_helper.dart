import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'image_helper.dart';

/// Helper class specifically for meal photo processing
/// Handles FatSecret API requirements (1MB limit, 512x512 resolution)
class MealPhotoHelper {
  MealPhotoHelper._();

  // FatSecret API specific configuration
  static const int maxMealPhotoSize = 1 * 1024 * 1024; // 1MB strict limit
  static const int targetResolution = 512; // 512x512 for optimal recognition
  static const int initialQuality = 75; // Starting quality

  /// Compress and convert image to WebP for meal photo (1MB limit)
  /// This is optimized specifically for FatSecret API requirements
  static Future<File?> compressImageForMealPhoto(File imageFile) async {
    try {
      // Validate input file
      if (!await imageFile.exists()) {
        print('Error: Image file does not exist');
        return null;
      }

      // Check if it's an image file using ImageHelper
      if (!ImageHelper.isImageFile(imageFile.path)) {
        print('Error: Not a valid image file');
        return null;
      }

      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(
        tempDir.path,
        'meal_${DateTime.now().millisecondsSinceEpoch}.webp',
      );

      print('Starting meal photo compression...');
      print('Original size: ${ImageHelper.formatFileSize(imageFile.lengthSync())}');

      // Attempt 1: Quality 75%
      var result = await _compressWithQuality(
        imageFile,
        targetPath,
        initialQuality,
        attempt: 1,
      );

      if (result != null && _isWithinSizeLimit(result)) {
        print('✅ Compression successful with quality ${initialQuality}%');
        return result;
      }

      // Attempt 2: Quality 60%
      result = await _compressWithQuality(
        imageFile,
        targetPath.replaceAll('.webp', '_q60.webp'),
        60,
        attempt: 2,
      );

      if (result != null && _isWithinSizeLimit(result)) {
        print('✅ Compression successful with quality 60%');
        return result;
      }

      // Attempt 3: Quality 45%
      result = await _compressWithQuality(
        imageFile,
        targetPath.replaceAll('.webp', '_q45.webp'),
        45,
        attempt: 3,
      );

      if (result != null && _isWithinSizeLimit(result)) {
        print('✅ Compression successful with quality 45%');
        return result;
      }

      // Final attempt: Quality 30%
      result = await _compressWithQuality(
        imageFile,
        targetPath.replaceAll('.webp', '_q30.webp'),
        30,
        attempt: 4,
      );

      if (result != null && _isWithinSizeLimit(result)) {
        print('✅ Compression successful with quality 30%');
        return result;
      }

      print('❌ Failed to compress image below 1MB');
      return null;

    } catch (e) {
      print('Error compressing meal photo: $e');
      return null;
    }
  }

  /// Compress image with specific quality
  static Future<File?> _compressWithQuality(
      File imageFile,
      String targetPath,
      int quality, {
        int attempt = 1,
      }) async {
    try {
      print('Attempt $attempt: Compressing with quality $quality%...');

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: quality,
        format: CompressFormat.webp,
        minWidth: targetResolution,
        minHeight: targetResolution,
        keepExif: false, // Remove metadata to reduce size
      );

      if (compressedFile != null) {
        final resultFile = File(compressedFile.path);
        final fileSize = resultFile.lengthSync();
        print('Result: ${ImageHelper.formatFileSize(fileSize)}');
        return resultFile;
      }

      return null;
    } catch (e) {
      print('Error in compression attempt $attempt: $e');
      return null;
    }
  }

  /// Check if file is within 1MB size limit
  static bool _isWithinSizeLimit(File file) {
    try {
      return file.lengthSync() <= maxMealPhotoSize;
    } catch (e) {
      print('Error checking file size: $e');
      return false;
    }
  }

  /// Validate if meal photo meets all requirements
  static bool isMealPhotoSizeValid(File file) {
    return _isWithinSizeLimit(file);
  }

  /// Get formatted size string using ImageHelper
  static String getFormattedSize(File file) {
    return ImageHelper.formatFileSize(file.lengthSync());
  }

  /// Get size in MB using ImageHelper
  static double getSizeInMB(File file) {
    return ImageHelper.getFileSizeInMB(file);
  }

  /// Validate meal photo and return detailed results
  static Future<Map<String, dynamic>> validateMealPhoto(File imageFile) async {
    final errors = <String>[];

    // Check if file exists
    if (!await imageFile.exists()) {
      errors.add('File does not exist');
      return {'valid': false, 'errors': errors};
    }

    // Check file type using ImageHelper
    if (!ImageHelper.isImageFile(imageFile.path)) {
      errors.add('Invalid file format. Only JPG, PNG, and WebP are supported');
    }

    // Check file size (before compression)
    final fileSize = imageFile.lengthSync();
    final sizeMB = ImageHelper.getFileSizeInMB(imageFile);

    // Just info, not an error (we'll compress it)
    final info = <String, dynamic>{
      'originalSize': fileSize,
      'originalSizeMB': sizeMB,
      'originalFormatted': ImageHelper.formatFileSize(fileSize),
      'needsCompression': fileSize > maxMealPhotoSize,
    };

    return {
      'valid': errors.isEmpty,
      'errors': errors,
      'info': info,
    };
  }

  /// Batch compress multiple meal photos
  static Future<List<File?>> compressMultipleMealPhotos(
      List<File> imageFiles, {
        Function(int current, int total)? onProgress,
      }) async {
    final results = <File?>[];

    for (int i = 0; i < imageFiles.length; i++) {
      if (onProgress != null) {
        onProgress(i + 1, imageFiles.length);
      }

      final compressed = await compressImageForMealPhoto(imageFiles[i]);
      results.add(compressed);

      // Small delay between compressions to avoid overwhelming the system
      if (i < imageFiles.length - 1) {
        await Future.delayed(Duration(milliseconds: 100));
      }
    }

    return results;
  }

  /// Clean up old meal photo temporary files
  static Future<void> cleanupOldMealPhotos() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();

      final now = DateTime.now();
      final threeDaysAgo = now.subtract(Duration(days: 3));

      int deletedCount = 0;

      for (final file in files) {
        if (file is File && file.path.contains('meal_')) {
          final stat = file.statSync();
          if (stat.modified.isBefore(threeDaysAgo)) {
            await file.delete();
            deletedCount++;
          }
        }
      }

      if (deletedCount > 0) {
        print('Cleaned up $deletedCount old meal photo(s)');
      }
    } catch (e) {
      print('Error cleaning up old meal photos: $e');
    }
  }

  /// Get compression statistics for a file
  static Future<Map<String, dynamic>?> getCompressionStats(
      File originalFile,
      File compressedFile,
      ) async {
    try {
      final originalSize = originalFile.lengthSync();
      final compressedSize = compressedFile.lengthSync();
      final compressionRatio = originalSize / compressedSize;
      final savedBytes = originalSize - compressedSize;
      final savedPercentage = ((savedBytes / originalSize) * 100);

      return {
        'originalSize': originalSize,
        'compressedSize': compressedSize,
        'originalFormatted': ImageHelper.formatFileSize(originalSize),
        'compressedFormatted': ImageHelper.formatFileSize(compressedSize),
        'compressionRatio': compressionRatio,
        'savedBytes': savedBytes,
        'savedPercentage': savedPercentage,
        'withinLimit': compressedSize <= maxMealPhotoSize,
      };
    } catch (e) {
      print('Error getting compression stats: $e');
      return null;
    }
  }

  /// Estimate if image will need compression
  static bool needsCompression(File imageFile) {
    try {
      return imageFile.lengthSync() > maxMealPhotoSize;
    } catch (e) {
      return true; // Assume needs compression if can't check
    }
  }

  /// Get max allowed size in bytes
  static int getMaxSize() => maxMealPhotoSize;

  /// Get max allowed size in MB
  static double getMaxSizeInMB() => maxMealPhotoSize / (1024 * 1024);

  /// Get target resolution
  static int getTargetResolution() => targetResolution;
}