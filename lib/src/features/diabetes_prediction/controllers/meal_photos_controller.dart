import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Model for meal photo data
class MealPhoto {
  final String originalPath;
  final String? processedPath;
  final int originalSize;
  final int? processedSize;
  final DateTime uploadTime;
  final bool isProcessing;

  MealPhoto({
    required this.originalPath,
    this.processedPath,
    required this.originalSize,
    this.processedSize,
    required this.uploadTime,
    this.isProcessing = false,
  });

  MealPhoto copyWith({
    String? originalPath,
    String? processedPath,
    int? originalSize,
    int? processedSize,
    DateTime? uploadTime,
    bool? isProcessing,
  }) {
    return MealPhoto(
      originalPath: originalPath ?? this.originalPath,
      processedPath: processedPath ?? this.processedPath,
      originalSize: originalSize ?? this.originalSize,
      processedSize: processedSize ?? this.processedSize,
      uploadTime: uploadTime ?? this.uploadTime,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }

  String getSizeFormatted() {
    final size = processedSize ?? originalSize;
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

/// Controller for managing meal photos upload and processing
class MealPhotosController extends GetxController {
  static MealPhotosController get instance => Get.find();

  // Image picker instance
  final ImagePicker _picker = ImagePicker();

  // Meal photos list
  final mealPhotos = <MealPhoto>[].obs;

  // Validation and processing states
  final isProcessing = false.obs;
  final isProcessingAPI = false.obs;
  final apiProcessed = false.obs;
  final apiError = ''.obs;
  final validationErrors = <String>[].obs;

  // Configuration constants
  static const int minPhotos = 7;
  static const int maxPhotos = 9;
  static const int maxTotalSizeMB = 10;
  static const int targetSize = 250;
  static const int maxFileSizeMB = 5;

  static const List<String> supportedFormats = ['jpg', 'jpeg', 'png'];

  @override
  void onInit() {
    super.onInit();
    // Clear any existing data
    resetData();
  }

  /// Check if assessment can be completed
  bool get canCompleteAssessment =>
      apiProcessed.value &&
          mealPhotos.length >= minPhotos &&
          !hasValidationErrors;

  /// Check if there are validation errors
  bool get hasValidationErrors => validationErrors.isNotEmpty;

  /// Pick single image from camera or gallery
  Future<void> pickImage(ImageSource source) async {
    try {
      if (mealPhotos.length >= maxPhotos) {
        _showError('Maximum $maxPhotos photos allowed');
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        await _processSelectedImage(image);
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  /// Pick multiple images from gallery
  Future<void> pickMultipleImages() async {
    try {
      final remainingSlots = maxPhotos - mealPhotos.length;
      if (remainingSlots <= 0) {
        _showError('Maximum $maxPhotos photos allowed');
        return;
      }

      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        final selectedImages = images.take(remainingSlots).toList();

        if (images.length > remainingSlots) {
          _showWarning(
              'Only first $remainingSlots photos selected due to limit');
        }

        for (final image in selectedImages) {
          await _processSelectedImage(image);
        }
      }
    } catch (e) {
      _showError('Failed to pick images: $e');
    }
  }

  /// Process selected image
  Future<void> _processSelectedImage(XFile image) async {
    try {
      isProcessing.value = true;

      // Validate file format
      final extension = path.extension(image.path).toLowerCase().replaceAll(
          '.', '');
      if (!supportedFormats.contains(extension)) {
        _showError('Unsupported format: $extension');
        return;
      }

      // Get file info
      final file = File(image.path);
      final fileSize = await file.length();

      // Validate file size
      if (fileSize > maxFileSizeMB * 1024 * 1024) {
        _showError(
            'File too large: ${(fileSize / (1024 * 1024)).toStringAsFixed(
                1)}MB (max: ${maxFileSizeMB}MB)');
        return;
      }

      // Create initial photo object
      final photo = MealPhoto(
        originalPath: image.path,
        originalSize: fileSize,
        uploadTime: DateTime.now(),
        isProcessing: true,
      );

      mealPhotos.add(photo);
      _validatePhotos();

      // Process image (resize and convert to webp)
      final processedPhoto = await _processImage(photo);

      // Update the photo in list
      final index = mealPhotos.indexWhere((p) =>
      p.originalPath == photo.originalPath);
      if (index != -1) {
        mealPhotos[index] = processedPhoto;
      }

      _validatePhotos();
    } catch (e) {
      _showError('Failed to process image: $e');
    } finally {
      isProcessing.value = false;
    }
  }

  /// Process image (resize and convert to WebP)
  Future<MealPhoto> _processImage(MealPhoto photo) async {
    try {
      // Read original image
      final originalFile = File(photo.originalPath);
      final bytes = await originalFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize image to target size while maintaining aspect ratio
      final resized = img.copyResize(
        image,
        width: targetSize,
        height: targetSize,
        maintainAspect: true,
      );

      // Convert to WebP format
      final webpBytes = img.encodeJpg(resized, quality: 80);

      // Save processed image
      final directory = await getTemporaryDirectory();
      final fileName = 'meal_${DateTime
          .now()
          .millisecondsSinceEpoch}.webp';
      final processedFile = File(path.join(directory.path, fileName));
      await processedFile.writeAsBytes(webpBytes);

      return photo.copyWith(
        processedPath: processedFile.path,
        processedSize: webpBytes.length,
        isProcessing: false,
      );
    } catch (e) {
      throw Exception('Image processing failed: $e');
    }
  }

  /// Remove photo by index
  void removePhoto(int index) {
    if (index >= 0 && index < mealPhotos.length) {
      final photo = mealPhotos[index];

      // Delete processed file if exists
      if (photo.processedPath != null) {
        final processedFile = File(photo.processedPath!);
        if (processedFile.existsSync()) {
          processedFile.deleteSync();
        }
      }

      mealPhotos.removeAt(index);
      _validatePhotos();

      // Reset API status if needed
      if (apiProcessed.value) {
        apiProcessed.value = false;
        apiError.value = '';
      }
    }
  }

  /// Validate all photos and update validation errors
  void _validatePhotos() {
    validationErrors.clear();

    // Check minimum photos
    if (mealPhotos.length < minPhotos) {
      validationErrors.add(
          'Need at least $minPhotos photos (currently: ${mealPhotos.length})');
    }

    // Check maximum photos
    if (mealPhotos.length > maxPhotos) {
      validationErrors.add(
          'Too many photos (max: $maxPhotos, current: ${mealPhotos.length})');
    }

    // Check total size
    final totalSizeMB = getTotalSizeInMB();
    if (totalSizeMB > maxTotalSizeMB) {
      validationErrors.add('Total size too large: ${totalSizeMB.toStringAsFixed(
          1)}MB (max: ${maxTotalSizeMB}MB)');
    }

    // Check for processing images
    final processingCount = mealPhotos
        .where((photo) => photo.isProcessing)
        .length;
    if (processingCount > 0) {
      validationErrors.add('$processingCount photos still processing...');
    }

    // Check for old photos (past 3 days)
    final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
    final oldPhotosCount = mealPhotos
        .where((photo) => photo.uploadTime.isBefore(threeDaysAgo))
        .length;
    if (oldPhotosCount > 0) {
      validationErrors.add('$oldPhotosCount photos are older than 3 days');
    }
  }

  /// Get total size of all photos in MB
  double getTotalSizeInMB() {
    int totalBytes = 0;
    for (final photo in mealPhotos) {
      totalBytes += photo.processedSize ?? photo.originalSize;
    }
    return totalBytes / (1024 * 1024);
  }

  /// Get formatted total size string
  String getTotalSizeFormatted() {
    final totalSizeMB = getTotalSizeInMB();
    if (totalSizeMB < 1) {
      return '${(totalSizeMB * 1024).toStringAsFixed(0)}KB';
    }
    return '${totalSizeMB.toStringAsFixed(1)}MB';
  }

  /// Process photos with API
  Future<void> processPhotosWithAPI() async {
    try {
      // Validate before processing
      _validatePhotos();
      if (hasValidationErrors) {
        _showError('Please fix validation errors before processing');
        return;
      }

      isProcessingAPI.value = true;
      apiError.value = '';

      // Prepare photos for API
      final List<Map<String, dynamic>> photoData = [];

      for (int i = 0; i < mealPhotos.length; i++) {
        final photo = mealPhotos[i];
        final filePath = photo.processedPath ?? photo.originalPath;
        final file = File(filePath);

        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          photoData.add({
            'id': i,
            'filename': 'meal_$i.webp',
            'data': bytes,
            'size': bytes.length,
            'uploadTime': photo.uploadTime.toIso8601String(),
          });
        }
      }

      // Simulate API call (replace with actual API call)
      final result = await _callNutritionAPI(photoData);

      if (result['success']) {
        apiProcessed.value = true;
        Get.snackbar(
          'Success',
          'Photos processed successfully!',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        throw Exception(result['error'] ?? 'API processing failed');
      }
    } catch (e) {
      apiError.value = 'Failed to process photos: $e';
      _showError(apiError.value);
    } finally {
      isProcessingAPI.value = false;
    }
  }

  /// Simulate API call for nutrition analysis
  Future<Map<String, dynamic>> _callNutritionAPI(
      List<Map<String, dynamic>> photoData) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 3));

    // Simulate random success/failure for demo
    // In real implementation, this would be actual API call
    if (photoData.length >= minPhotos) {
      return {
        'success': true,
        'data': {
          'totalMeals': photoData.length,
          'nutritionAnalysis': {
            'totalCalories': 2150,
            'avgCaloriesPerMeal': 2150 / photoData.length,
            'macronutrients': {
              'carbs': 45.2,
              'protein': 25.8,
              'fat': 29.0,
            },
            'riskFactors': [
              'High sodium content detected in 3 meals',
              'Low fiber intake observed',
              'Excessive sugar in beverages',
            ],
          },
          'processedAt': DateTime.now().toIso8601String(),
        }
      };
    } else {
      return {
        'success': false,
        'error': 'Insufficient photos for analysis'
      };
    }
  }

  /// Complete the assessment
  Future<void> completeAssessment() async {
    try {
      if (!canCompleteAssessment) {
        _showError(
            'Cannot complete assessment. Please ensure all requirements are met.');
        return;
      }

      isProcessingAPI.value = true;

      // Prepare final data
      final assessmentData = {
        'mealPhotos': {
          'totalPhotos': mealPhotos.length,
          'totalSizeMB': getTotalSizeInMB(),
          'photos': mealPhotos.map((photo) =>
          {
            'originalSize': photo.originalSize,
            'processedSize': photo.processedSize ?? photo.originalSize,
            'uploadTime': photo.uploadTime.toIso8601String(),
          }).toList(),
        },
        'apiProcessed': apiProcessed.value,
        'completedAt': DateTime.now().toIso8601String(),
      };

      // Simulate final processing
      await Future.delayed(const Duration(seconds: 2));

      print('Assessment Data: $assessmentData'); // For debugging

      // Navigate to results or next screen
      Get.snackbar(
        'Assessment Complete!',
        'Your diabetes risk assessment has been completed successfully.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Clean up temporary files
      await _cleanupTempFiles();

      // Navigate to results screen
      // Get.toNamed('/assessment-results', arguments: assessmentData);
      Get.back(); // For now, just go back

    } catch (e) {
      _showError('Failed to complete assessment: $e');
    } finally {
      isProcessingAPI.value = false;
    }
  }

  /// Clean up temporary processed files
  Future<void> _cleanupTempFiles() async {
    try {
      for (final photo in mealPhotos) {
        if (photo.processedPath != null) {
          final file = File(photo.processedPath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      print('Warning: Failed to cleanup temp files: $e');
    }
  }

  /// Show error message
  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  /// Show warning message
  void _showWarning(String message) {
    Get.snackbar(
      'Warning',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  /// Reset all data
  void resetData() {
    mealPhotos.clear();
    validationErrors.clear();
    isProcessing.value = false;
    isProcessingAPI.value = false;
    apiProcessed.value = false;
    apiError.value = '';
  }

  /// Get data for final submission
  Map<String, dynamic> toJson() {
    return {
      'totalPhotos': mealPhotos.length,
      'totalSizeMB': getTotalSizeInMB(),
      'apiProcessed': apiProcessed.value,
      'validationPassed': !hasValidationErrors,
      'uploadedAt': DateTime.now().toIso8601String(),
    };
  }

  @override
  void onClose() {
    // Clean up when controller is disposed
    _cleanupTempFiles();
    super.onClose();
  }
}