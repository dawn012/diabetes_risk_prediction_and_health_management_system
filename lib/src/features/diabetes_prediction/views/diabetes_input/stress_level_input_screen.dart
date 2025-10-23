import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/stress_level_controller.dart';
import 'widgets/diabetes_prediction_input_screen.dart';

class StressLevelInputScreen extends StatelessWidget {
  const StressLevelInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StressLevelController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return Obx(() => DiabetesPredictionInputScreen(
      title: 'Stress Level',
      progressValue: 0.5, // 4/8 steps completed
      showBackButton: true,
      canProceed: controller.canProceed.value,
      isLoading: controller.isLoading.value,
      continueButtonText: 'Continue',
      onContinue: () => controller.saveAndContinue(),
      content: SingleChildScrollView(
        child: Column(
          children: [
            SectionHeader(
              title: 'How stressed do you feel?',
              subtitle: 'Rate your stress level in the past month',
              questionNumber: 'Step 4 of 8',
              icon: Icons.psychology,
              iconColor: TColors.primary,
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
                      color: controller.getStressLevelColor().withOpacity(0.1),
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
                              color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
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
                      color: controller.getStressLevelColor().withOpacity(0.1),
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
                      ),
                    ),
                  )),

                  const SizedBox(height: 32),

                  // Slider
                  Obx(() => CustomSlider(
                    value: controller.stressLevel.value.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: (value) => controller.setStressLevel(value.toInt()),
                    activeColor: controller.getStressLevelColor(),
                    darkMode: darkMode,
                  )),

                  const SizedBox(height: 16),

                  // Scale indicators
                  RangeIndicators(
                    labels: ['1 (No Stress)', '10 (Extreme)'],
                    darkMode: darkMode,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Stress Sources Section
            InputContainer(
              darkMode: darkMode,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Common Stress Sources',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: darkMode ? TColors.white : TColors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select what causes you stress (optional)',
                    style: TextStyle(
                      fontSize: 14,
                      color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Stress sources chips
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildStressSourceChip('Work/Career', Icons.work, controller, darkMode),
                      _buildStressSourceChip('Studies', Icons.school, controller, darkMode),
                      _buildStressSourceChip('Family', Icons.family_restroom, controller, darkMode),
                      _buildStressSourceChip('Health', Icons.local_hospital, controller, darkMode),
                      _buildStressSourceChip('Finances', Icons.attach_money, controller, darkMode),
                      _buildStressSourceChip('Relationships', Icons.favorite, controller, darkMode),
                      _buildStressSourceChip('Future', Icons.psychology_alt, controller, darkMode),
                      _buildStressSourceChip('Social', Icons.groups, controller, darkMode),
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

  Widget _buildStressSourceChip(String label, IconData icon, StressLevelController controller, bool darkMode) {
    return Obx(() {
      final isSelected = controller.stressSources.contains(label);
      return GestureDetector(
        onTap: () => controller.toggleStressSource(label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? TColors.primary.withOpacity(0.1)
                : darkMode ? TColors.darkerGrey.withOpacity(0.5) : TColors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? TColors.primary
                  : Colors.transparent,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? TColors.primary
                    : darkMode ? TColors.white : TColors.black,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? TColors.primary
                      : darkMode ? TColors.white : TColors.black,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}