import 'package:flutter/material.dart' hide NavigationMode;
import 'package:get/get.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/health_data_range.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/stress_level_controller.dart';
import 'widgets/diabetes_prediction_input_screen.dart';
import 'widgets/stress_info_dialog.dart';

class StressLevelInputScreen extends StatelessWidget {
  const StressLevelInputScreen({
    super.key,
    this.initialStressLevel,
    this.mode = NavigationMode.flow,
  });

  final int? initialStressLevel;
  final NavigationMode mode;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StressLevelController());
    final darkMode = THelperFunctions.isDarkMode(context);

    // 如果有传入初始值，在构建时设置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.navigationMode.value = mode;
      if (initialStressLevel != null) {
        controller.setStressLevel(initialStressLevel!);
      }
    });

    return Obx(() => DiabetesPredictionInputScreen(
      title: 'Stress Level',
      progressValue: 0.5,
      // 4/8 steps completed
      showBackButton: controller.canGoBack.value,
      showCloseButton: true,
      // onClose: () => controller.handleClose(context),
      canProceed: controller.canProceed.value,
      isLoading: controller.isLoading.value,
      continueButtonText: 'Continue',
      onContinue: () => controller.saveAndContinue(),
      onSave: () => controller.saveAndContinue(),
      navigationMode: controller.navigationMode.value,
      content: SingleChildScrollView(
        child: Column(
          children: [
            // Section Header with Info Button
            Stack(
              children: [
                SectionHeader(
                  title: 'How stressed do you feel?',
                  subtitle: 'Rate your stress level in the past month',
                  questionNumber: 'Step 4 of 8',
                  icon: Icons.psychology,
                  iconColor: TColors.primary,
                ),
                // Info button positioned at top-right
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: TColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => StressInfoDialog.show(),
                      icon: Icon(
                        Icons.info_outline,
                        color: TColors.primary,
                        size: 24,
                      ),
                      tooltip: 'Learn about stress levels',
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.all(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Stress Level Selector
            InputContainer(
              darkMode: darkMode,
              child: Column(
                children: [
                  Text(
                    'Stress Level',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: darkMode ? TColors.white : TColors.black,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Stress Level Display
                  Obx(() => Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: controller
                          .getStressLevelColor()
                          .withOpacity(0.1),
                      border: Border.all(
                        color: controller.getStressLevelColor(),
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            controller.getStressEmoji(),
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${controller.stressLevel.value}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: controller.getStressLevelColor(),
                            ),
                          ),
                          Text(
                            '/10',
                            style: TextStyle(
                              fontSize: 14,
                              color: darkMode
                                  ? TColors.darkGrey
                                  : TColors.darkerGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),

                  const SizedBox(height: 24),

                  // Stress Level Description
                  Obx(() => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: controller
                          .getStressLevelColor()
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        controller.getStressLevelDescription(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: controller.getStressLevelColor(),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )),

                  const SizedBox(height: 32),

                  // Slider
                  Obx(() => CustomSlider(
                    value: controller.stressLevel.value.toDouble(),
                    min: HealthDataRanges.minStressLevel.toDouble(),
                    max: HealthDataRanges.maxStressLevel.toDouble(),
                    divisions: 9,
                    onChanged: (value) =>
                        controller.setStressLevel(value.toInt()),
                    activeColor: controller.getStressLevelColor(),
                    darkMode: darkMode,
                  )),

                  const SizedBox(height: 16),

                  // Scale indicators
                  RangeIndicators(
                    labels: ['${HealthDataRanges.minStressLevel} (No Stress)', '${HealthDataRanges.maxStressLevel} (Extreme)'],
                    darkMode: darkMode,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    ));
  }
}