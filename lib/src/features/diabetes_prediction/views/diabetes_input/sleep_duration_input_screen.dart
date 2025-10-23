import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/sleep_duration_controller.dart';
import 'widgets/diabetes_prediction_input_screen.dart';

class SleepDurationInputScreen extends StatelessWidget {
  const SleepDurationInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SleepDurationController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return Obx(() => DiabetesPredictionInputScreen(
      title: 'Sleep Duration',
      progressValue: 0.625, // 5/8 steps completed
      showBackButton: true,
      canProceed: controller.canProceed,
      isLoading: controller.isLoading.value,
      continueButtonText: 'Continue',
      onContinue: () => controller.saveAndContinue(),
      content: SingleChildScrollView(
        child: Column(
          children: [
            SectionHeader(
              title: 'Sleep Duration',
              subtitle: 'How many hours do you sleep per night on average?',
              questionNumber: 'Step 5 of 8',
              icon: Icons.bedtime,
              iconColor: TColors.primary,
            ),

            const SizedBox(height: 40),

            // Sleep Duration Selector
            InputContainer(
              darkMode: darkMode,
              child: Column(
                children: [
                  Text(
                    'Average Sleep Duration',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: darkMode ? TColors.white : TColors.black,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Sleep Duration Display
                  Obx(() => Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: controller.getSleepQualityColor().withOpacity(0.1),
                      border: Border.all(
                        color: controller.getSleepQualityColor(),
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            controller.getSleepIcon(),
                            size: 36,
                            color: controller.getSleepQualityColor(),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            controller.getFormattedDuration(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: controller.getSleepQualityColor(),
                            ),
                          ),
                          Text(
                            'hours',
                            style: TextStyle(
                              fontSize: 14,
                              color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),

                  const SizedBox(height: 24),

                  // Sleep Quality Description
                  Obx(() => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: controller.getSleepQualityColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        controller.getSleepQualityDescription(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: controller.getSleepQualityColor(),
                        ),
                      ),
                    ),
                  )),

                  const SizedBox(height: 32),

                  // Slider
                  Obx(() => CustomSlider(
                    value: controller.sleepDuration.value,
                    min: 3.0,
                    max: 12.0,
                    divisions: 18, // 0.5 hour increments
                    onChanged: (value) => controller.setSleepDuration(value),
                    activeColor: controller.getSleepQualityColor(),
                    darkMode: darkMode,
                  )),

                  const SizedBox(height: 16),

                  // Scale indicators
                  RangeIndicators(
                    labels: ['3h (Too Short)', '7-9h (Optimal)', '12h (Too Long)'],
                    colors: [
                      Colors.red,
                      Colors.green,
                      Colors.orange,
                    ],
                    darkMode: darkMode,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Quick Select Options
            InputContainer(
              darkMode: darkMode,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Select',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: darkMode ? TColors.white : TColors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a common sleep duration',
                    style: TextStyle(
                      fontSize: 14,
                      color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Quick select buttons
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildQuickSelectButton('6h', 6.0, controller, darkMode),
                      _buildQuickSelectButton('6.5h', 6.5, controller, darkMode),
                      _buildQuickSelectButton('7h', 7.0, controller, darkMode),
                      _buildQuickSelectButton('7.5h', 7.5, controller, darkMode),
                      _buildQuickSelectButton('8h', 8.0, controller, darkMode),
                      _buildQuickSelectButton('8.5h', 8.5, controller, darkMode),
                      _buildQuickSelectButton('9h', 9.0, controller, darkMode),
                      _buildQuickSelectButton('9.5h', 9.5, controller, darkMode),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildQuickSelectButton(String label, double value, SleepDurationController controller, bool darkMode) {
    return Obx(() {
      final isSelected = (controller.sleepDuration.value - value).abs() < 0.1;
      return QuickSelectButton(
        label: label,
        isSelected: isSelected,
        onTap: () => controller.setSleepDuration(value),
        selectedColor: TColors.secondary,
        darkMode: darkMode,
      );
    });
  }
}