import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../common/loaders/loaders.dart';
import '../../../utils/helpers/image_helper.dart';
import '../../../utils/helpers/meal_photo_helper.dart';
import '../models/diet_assessment_report_model.dart';
import '../models/meal_analysis_result_model.dart';
import '../models/meal_photo_record_model.dart';
import '../../../services/diabetes_hive_storage_manager.dart';
import '../views/diabetes_input/widgets/diabetes_prediction_input_screen.dart';

class MealPhotosController extends GetxController {
  static MealPhotosController get instance => Get.find();

  final DiabetesHiveStorageManager _storageManager = DiabetesHiveStorageManager.instance;
  final _functions = FirebaseFunctions.instance;

  // Observable variables
  final mealPhotos = <MealPhotoRecord>[].obs;
  final isProcessing = false.obs;
  final isProcessingAPI = false.obs;
  final dietAssessment = Rx<DietAssessmentReport?>(null);
  final validationErrors = <String>[].obs;
  final Rx<NavigationMode> navigationMode = NavigationMode.flow.obs;

  // Configuration
  static const int minPhotos = 7;
  static const int maxPhotos = 9;
  static const int maxDaysOld = 3;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  /// Initialize controller
  Future<void> _initialize() async {
    // Get navigation mode from arguments if provided
    if (Get.arguments != null && Get.arguments['mode'] != null) {
      navigationMode.value = Get.arguments['mode'];
    }

    await _loadFromCache();
  }

  /// Load meal photos and results from Hive cache
  Future<void> _loadFromCache() async {
    try {
      final cache = _storageManager.getCachedAssessment();

      if (cache != null) {
        // Load meal photos
        if (cache.mealPhotos != null) {
          // Validate photos still exist
          final validPhotos = <MealPhotoRecord>[];
          final threeDaysAgo = DateTime.now().subtract(Duration(days: maxDaysOld));

          for (final photo in cache.mealPhotos!) {
            final file = File(photo.localPath);
            if (file.existsSync() && photo.uploadTime.isAfter(threeDaysAgo)) {
              validPhotos.add(photo);
            }
          }

          mealPhotos.value = validPhotos;

          // If some photos were removed, update cache
          if (validPhotos.length != cache.mealPhotos!.length) {
            await _saveToCache();
          }
        }

        // Load diet assessment
        dietAssessment.value = cache.dietAssessment;

        _validatePhotos();
      }
    } catch (e) {
      print('Error loading from cache: $e');
    }
  }

  /// Save meal photos and results to Hive cache
  Future<void> _saveToCache() async {
    try {
      // 自动判断是否完成：照片数量足够 + 全部已处理 + 有评估结果
      final bool shouldMarkComplete =
          mealPhotos.length >= minPhotos &&
              allPhotosProcessed &&
              dietAssessment.value != null;

      await _storageManager.updateStepData(8, {
        'mealPhotos': mealPhotos.toList(),
        'mealPhotosProcessed': allPhotosProcessed,
        'dietAssessment': dietAssessment.value,
      }, markComplete: shouldMarkComplete);
    } catch (e) {
      print('Error saving to cache: $e');
    }
  }

  void _validatePhotos() {
    validationErrors.clear();

    if (mealPhotos.length < minPhotos) {
      validationErrors.add(
        'Need at least $minPhotos photos (currently: ${mealPhotos.length})',
      );
    }

    final threeDaysAgo = DateTime.now().subtract(Duration(days: maxDaysOld));
    final oldPhotos = mealPhotos.where((p) => p.uploadTime.isBefore(threeDaysAgo)).length;

    if (oldPhotos > 0) {
      validationErrors.add('$oldPhotos photos are older than $maxDaysOld days');
    }
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      if (mealPhotos.length >= maxPhotos) {
        TLoaders.errorSnackBar(
          title: 'Limit Reached',
          message: 'Maximum $maxPhotos photos allowed',
        );
        return;
      }

      isProcessing.value = true;

      File? image;
      if (source == ImageSource.camera) {
        image = await ImageHelper.openCustomCamera();
      } else {
        image = await ImageHelper.pickImage();
      }

      if (image != null) {
        await _processAndSaveImage(image);
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Error', message: 'Failed to pick image: $e');
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> pickMultipleImages() async {
    try {
      final remainingSlots = maxPhotos - mealPhotos.length;
      if (remainingSlots <= 0) {
        TLoaders.errorSnackBar(
          title: 'Limit Reached',
          message: 'Maximum $maxPhotos photos allowed',
        );
        return;
      }

      isProcessing.value = true;
      final images = await ImageHelper.pickMultipleMedia(limit: remainingSlots);

      if (images.isNotEmpty) {
        if (images.length > remainingSlots) {
          TLoaders.warningSnackBar(
            title: 'Notice',
            message: 'Only first $remainingSlots photos will be added',
          );
        }

        for (final image in images.take(remainingSlots)) {
          if (ImageHelper.isImageFile(image.path)) {
            await _processAndSaveImage(image);
          }
        }
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Error', message: 'Failed to pick images: $e');
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> _processAndSaveImage(File imageFile) async {
    try {
      final processedFile = await MealPhotoHelper.compressImageForMealPhoto(imageFile);

      if (processedFile == null) {
        throw Exception('Failed to process image');
      }

      if (!MealPhotoHelper.isMealPhotoSizeValid(processedFile)) {
        final sizeMB = MealPhotoHelper.getSizeInMB(processedFile);
        TLoaders.errorSnackBar(
          title: 'File Too Large',
          message: 'Image must be less than 1MB (current: ${sizeMB.toStringAsFixed(2)}MB)',
        );
        return;
      }

      final photo = MealPhotoRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        localPath: processedFile.path,
        fileSize: processedFile.lengthSync(),
        uploadTime: DateTime.now(),
        needsProcessing: true, // Mark as needing processing
      );

      mealPhotos.add(photo);

      await _saveToCache();
      _validatePhotos();

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Photo added (${MealPhotoHelper.getFormattedSize(processedFile)})',
      );
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Error', message: 'Failed to process image: $e');
    }
  }

  Future<void> removePhoto(int index) async {
    if (index >= 0 && index < mealPhotos.length) {
      final photo = mealPhotos[index];

      try {
        final file = File(photo.localPath);
        if (file.existsSync()) {
          await file.delete();
        }
      } catch (e) {
        print('Error deleting file: $e');
      }

      mealPhotos.removeAt(index);

      // If we removed a processed photo and have other processed photos,
      // recalculate the diet assessment
      if (!photo.needsProcessing && hasProcessedPhotos) {
        await _recalculateAssessment();
      } else {
        // If all unprocessed or no photos left, clear assessment
        if (mealPhotos.isEmpty || !hasProcessedPhotos) {
          dietAssessment.value = null;
        }
      }

      await _saveToCache();
      _validatePhotos();
    }
  }

  /// Process only unprocessed photos with Cloud Function
  Future<void> processPhotosWithAPI() async {
    try {
      _validatePhotos();
      if (hasValidationErrors) {
        TLoaders.errorSnackBar(
          title: 'Validation Error',
          message: 'Please fix validation errors before processing',
        );
        return;
      }

      final unprocessedPhotos = mealPhotos.where((p) => p.needsProcessing).toList();

      if (unprocessedPhotos.isEmpty) {
        TLoaders.warningSnackBar(
          title: 'Already Processed',
          message: 'All photos have been processed',
        );
        return;
      }

      isProcessingAPI.value = true;

      // Prepare only unprocessed images as base64
      final images = <Map<String, dynamic>>[];
      for (final photo in unprocessedPhotos) {
        final file = File(photo.localPath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final base64Image = base64Encode(bytes);
          images.add({
            'id': photo.id,
            'image_b64': base64Image,
          });
        }
      }

      if (images.isEmpty) {
        throw Exception('No valid images to process');
      }

      // Call cloud function
      final callable = _functions.httpsCallable('analyzeMealPhotos');
      final result = await callable.call({'images': images});

      final data = result.data;
      if (data['success'] == true) {
        // Update each newly processed photo with its analysis result
        for (int i = 0; i < mealPhotos.length; i++) {
          if (mealPhotos[i].needsProcessing) {
            final analysisResult = (data['nutritionData']['meals'] as List)
                .firstWhere(
                  (m) => m['id'] == mealPhotos[i].id,
              orElse: () => throw Exception('Analysis result not found'),
            );

            mealPhotos[i] = mealPhotos[i].copyWith(
              needsProcessing: false,
              analysisResult: MealAnalysisResult.fromJson(analysisResult),
            );
          }
        }

        // Recalculate complete diet assessment from all processed photos
        await _recalculateAssessment();

        // Save to Hive cache
        await _saveToCache();

        TLoaders.successSnackBar(
          title: 'Success',
          message: 'Photos analyzed successfully!',
        );
      } else {
        throw Exception(data['error'] ?? 'API processing failed');
      }
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Processing Failed',
        message: e.toString(),
      );
    } finally {
      isProcessingAPI.value = false;
    }
  }

  /// Recalculate diet assessment from all processed photos
  Future<void> _recalculateAssessment() async {
    final processedPhotos = mealPhotos.where((p) => !p.needsProcessing && p.analysisResult != null).toList();

    if (processedPhotos.isEmpty) {
      dietAssessment.value = null;
      await _saveToCache();
      return;
    }

    // Extract all meal analysis results
    final meals = processedPhotos
        .map((p) => p.analysisResult!)
        .toList();

    // Calculate average GL
    final totalGL = meals.fold(0.0, (sum, meal) => sum + meal.totalGL);
    final avgGL = totalGL / meals.length;

    // Determine health status
    final highGLCount = meals.where((m) => m.glCategory == 'high').length;
    final isHealthy = avgGL < 15 && highGLCount < (meals.length * 0.3);

    // Generate warnings
    final warnings = <String>[];
    if (avgGL >= 15) {
      warnings.add('Average GL is high - consider lower GL foods');
    }
    if (highGLCount > meals.length * 0.3) {
      warnings.add('Too many high GL meals detected');
    }

    // Create new assessment
    dietAssessment.value = DietAssessmentReport(
      meals: meals,
      avgGLPerMeal: avgGL,
      isHealthy: isHealthy,
      warnings: warnings,
      mealCount: meals.length,
      glThresholds: {
        'low': 10,
        'medium': 20,
        'high': 20,
      },
      assessmentDate: DateTime.now(),
    );

    await _saveToCache();
  }

  Future<void> completeAssessment() async {
    if (!canProceed) {
      TLoaders.errorSnackBar(
        title: 'Cannot Complete',
        message: 'Please process all photos before completing',
      );
      return;
    }

    TLoaders.successSnackBar(
      title: 'Assessment Complete',
      message: 'Your meal photos have been analyzed',
    );

    Get.back();
  }

  Future<void> resetData() async {
    // Delete physical files
    for (final photo in mealPhotos) {
      try {
        final file = File(photo.localPath);
        if (file.existsSync()) {
          await file.delete();
        }
      } catch (e) {
        print('Error deleting file: $e');
      }
    }

    // Clear local state
    mealPhotos.clear();
    validationErrors.clear();
    isProcessing.value = false;
    isProcessingAPI.value = false;
    dietAssessment.value = null;

    // Clear from cache
    await _storageManager.updateStepData(8, {
      'mealPhotos': <MealPhotoRecord>[],
      'mealPhotosProcessed': false,
      'dietAssessment': null,
    });
  }

  // Getters
  bool get hasValidationErrors => validationErrors.isNotEmpty;

  /// Check if there are any unprocessed photos
  bool get hasUnprocessedPhotos => mealPhotos.any((p) => p.needsProcessing);

  /// Check if all photos are processed
  bool get allPhotosProcessed => mealPhotos.isNotEmpty && !hasUnprocessedPhotos;

  /// Check if there are any processed photos
  bool get hasProcessedPhotos => mealPhotos.any((p) => !p.needsProcessing);

  /// Get count of processed photos
  int get processedCount => mealPhotos.where((p) => !p.needsProcessing).length;

  /// Get count of unprocessed photos
  int get unprocessedCount => mealPhotos.where((p) => p.needsProcessing).length;

  /// Check if needs processing (has unprocessed photos)
  bool get needsProcessing => hasUnprocessedPhotos;

  /// Check if can proceed to next step
  bool get canProceed =>
      !hasValidationErrors &&
          mealPhotos.length >= minPhotos &&
          allPhotosProcessed;

  /// 检查是否可以处理照片（有未处理照片时才enable）
  bool get canProcessPhotos => hasUnprocessedPhotos && !isProcessingAPI.value;

  /// 检查是否可以继续/保存（全部处理完成且照片数量符合要求）
  bool get canContinueOrSave =>
      !hasValidationErrors &&
          mealPhotos.length >= minPhotos &&
          allPhotosProcessed;

  /// 获取按钮文本
  String get continueButtonText {
    if (shouldShowProcessButton) {
      return 'Process Photos';
    } else {
      return navigationMode == NavigationMode.edit ? 'Save' : 'Continue';
    }
  }

  bool get shouldShowProcessButton {
    return hasUnprocessedPhotos || mealPhotos.length < minPhotos || hasValidationErrors;
  }

  String getTotalSizeFormatted() {
    final totalBytes = mealPhotos.fold<int>(0, (sum, p) => sum + p.fileSize);
    return ImageHelper.formatFileSize(totalBytes);
  }

  @override
  void onClose() {
    super.onClose();
  }
}