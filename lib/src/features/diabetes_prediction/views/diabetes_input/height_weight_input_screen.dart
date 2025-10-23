import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/height_weight_controller.dart';
import 'widgets/diabetes_prediction_input_screen.dart';

class HeightWeightInputScreen extends StatelessWidget {
  const HeightWeightInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HeightWeightController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return Obx(() => DiabetesPredictionInputScreen(
      title: 'Health Metrics',
      progressValue: 0.125, // 1/8 steps completed
      showBackButton: false, // First screen - no back button
      canProceed: controller.canProceed.value,
      isLoading: controller.isLoading.value,
      onContinue: () => controller.saveAndContinue(),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Let\'s get your measurements',
              subtitle: 'This helps us provide more accurate predictions',
              questionNumber: 'Step 1 of 8',
              icon: Icons.straighten,
              iconColor: TColors.primary,
            ),

            const SizedBox(height: 48),

            // Height Section
            _buildHeightSection(context, controller, darkMode),

            const SizedBox(height: 48),

            // Weight Section
            _buildWeightSection(context, controller, darkMode),
          ],
        ),
      ),
    ));
  }

  Widget _buildHeightSection(BuildContext context, HeightWeightController controller, bool darkMode) {
    return InputContainer(
      darkMode: darkMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Height', 'Drag the slider to set your height', Icons.height, TColors.primary, darkMode),

          const SizedBox(height: 32),

          // Height Display
          Center(
            child: Obx(() => Column(
              children: [
                Text(
                  '${controller.height.value.toInt()}',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: TColors.primary,
                  ),
                ),
                Text(
                  'cm',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                  ),
                ),
              ],
            )),
          ),

          const SizedBox(height: 24),

          // Height Slider
          Obx(() => CustomSlider(
            value: controller.height.value,
            min: 100,
            max: 250,
            divisions: 150,
            onChanged: (value) => controller.updateHeight(value),
            activeColor: TColors.primary,
            darkMode: darkMode,
          )),

          const SizedBox(height: 16),

          // Range indicators
          RangeIndicators(
            labels: ['100cm', '175cm', '250cm'],
            darkMode: darkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildWeightSection(BuildContext context, HeightWeightController controller, bool darkMode) {
    return InputContainer(
      darkMode: darkMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Weight', 'Use the controls to set your weight', Icons.monitor_weight_outlined, TColors.secondary, darkMode),

          const SizedBox(height: 32),

          // Weight Display with Circular Design
          Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Circular Background
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: darkMode ? TColors.darkerGrey : TColors.grey,
                        width: 2,
                      ),
                    ),
                  ),

                  // Weight Value
                  Obx(() => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${controller.weight.value.toInt()}',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: TColors.secondary,
                        ),
                      ),
                      Text(
                        'kg',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                        ),
                      ),
                    ],
                  )),

                  // Circular Progress Indicator
                  Obx(() => Container(
                    width: 180,
                    height: 180,
                    child: CircularProgressIndicator(
                      value: (controller.weight.value - 30) / 120,
                      strokeWidth: 8,
                      backgroundColor: darkMode ? TColors.darkerGrey : TColors.grey,
                      valueColor: AlwaysStoppedAnimation<Color>(TColors.secondary),
                    ),
                  )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Weight Control Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildWeightButton(
                context,
                Icons.remove,
                    () => controller.decreaseWeight(),
                darkMode,
              ),
              _buildWeightButton(
                context,
                Icons.add,
                    () => controller.increaseWeight(),
                darkMode,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Fine adjustment slider
          Obx(() => CustomSlider(
            value: controller.weight.value,
            min: 30,
            max: 150,
            divisions: 240,
            onChanged: (value) => controller.updateWeight(value),
            activeColor: TColors.secondary,
            darkMode: darkMode,
            thumbRadius: 10,
            trackHeight: 4,
          )),

          const SizedBox(height: 16),

          // Weight range indicators
          RangeIndicators(
            labels: ['30kg', '90kg', '150kg'],
            darkMode: darkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle, IconData icon, Color color, bool darkMode) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: darkMode ? TColors.white : TColors.black,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeightButton(BuildContext context, IconData icon, VoidCallback onPressed, bool darkMode) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: TColors.secondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: TColors.secondary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: TColors.secondary,
          size: 24,
        ),
      ),
    );
  }
}