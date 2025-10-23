import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/water_intake_controller.dart';
import 'widgets/diabetes_prediction_input_screen.dart';

class WaterIntakeInputScreen extends StatelessWidget {
  const WaterIntakeInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WaterIntakeController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return Obx(() => DiabetesPredictionInputScreen(
      title: 'Water Intake',
      progressValue: 0.75,
      showBackButton: true,
      canProceed: controller.canProceed,
      isLoading: controller.isLoading.value,
      continueButtonText: 'Continue',
      onContinue: () => controller.saveAndContinue(),
      content: SingleChildScrollView(
        child: Column(
          children: [
            SectionHeader(
              title: 'Daily Water Intake',
              subtitle: 'How much water do you drink per day on average?',
              questionNumber: 'Step 6 of 8',
              icon: Icons.local_drink,
              iconColor: Colors.blue,
            ),

            const SizedBox(height: 40),

            // Water Intake Selector
            InputContainer(
              darkMode: darkMode,
              child: Column(
                children: [
                  Text(
                    'Average Daily Water Intake',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: darkMode ? TColors.white : TColors.black,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Water Intake Display
                  Obx(() => Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: controller.getHydrationStatusColor().withOpacity(0.1),
                      border: Border.all(
                        color: controller.getHydrationStatusColor(),
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_drink,
                            size: 36,
                            color: controller.getHydrationStatusColor(),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${controller.waterIntake.value.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: controller.getHydrationStatusColor(),
                            ),
                          ),
                          Text(
                            'liters',
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

                  // Hydration Status Description
                  Obx(() => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: controller.getHydrationStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        controller.getHydrationStatusDescription(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: controller.getHydrationStatusColor(),
                        ),
                      ),
                    ),
                  )),

                  const SizedBox(height: 32),

                  // Slider
                  Obx(() => CustomSlider(
                    value: controller.waterIntake.value,
                    min: 0.5,
                    max: 5.0,
                    divisions: 45, // 0.1 liter increments
                    onChanged: (value) => controller.setWaterIntake(value),
                    activeColor: controller.getHydrationStatusColor(),
                    darkMode: darkMode,
                  )),

                  const SizedBox(height: 16),

                  // Scale indicators
                  RangeIndicators(
                    labels: ['0.5L (Low)', '2-3L (Good)', '5L (High)'],
                    colors: [
                      Colors.red,
                      Colors.green,
                      Colors.blue,
                    ],
                    darkMode: darkMode,
                  ),

                  const SizedBox(height: 24),

                  // Alternative unit display
                  Obx(() => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: darkMode ? TColors.darkerGrey.withOpacity(0.3) : TColors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildUnitDisplay(
                          '≈ ${controller.getCupsEquivalent()} cups',
                          Icons.coffee,
                          darkMode,
                        ),
                        _buildUnitDisplay(
                          '≈ ${controller.getBottlesEquivalent()} bottles',
                          Icons.sports_bar,
                          darkMode,
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Unit Selection
            InputContainer(
              darkMode: darkMode,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preferred Unit',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: darkMode ? TColors.white : TColors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose how you prefer to measure water intake',
                    style: TextStyle(
                      fontSize: 14,
                      color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Unit selection buttons
                  Obx(() => Row(
                    children: [
                      Expanded(
                        child: _buildUnitButton(
                          'Liters',
                          Icons.local_drink,
                          'liters',
                          controller,
                          darkMode,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildUnitButton(
                          'Cups',
                          Icons.coffee,
                          'cups',
                          controller,
                          darkMode,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildUnitButton(
                          'Bottles',
                          Icons.sports_bar,
                          'bottles',
                          controller,
                          darkMode,
                        ),
                      ),
                    ],
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildUnitDisplay(String text, IconData icon, bool darkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildUnitButton(String label, IconData icon, String unit, WaterIntakeController controller, bool darkMode) {
    final isSelected = controller.preferredUnit.value == unit;
    return GestureDetector(
      onTap: () => controller.setPreferredUnit(unit),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withOpacity(0.1)
              : darkMode ? TColors.darkerGrey.withOpacity(0.5) : TColors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? Colors.blue
                  : darkMode ? TColors.white : TColors.black,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.blue
                    : darkMode ? TColors.white : TColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}