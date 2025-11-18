import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart' hide NavigationMode;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../common/loaders/loaders.dart';
import '../../../common/widgets/dialogs/dialog.dart';
import '../../../utils/helpers/image_helper.dart';
import '../../../utils/helpers/meal_photo_helper.dart';
import '../models/diet_assessment_report_model.dart';
import '../models/meal_analysis_result_model.dart';
import '../models/meal_photo_record_model.dart';
import '../../../services/diabetes_hive_storage_manager.dart';
import '../views/diabetes_input/diabetes_prediction_overview_screen.dart';
import '../views/diabetes_input/widgets/diabetes_prediction_input_screen.dart';

/// 图片处理结果类
class ImageProcessResult {
  final bool success;
  final String? fileSize;
  final String? errorMessage;

  ImageProcessResult({
    required this.success,
    this.fileSize,
    this.errorMessage,
  });
}

/// 批量上传结果类
class BatchUploadResult {
  final int successCount;
  final int failureCount;
  final int sizeErrorCount; // 文件大小错误数量
  final List<String> otherErrors; // 其他错误信息

  BatchUploadResult({
    required this.successCount,
    required this.failureCount,
    required this.sizeErrorCount,
    required this.otherErrors,
  });
}

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
  static const int _minPhotos = 1;
  static const int _maxPhotos = 9;
  static const int maxDaysOld = 3;

  // Public getter for UI access
  int get maxPhotos => _maxPhotos;
  int get minPhotos => _minPhotos;

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
        print('📦 Loading meal photos from cache...');

        // Load meal photos
        if (cache.mealPhotos != null) {
          // Validate photos still exist
          final validPhotos = <MealPhotoRecord>[];
          final threeDaysAgo = DateTime.now().subtract(Duration(days: maxDaysOld));

          for (final photo in cache.mealPhotos!) {
            final file = File(photo.imagePath);
            if (file.existsSync() && photo.uploadTime.isAfter(threeDaysAgo)) {
              validPhotos.add(photo);
              print('Loaded photo: ${photo.id}, processed: ${!photo.needsProcessing}');
            } else {
              print('Photo expired or file not found: ${photo.id}');
            }
          }

          mealPhotos.value = validPhotos;
          print('📊 Total valid photos loaded: ${validPhotos.length}');

          // 🔥 CRITICAL FIX: Only load diet assessment if we have processed photos
          if (validPhotos.any((p) => !p.needsProcessing)) {
            dietAssessment.value = cache.dietAssessment;
            if (dietAssessment.value != null) {
              print('Loaded diet assessment with ${dietAssessment.value!.mealCount} meals');
            }
          } else {
            // No processed photos, clear assessment
            print('No processed photos found, clearing assessment');
            dietAssessment.value = null;
          }

          // If some photos were removed, update cache
          if (validPhotos.length != cache.mealPhotos!.length) {
            print('Updating cache with valid photos only');
            await _saveToCache();
          }
        } else {
          // No photos in cache
          print('No photos in cache');
          mealPhotos.clear();
          dietAssessment.value = null;
        }

        _validatePhotos();
      } else {
        print('No cached assessment found');
        mealPhotos.clear();
        dietAssessment.value = null;
      }
    } catch (e) {
      print('Error loading from cache: $e');
    }
  }

  /// Save meal photos and results to Hive cache
  Future<void> _saveToCache() async {
    try {
      print('💾 Saving to cache...');
      print('   Photos: ${mealPhotos.length}');
      print('   All processed: $allPhotosProcessed');
      print('   Has assessment: ${dietAssessment.value != null}');

      // This prevents stale assessment data from being saved
      if (mealPhotos.isEmpty || !hasProcessedPhotos) {
        print('   Force clearing assessment - no valid processed photos');
        dietAssessment.value = null;
      }

      // 1. 照片数量在 minPhotos 和 maxPhotos 之间
      // 2. 所有照片都已处理完成
      // 3. 必须有 diet assessment 结果
      final bool hasValidPhotoCount = mealPhotos.length >= minPhotos && mealPhotos.length <= maxPhotos;
      final bool allProcessed = mealPhotos.isNotEmpty && allPhotosProcessed;
      final bool hasAssessment = dietAssessment.value != null;
      final bool noErrors = !hasErrorPhotos;
      final bool hasValidPhotos = hasValidProcessedPhotos;

      final bool shouldMarkComplete = hasValidPhotoCount && allProcessed && hasAssessment && noErrors && hasValidPhotos;;

      print('   Should mark complete: $shouldMarkComplete');

      await _storageManager.updateStepData(8, {
        'mealPhotos': mealPhotos.toList(),
        'mealPhotosProcessed': allPhotosProcessed,
        'dietAssessment': dietAssessment.value,
      }, markComplete: shouldMarkComplete);

      print('✅ Cache saved successfully');
    } catch (e) {
      print('❌ Error saving to cache: $e');
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

    if (hasErrorPhotos) {
      validationErrors.add(
        '$errorPhotosCount photo(s) are not food items - please delete them',
      );
    }
  }

  /// 安全转换 Map 类型
  Map<String, dynamic> _convertMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is Map) {
      return data.map<String, dynamic>((key, value) {
        final convertedKey = key?.toString() ?? '';
        final convertedValue = _convertValue(value);
        return MapEntry(convertedKey, convertedValue);
      });
    }
    return {};
  }

  /// 安全转换 List 类型
  List<dynamic> _convertList(dynamic data) {
    if (data is List<dynamic>) {
      return data.map(_convertValue).toList();
    } else if (data is List) {
      return data.map(_convertValue).toList();
    }
    return [];
  }

  /// 递归转换值
  dynamic _convertValue(dynamic value) {
    if (value is Map) {
      return _convertMap(value);
    } else if (value is List) {
      return _convertList(value);
    } else if (value is num) {
      return value.toDouble();
    }
    return value;
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      if (mealPhotos.length >= _maxPhotos) {
        TLoaders.errorSnackBar(
          title: 'Limit Reached',
          message: 'Maximum $_maxPhotos photos allowed',
        );
        return;
      }

      isProcessing.value = true;

      File? image;
      if (source == ImageSource.camera) {
        image = await ImageHelper.takePhoto();
      } else {
        image = await ImageHelper.pickImage();
      }

      if (image != null) {
        final result = await _processAndSaveImage(image);
        if (result.success) {
          TLoaders.successSnackBar(
            title: 'Success',
            message: 'Photo added (${result.fileSize})',
          );
        } else {
          TLoaders.errorSnackBar(
            title: 'Error',
            message: result.errorMessage ?? 'Failed to process image',
          );
        }
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

        // 批量处理图片并统计结果
        final results = await _processMultipleImages(images.take(remainingSlots).toList());

        // 根据处理结果显示相应的 SnackBar
        _showBatchUploadResult(results);
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Error', message: 'Failed to pick images: $e');
    } finally {
      isProcessing.value = false;
    }
  }

  /// 批量处理多个图片并返回处理结果
  Future<BatchUploadResult> _processMultipleImages(List<File> images) async {
    int successCount = 0;
    int failureCount = 0;
    int sizeErrorCount = 0; // 专门统计文件大小错误的次数
    List<String> otherErrors = []; // 其他错误信息

    for (final image in images) {
      if (!ImageHelper.isImageFile(image.path)) {
        failureCount++;
        otherErrors.add('Invalid image file');
        continue;
      }

      final result = await _processAndSaveImage(image);

      if (result.success) {
        successCount++;
      } else {
        failureCount++;

        // 分类统计错误类型
        if (result.errorMessage?.contains('less than 1MB') == true) {
          sizeErrorCount++;
        } else {
          otherErrors.add(result.errorMessage ?? 'Unknown error');
        }
      }
    }

    return BatchUploadResult(
      successCount: successCount,
      failureCount: failureCount,
      sizeErrorCount: sizeErrorCount,
      otherErrors: otherErrors,
    );
  }

  /// 显示批量上传结果
  void _showBatchUploadResult(BatchUploadResult results) {
    final total = results.successCount + results.failureCount;

    if (results.successCount == total) {
      // 全部成功
      TLoaders.successSnackBar(
        title: 'Upload Successful',
        message: 'All $total photos added successfully',
      );
    } else if (results.successCount > 0 && results.failureCount > 0) {
      // 部分成功 - 简化错误信息
      String message = '${results.successCount} of $total photos added successfully.';

      if (results.sizeErrorCount > 0) {
        message += ' ${results.sizeErrorCount} photo(s) were too large.';
      }

      if (results.otherErrors.isNotEmpty) {
        message += ' ${results.otherErrors.length} photo(s) failed to process.';
      }

      TLoaders.warningSnackBar(
        title: 'Partial Upload',
        message: message,
      );
    } else {
      // 全部失败 - 简化错误信息
      String message = 'Failed to add all $total photos.';

      if (results.sizeErrorCount > 0) {
        message += ' ${results.sizeErrorCount} photo(s) were too large.';
      }

      if (results.otherErrors.isNotEmpty) {
        message += ' ${results.otherErrors.length} photo(s) failed to process.';
      }

      TLoaders.errorSnackBar(
        title: 'Upload Failed',
        message: message,
      );
    }
  }

  /// 处理并保存图片，返回处理结果
  Future<ImageProcessResult> _processAndSaveImage(File imageFile) async {
    try {
      final processedFile = await MealPhotoHelper.compressImageForMealPhoto(imageFile);

      if (processedFile == null) {
        return ImageProcessResult(
          success: false,
          errorMessage: 'Failed to process image',
        );
      }

      if (!MealPhotoHelper.isMealPhotoSizeValid(processedFile)) {
        final sizeMB = MealPhotoHelper.getSizeInMB(processedFile);
        return ImageProcessResult(
          success: false,
          errorMessage: 'Image must be less than 1MB (current: ${sizeMB.toStringAsFixed(2)}MB)',
        );
      }

      final photo = MealPhotoRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imagePath: processedFile.path,
        fileSize: processedFile.lengthSync(),
        uploadTime: DateTime.now(),
        needsProcessing: true,
      );

      mealPhotos.add(photo);
      await _saveToCache();
      _validatePhotos();

      return ImageProcessResult(
        success: true,
        fileSize: MealPhotoHelper.getFormattedSize(processedFile),
      );
    } catch (e) {
      return ImageProcessResult(
        success: false,
        errorMessage: 'Failed to process image: $e',
      );
    }
  }

  Future<void> removePhoto(int index) async {
    if (index >= 0 && index < mealPhotos.length) {
      final photo = mealPhotos[index];

      // 根据照片是否已处理显示不同的确认对话框
      if (photo.needsProcessing) {
        // 未处理的照片直接删除
        await _performPhotoRemoval(index, photo);
      } else {
        // 已处理的照片显示确认对话框
        final shouldDelete = await TDialog.deleteDialog(
          title: 'Delete Processed Photo?',
          message: 'This photo has been processed and contains analysis data. Deleting it will remove all associated nutritional information.',
          onConfirm: () async {
            await _performPhotoRemoval(index, photo);
          },
        );

        // 如果用户取消删除，直接返回
        if (shouldDelete != true) return;
      }
    }
  }

  /// 执行实际的照片删除操作
  Future<void> _performPhotoRemoval(int index, MealPhotoRecord photo) async {
    try {
      final file = File(photo.imagePath);
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

    TLoaders.successSnackBar(
      title: 'Photo Deleted',
      message: 'Meal photo has been removed',
    );
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
      print('🔄 Starting API processing for ${unprocessedPhotos.length} photos...');

      // Prepare only unprocessed images as base64
      final images = <Map<String, dynamic>>[];
      for (final photo in unprocessedPhotos) {
        final file = File(photo.imagePath);
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

      print('📤 Calling Cloud Function with ${images.length} images...');

      // Call cloud function
      final callable = _functions.httpsCallable('analyzeMealPhotos');
      final result = await callable.call({'images': images});

      print('📥 Received response from Cloud Function');

      final data = _convertMap(result.data);

      if (data['success'] == true) {
        final nutritionData = _convertMap(data['nutritionData']);
        final meals = _convertList(nutritionData['meals']);

        print('✅ Processing ${meals.length} meal results...');

        // Update each newly processed photo with its analysis result
        for (int i = 0; i < mealPhotos.length; i++) {
          if (mealPhotos[i].needsProcessing) {
            final mealData = meals.firstWhere(
                  (m) => _convertMap(m)['id'] == mealPhotos[i].id,
              orElse: () => null,
            );

            if (mealData != null) {
              final mealMap = _convertMap(mealData);
              mealPhotos[i] = mealPhotos[i].copyWith(
                needsProcessing: false,
                analysisResult: MealAnalysisResult.fromJson(mealMap),
              );
              print('✅ Updated photo ${mealPhotos[i].id} with analysis result');
            }
          }
        }

        // Recalculate complete diet assessment from all processed photos
        print('🔄 Recalculating diet assessment...');
        await _recalculateAssessment();

        // 🔥 CRITICAL: Save to Hive cache AFTER processing
        print('💾 Saving processed results to cache...');
        await _saveToCache();
        print('✅ All results saved to cache');

        TLoaders.successSnackBar(
          title: 'Success',
          message: 'Photos analyzed successfully!',
        );
      } else {
        throw Exception(data['error'] ?? 'API processing failed');
      }
    } catch (e) {
      print('❌ Error in processPhotosWithAPI: $e');
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
      print('ℹ️ No processed photos, clearing assessment');
      dietAssessment.value = null;
      await _saveToCache();
      return;
    }

    print('📊 Recalculating assessment from ${processedPhotos.length} processed photos...');

    // Extract all meal analysis results
    final meals = processedPhotos
        .map((p) => p.analysisResult!)
        .toList();

    // Calculate average GL (only from meals without errors)
    final validMeals = meals.where((m) => !m.hasError && m.totalGL > 0).toList();

    if (validMeals.isEmpty) {
      print('⚠️ No valid meals with GL data');
      dietAssessment.value = null; // 设为 null，不创建空 assessment
      await _saveToCache();
      return;
    }

    final totalGL = validMeals.fold(0.0, (sum, meal) => sum + meal.totalGL);
    final avgGL = totalGL / validMeals.length;

    // Determine health status
    final highGLCount = validMeals.where((m) => m.glCategory == 'high').length;
    final isHealthy = avgGL < 15 && highGLCount < (validMeals.length * 0.3);

    // Generate warnings
    final warnings = <String>[];
    if (avgGL >= 15) {
      warnings.add('Average GL is high - consider lower GL foods');
    }
    if (highGLCount > validMeals.length * 0.3) {
      warnings.add('Too many high GL meals detected');
    }

    final errorCount = meals.where((m) => m.hasError).length;
    if (errorCount > 0) {
      warnings.add('$errorCount photo(s) were not food items and excluded from analysis');
    }

    // Create new assessment
    dietAssessment.value = DietAssessmentReport(
      meals: meals,
      avgGLPerMeal: avgGL,
      isHealthy: isHealthy,
      warnings: warnings,
      mealCount: validMeals.length,
      glThresholds: {
        'low': 10,
        'medium': 20,
        'high': 20,
      },
      assessmentDate: DateTime.now(),
    );

    print('✅ Assessment calculated: avgGL=${avgGL}, healthy=$isHealthy, validMeals=${validMeals.length}');

    await _saveToCache();
  }

  Future<void> completeAssessment() async {
    try {
      if (!canContinueOrSave) {
        TLoaders.errorSnackBar(
          title: 'Cannot Complete',
          message: 'Please ensure all photos are processed and valid before saving',
        );
        return;
      }

      print('💾 Saving meal photos assessment...');

      // 根据模式决定导航行为
      if (navigationMode.value == NavigationMode.edit) {
        TLoaders.successSnackBar(
          title: 'Saved',
          message: 'Meal photos have been updated',
        );

        Get.off(
              () => DiabetesPredictionOverviewScreen(),
          transition: Transition.downToUp,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        Get.to(() => const DiabetesPredictionOverviewScreen());
      }
    } catch (e) {
      print('❌ Error completing assessment: $e');
      TLoaders.errorSnackBar(
        title: 'Save Failed',
        message: 'Failed to save changes: $e',
      );
    }
  }

  Future<void> resetData() async {
    print('🗑️ Resetting all meal photo data...');

    final removedPhotosLength = mealPhotos.length;

    // Delete physical files
    for (final photo in mealPhotos) {
      try {
        final file = File(photo.imagePath);
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
    }, markComplete: false);

    TLoaders.successSnackBar(
      title: 'All Photos Cleared',
      message: '$removedPhotosLength meal photos have been removed',
    );
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

  /// 检查是否有错误照片（已处理但有错误）
  bool get hasErrorPhotos => mealPhotos.any((p) =>
  !p.needsProcessing &&
      p.analysisResult != null &&
      p.analysisResult!.hasError
  );

  /// 获取错误照片数量
  int get errorPhotosCount => mealPhotos.where((p) =>
  !p.needsProcessing &&
      p.analysisResult != null &&
      p.analysisResult!.hasError
  ).length;

  /// 检查是否有有效的处理照片（非错误）
  bool get hasValidProcessedPhotos => mealPhotos.any((p) =>
  !p.needsProcessing &&
      p.analysisResult != null &&
      !p.analysisResult!.hasError
  );

  /// 获取有效处理照片的数量
  int get validProcessedCount => mealPhotos.where((p) =>
  !p.needsProcessing &&
      p.analysisResult != null &&
      !p.analysisResult!.hasError
  ).length;

  /// Check if can proceed to next step
  bool get canProceed =>
      !hasValidationErrors &&
          mealPhotos.length >= minPhotos &&
          mealPhotos.length <= maxPhotos &&
          allPhotosProcessed &&
          !hasErrorPhotos &&
          dietAssessment.value != null;

  /// 检查是否可以处理照片（有未处理照片时才enable）
  bool get canProcessPhotos => hasUnprocessedPhotos && !isProcessingAPI.value;

  /// 检查是否可以继续/保存（全部处理完成且照片数量符合要求）
  bool get canContinueOrSave =>
      !hasValidationErrors &&
          mealPhotos.length >= minPhotos &&
          mealPhotos.length <= maxPhotos &&
          allPhotosProcessed &&
          !hasErrorPhotos &&
          dietAssessment.value != null;

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