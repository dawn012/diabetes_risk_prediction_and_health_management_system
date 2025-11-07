import 'package:flutter/material.dart' hide NavigationMode;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/meal_photos_controller.dart';
import '../../models/meal_analysis_result_model.dart';
import 'widgets/diabetes_prediction_input_screen.dart';

class MealPhotosUploadScreen extends StatelessWidget {
  const MealPhotosUploadScreen({
    super.key,
    this.mode = NavigationMode.flow,
  });

  final NavigationMode mode;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MealPhotosController());
    final darkMode = THelperFunctions.isDarkMode(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.navigationMode.value = mode;
    });

    return Obx(() => DiabetesPredictionInputScreen(
      title: 'Meal Photos',
      progressValue: 8 / 8,
      showBackButton: mode == NavigationMode.flow,
      showCloseButton: mode == NavigationMode.edit,
      navigationMode: mode,
      canProceed: controller.shouldShowProcessButton
          ? controller.canProcessPhotos  // 显示Process时：有未处理照片才enable
          : controller.canContinueOrSave, // 显示Continue/Save时：一切OK才enable
      isLoading: controller.isProcessingAPI.value,
      continueButtonText: controller.continueButtonText,
      onContinue: controller.shouldShowProcessButton
          ? () => controller.processPhotosWithAPI()
          : () => controller.completeAssessment(),
      onSave: mode == NavigationMode.edit && !controller.shouldShowProcessButton
          ? () => controller.completeAssessment()
          : null,
      forceProcessButton: mode == NavigationMode.edit && controller.shouldShowProcessButton,
      onProcess: () => controller.processPhotosWithAPI(),
      content: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            SectionHeader(
              title: 'Upload Recent Meals',
              subtitle: 'Upload 7-9 photos from past 3 days',
              questionNumber: 'STEP 8 OF 8',
              icon: Icons.camera_alt,
              iconColor: Colors.orange,
            ),

            const SizedBox(height: 24),

            // Requirements Card
            _buildRequirementsCard(darkMode),

            const SizedBox(height: 20),

            // Status Card
            _buildStatusCard(controller, darkMode),

            const SizedBox(height: 20),

            // Upload Button
            if (!controller.allPhotosProcessed)
              _buildUploadButton(controller, darkMode),

            if (!controller.allPhotosProcessed)
              const SizedBox(height: 20),

            // Photos Grid
            if (controller.mealPhotos.isNotEmpty)
              _buildPhotosGrid(controller, darkMode)
            else
              _buildEmptyState(darkMode),

            const SizedBox(height: 20),

            // GL Info Card (only show after processing)
            if (controller.hasProcessedPhotos)
              _buildGLInfoCard(darkMode),

            const SizedBox(height: 20),

            // Detailed Results (only show after all processed)
            if (controller.dietAssessment.value != null)
              _buildDetailedResults(
                controller.dietAssessment.value!,
                darkMode,
              ),
          ],
        ),
      ),
    ));
  }

  Widget _buildRequirementsCard(bool darkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Requirements',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _requirementItem('7-9 meal photos', Icons.restaurant),
          _requirementItem('From past 3 days', Icons.calendar_today),
          _requirementItem('Auto-compressed', Icons.image),
          _requirementItem('Max 1MB per photo', Icons.storage),
        ],
      ),
    );
  }

  Widget _requirementItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.blue.withOpacity(0.7)),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.blue.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(MealPhotosController controller, bool darkMode) {
    return Obx(() {
      final hasUnprocessed = controller.hasUnprocessedPhotos;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: darkMode
              ? TColors.darkerGrey.withOpacity(0.3)
              : TColors.softGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: controller.hasValidationErrors
                ? Colors.red.withOpacity(0.5)
                : hasUnprocessed && controller.mealPhotos.length >= 7
                ? Colors.orange.withOpacity(0.5)
                : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statusItem(
                  'Photos',
                  '${controller.mealPhotos.length}/9',
                  controller.mealPhotos.length >= 7
                      ? Colors.green
                      : Colors.orange,
                  darkMode,
                ),
                _statusItem(
                  'Processed',
                  '${controller.processedCount}/${controller.mealPhotos.length}',
                  controller.allPhotosProcessed
                      ? Colors.green
                      : Colors.orange,
                  darkMode,
                ),
                _statusItem(
                  'Size',
                  controller.getTotalSizeFormatted(),
                  Colors.blue,
                  darkMode,
                ),
              ],
            ),

            // Errors
            if (controller.validationErrors.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: controller.validationErrors
                      .map((err) => Text(
                    '• $err',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ))
                      .toList(),
                ),
              ),
            ],

            // Warning
            if (hasUnprocessed &&
                !controller.hasValidationErrors &&
                controller.mealPhotos.length >= 7) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Colors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Click "Process Photos" to analyze ${controller.unprocessedCount} new photo(s)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _statusItem(String label, String value, Color color, bool darkMode) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadButton(MealPhotosController controller, bool darkMode) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: OutlinedButton.icon(
        onPressed: controller.isProcessing.value
            ? null
            : () => _showUploadOptions(controller),
        icon: const Icon(Icons.add_photo_alternate),
        label: const Text(
          'Add Meal Photos',
          style: TextStyle(fontSize: 16),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.orange,
          side: const BorderSide(color: Colors.orange, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotosGrid(MealPhotosController controller, bool darkMode) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Uploaded Photos (${controller.mealPhotos.length})',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: darkMode ? TColors.white : TColors.black,
              ),
            ),
            if (controller.mealPhotos.isNotEmpty)
              TextButton.icon(
                onPressed: () => _showClearConfirmation(controller),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Clear All'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemCount: controller.mealPhotos.length,
          itemBuilder: (context, index) {
            final photo = controller.mealPhotos[index];
            return _buildPhotoCard(photo, index, controller, darkMode);
          },
        ),
      ],
    ));
  }

  Widget _buildPhotoCard(
      dynamic photo,
      int index,
      MealPhotosController controller,
      bool darkMode,
      ) {
    final hasGL = photo.analysisResult != null;
    final glColor = hasGL
        ? photo.analysisResult!.glCategory == 'low'
        ? Colors.green
        : photo.analysisResult!.glCategory == 'medium'
        ? Colors.orange
        : Colors.red
        : Colors.grey;

    return GestureDetector(
      onTap: hasGL
          ? () => _showMealDetails(photo.analysisResult!, darkMode)
          : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: glColor.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(photo.localPath),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            // Processing indicator
            if (photo.needsProcessing)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // GL Badge
            if (hasGL)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: glColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'GL: ${photo.analysisResult!.totalGL.toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Bottom info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Meal ${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (hasGL) ...[
                      Text(
                        '${photo.analysisResult!.foods.length} food(s)',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        photo.analysisResult!.glCategory.toUpperCase(),
                        style: TextStyle(
                          color: glColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else
                      Text(
                        photo.getSizeFormatted(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Delete button
            Positioned(
              top: 8,
              left: 8,
              child: GestureDetector(
                onTap: () => controller.removePhoto(index),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),

            // Tap to view indicator
            if (hasGL)
              Positioned(
                bottom: 60,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGLInfoCard(bool darkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              Text(
                'What is Glycemic Load (GL)?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'GL measures how much a food raises blood sugar levels. It considers both the carb amount and quality.',
            style: TextStyle(
              fontSize: 13,
              color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _glLegend('Low', 'GL < 10', Colors.green),
              const SizedBox(width: 12),
              _glLegend('Medium', 'GL 10-20', Colors.orange),
              const SizedBox(width: 12),
              _glLegend('High', 'GL > 20', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _glLegend(String label, String range, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              range,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedResults(dynamic data, bool darkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: data.isHealthy
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: data.isHealthy
              ? Colors.green.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                data.isHealthy ? Icons.check_circle : Icons.warning_amber,
                color: data.isHealthy ? Colors.green : Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data.isHealthy ? 'Healthy Diet' : 'Needs Improvement',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: data.isHealthy ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _resultRow('Average GL/Meal',
              '${data.avgGLPerMeal.toStringAsFixed(1)}'),
          _resultRow('Total Foods Detected', '${data.totalFoodsDetected}'),
          _resultRow('Low GL Meals',
              '${data.lowGLMealsCount}/${data.mealCount}'),
          _resultRow('High GL Meals',
              '${data.highGLMealsCount}/${data.mealCount}'),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),

          _resultRow('Total Calories', '${data.totalCalories.toInt()} kcal'),
          _resultRow('Total Carbs', '${data.totalCarbs.toInt()}g'),
          _resultRow('Total Sugar', '${data.totalSugar.toInt()}g'),
          _resultRow('Total Fiber', '${data.totalFiber.toInt()}g'),

          if (data.warnings.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Health Concerns:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...data.warnings.map((w) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '• $w',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.withOpacity(0.9),
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool darkMode) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: darkMode
            ? TColors.darkerGrey.withOpacity(0.3)
            : TColors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: darkMode
              ? TColors.darkerGrey
              : TColors.grey.withOpacity(0.3),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_camera_outlined,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              'No meal photos',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            Text(
              'Tap "Add Meal Photos" to begin',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showMealDetails(MealAnalysisResult meal, bool darkMode) {
    Get.dialog(
      Dialog(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Meal ${meal.mealNumber} Details',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getGLColor(meal.glCategory).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getGLColor(meal.glCategory).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total GL:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${meal.totalGL.toStringAsFixed(1)} (${meal.glCategory.toUpperCase()})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getGLColor(meal.glCategory),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: meal.foods.length,
                  itemBuilder: (context, index) {
                    final food = meal.foods[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              food.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (food.glycemicLoad != null) ...[
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'GL:',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getGLColor(food.glCategory)
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${food.glycemicLoad!.toStringAsFixed(1)} (${food.glCategory})',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _getGLColor(food.glCategory),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                            ],
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Calories:',
                                  style: TextStyle(fontSize: 12),
                                ),
                                Text(
                                  '${food.calories.toInt()} kcal',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Carbs:',
                                  style: TextStyle(fontSize: 12),
                                ),
                                Text(
                                  '${food.carbs.toInt()}g',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            if (food.giValue != null)
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'GI:',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    '${food.giValue}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getGLColor(String category) {
    switch (category.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showUploadOptions(MealPhotosController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: THelperFunctions.isDarkMode(Get.context!)
              ? TColors.black
              : TColors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Meal Photos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.orange),
              ),
              title: const Text('Take Photo'),
              subtitle: const Text('Use camera to capture meal'),
              onTap: () {
                Get.back();
                controller.pickImage(ImageSource.camera);
              },
            ),

            const Divider(),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_library, color: Colors.green),
              ),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select multiple photos'),
              onTap: () {
                Get.back();
                controller.pickMultipleImages();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearConfirmation(MealPhotosController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear All Photos?'),
        content: const Text(
          'This will remove all uploaded photos. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.resetData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}