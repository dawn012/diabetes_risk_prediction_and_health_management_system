import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/meal_photos_controller.dart';
import 'widgets/diabetes_prediction_input_screen.dart';

class MealPhotosUploadScreen extends StatelessWidget {
  const MealPhotosUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MealPhotosController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return Obx(() => DiabetesPredictionInputScreen(
      title: 'Meal Photos',
      progressValue: 1.0, // Final step
      showBackButton: true,
      canProceed: controller.canCompleteAssessment,
      isLoading: controller.isProcessingAPI.value,
      continueButtonText: controller.apiProcessed.value
          ? 'Complete Assessment'
          : 'Process Photos',
      onContinue: () => controller.apiProcessed.value
          ? controller.completeAssessment()
          : controller.processPhotosWithAPI(),
      content: SingleChildScrollView(
        child: Column(
          children: [
            SectionHeader(
              title: 'Meal Photos',
              subtitle: 'Upload photos of your meals from the past 3 days',
              questionNumber: 'Final Step',
              icon: Icons.camera_alt,
              iconColor: Colors.orange,
            ),

            const SizedBox(height: 24),

            // Upload Requirements
            _buildRequirementsCard(controller, darkMode),

            const SizedBox(height: 24),

            // Upload Status
            _buildUploadStatusCard(controller, darkMode),

            const SizedBox(height: 24),

            // Upload Button
            _buildUploadButton(controller, darkMode),

            const SizedBox(height: 24),

            // Photos Grid
            Obx(() {
              if (controller.mealPhotos.isNotEmpty) {
                return _buildPhotosGrid(controller, darkMode);
              }
              return _buildEmptyState(darkMode);
            }),

            const SizedBox(height: 24),

            // API Processing Status
            Obx(() {
              if (controller.isProcessingAPI.value) {
                return _buildProcessingCard(controller, darkMode);
              } else if (controller.apiProcessed.value) {
                return _buildSuccessCard(controller, darkMode);
              } else if (controller.apiError.value.isNotEmpty) {
                return _buildErrorCard(controller, darkMode);
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    ));
  }

  Widget _buildRequirementsCard(MealPhotosController controller, bool darkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Upload Requirements',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRequirementItem('Minimum 7 meals required', Icons.restaurant),
          _buildRequirementItem('Maximum 9 meals allowed', Icons.fastfood),
          _buildRequirementItem('Photos from past 3 days only', Icons.calendar_today),
          _buildRequirementItem('Max total size: 10MB', Icons.storage),
          _buildRequirementItem('Supported: JPG, PNG', Icons.image),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue.withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadStatusCard(MealPhotosController controller, bool darkMode) {
    return Obx(() => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: darkMode ? TColors.darkerGrey.withOpacity(0.3) : TColors.softGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: controller.hasValidationErrors
              ? Colors.red.withOpacity(0.5)
              : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusItem(
                'Photos Uploaded',
                '${controller.mealPhotos.length}',
                controller.mealPhotos.length >= 5 ? Colors.green : Colors.orange,
                darkMode,
              ),
              _buildStatusItem(
                'Total Size',
                controller.getTotalSizeFormatted(),
                controller.getTotalSizeInMB() <= 10 ? Colors.green : Colors.red,
                darkMode,
              ),
            ],
          ),

          if (controller.validationErrors.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Issues Found:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...controller.validationErrors.map((error) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '• $error',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.withOpacity(0.8),
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    ));
  }

  Widget _buildStatusItem(String label, String value, Color color, bool darkMode) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadButton(MealPhotosController controller, bool darkMode) {
    return Container(
      width: double.infinity,
      height: 80,
      child: OutlinedButton(
        onPressed: controller.isProcessing.value ? null : () => _showUploadOptions(controller),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.orange,
          side: BorderSide(
            color: controller.isProcessing.value ? Colors.grey : Colors.orange,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: controller.isProcessing.value
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Text('Processing Images...'),
          ],
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, size: 24),
            const SizedBox(width: 12),
            Text(
              'Add Meal Photos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosGrid(MealPhotosController controller, bool darkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Uploaded Meal Photos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: darkMode ? TColors.white : TColors.black,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: controller.mealPhotos.length,
          itemBuilder: (context, index) {
            final photo = controller.mealPhotos[index];
            return _buildPhotoCard(photo, index, controller, darkMode);
          },
        ),
      ],
    );
  }

  Widget _buildPhotoCard(MealPhoto photo, int index, MealPhotosController controller, bool darkMode) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: darkMode ? TColors.darkerGrey : TColors.grey.withOpacity(0.3),
        ),
      ),
      child: Stack(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(photo.processedPath ?? photo.originalPath),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // Overlay with info
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
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
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
            right: 8,
            child: GestureDetector(
              onTap: () => controller.removePhoto(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),

          // Processing indicator
          if (photo.isProcessing)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
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
        color: darkMode ? TColors.darkerGrey.withOpacity(0.3) : TColors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: darkMode ? TColors.darkerGrey : TColors.grey.withOpacity(0.3),
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_camera,
              size: 48,
              color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'No meal photos uploaded yet',
              style: TextStyle(
                fontSize: 16,
                color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Add Meal Photos" to get started',
              style: TextStyle(
                fontSize: 14,
                color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingCard(MealPhotosController controller, bool darkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Processing Photos with API...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Analyzing nutritional content from your meal photos. This may take a few moments.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(MealPhotosController controller, bool darkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 12),
              Text(
                'Photos Processed Successfully!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your meal photos have been analyzed. You can now complete the assessment.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.green.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(MealPhotosController controller, bool darkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 20),
              const SizedBox(width: 12),
              Text(
                'Processing Failed',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            controller.apiError.value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.red.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => controller.processPhotosWithAPI(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red),
              ),
              child: Text('Retry Processing'),
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadOptions(MealPhotosController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: THelperFunctions.isDarkMode(Get.context!) ? TColors.black : TColors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Meal Photos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: THelperFunctions.isDarkMode(Get.context!) ? TColors.white : TColors.black,
              ),
            ),
            const SizedBox(height: 24),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.camera_alt, color: Colors.blue),
              ),
              title: Text('Take Photo'),
              subtitle: Text('Capture a new meal photo'),
              onTap: () {
                Get.back();
                controller.pickImage(ImageSource.camera);
              },
            ),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.photo_library, color: Colors.green),
              ),
              title: Text('Choose from Gallery'),
              subtitle: Text('Select photos from your gallery'),
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
}