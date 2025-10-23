import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/physical_activity_controller.dart';
import 'widgets/diabetes_prediction_input_screen.dart';

class PhysicalActivityInputScreen extends StatelessWidget {
  const PhysicalActivityInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PhysicalActivityController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return Obx(() => DiabetesPredictionInputScreen(
      title: 'Physical Activity',
      progressValue: 0.375, // 3/8 steps completed
      showBackButton: true,
      canProceed: controller.canProceed.value,
      isLoading: controller.isLoading.value,
      onContinue: () => controller.nextStep(),
      // continueButtonText: controller.currentStep.value == 2 ? 'Continue' : 'Next',
      continueButtonText: 'Continue',
      onBack: controller.currentStep.value > 0 ? () => controller.previousStep() : null,
      content: PageView(
        controller: controller.pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Question 1: Exercise Frequency
          // _buildFrequencyQuestion(context, controller, darkMode),
          // Question 2: Exercise Duration
          _buildDurationQuestion(context, controller, darkMode),
          // Question 3: Exercise Intensity
          // _buildIntensityQuestion(context, controller, darkMode),
        ],
      ),
    ));
  }

  Widget _buildFrequencyQuestion(BuildContext context, PhysicalActivityController controller, bool darkMode) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'How often do you exercise?',
            subtitle: 'Tell us how many days per week you typically exercise or do physical activities',
            questionNumber: 'Question 1 of 3',
            icon: Icons.calendar_today,
            iconColor: TColors.primary,
          ),

          const SizedBox(height: 40),

          // Weekly Calendar Visual
          InputContainer(
            darkMode: darkMode,
            child: Column(
              children: [
                Text(
                  'Days per Week',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: darkMode ? TColors.white : TColors.black,
                  ),
                ),

                const SizedBox(height: 24),

                // Week days visualization
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(7, (index) {
                    final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
                    return Obx(() => GestureDetector(
                      onTap: () => controller.setFrequency(index + 1),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (index < controller.frequency.value)
                              ? TColors.primary
                              : darkMode ? TColors.darkerGrey : TColors.grey,
                        ),
                        child: Center(
                          child: Text(
                            days[index],
                            style: TextStyle(
                              color: (index < controller.frequency.value)
                                  ? TColors.white
                                  : darkMode ? TColors.darkGrey : TColors.darkerGrey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ));
                  }),
                ),

                const SizedBox(height: 24),

                Obx(() => Text(
                  controller.frequency.value == 0
                      ? 'Select how many days'
                      : controller.frequency.value == 1
                      ? '1 day per week'
                      : '${controller.frequency.value} days per week',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: TColors.primary,
                  ),
                )),

                const SizedBox(height: 32),

                // Quick select buttons
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    Obx(() => QuickSelectButton(
                      label: 'Never',
                      isSelected: controller.frequency.value == 0,
                      onTap: () => controller.setFrequency(0),
                      selectedColor: TColors.primary,
                      darkMode: darkMode,
                    )),
                    Obx(() => QuickSelectButton(
                      label: '1-2 times',
                      isSelected: controller.frequency.value == 2,
                      onTap: () => controller.setFrequency(2),
                      selectedColor: TColors.primary,
                      darkMode: darkMode,
                    )),
                    Obx(() => QuickSelectButton(
                      label: '3-4 times',
                      isSelected: controller.frequency.value == 4,
                      onTap: () => controller.setFrequency(4),
                      selectedColor: TColors.primary,
                      darkMode: darkMode,
                    )),
                    Obx(() => QuickSelectButton(
                      label: '5-6 times',
                      isSelected: controller.frequency.value == 6,
                      onTap: () => controller.setFrequency(6),
                      selectedColor: TColors.primary,
                      darkMode: darkMode,
                    )),
                    Obx(() => QuickSelectButton(
                      label: 'Daily',
                      isSelected: controller.frequency.value == 7,
                      onTap: () => controller.setFrequency(7),
                      selectedColor: TColors.primary,
                      darkMode: darkMode,
                    )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationQuestion(BuildContext context, PhysicalActivityController controller, bool darkMode) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'How long do you exercise?',
            subtitle: 'How many minutes do you usually exercise per day?',
            questionNumber: 'Step 3 of 8',
            icon: Icons.timer,
            iconColor: TColors.primary,
          ),

          const SizedBox(height: 40),

          // Duration Selector
          InputContainer(
            darkMode: darkMode,
            child: Column(
              children: [
                Text(
                  'Minutes per Day',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: darkMode ? TColors.white : TColors.black,
                  ),
                ),

                const SizedBox(height: 32),

                // Time Display
                Obx(() => Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: TColors.secondary,
                      width: 4,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${controller.duration.value}',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: TColors.secondary,
                          ),
                        ),
                        Text(
                          'minutes',
                          style: TextStyle(
                            fontSize: 16,
                            color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),

                const SizedBox(height: 32),

                // Duration Slider
                Obx(() => CustomSlider(
                  value: controller.duration.value.toDouble(),
                  min: 0,
                  max: 180,
                  divisions: 36,
                  onChanged: (value) => controller.setDuration(value.toInt()),
                  activeColor: TColors.secondary,
                  darkMode: darkMode,
                )),

                const SizedBox(height: 16),

                // Range indicators
                RangeIndicators(
                  labels: ['0 min', '90 min', '180 min'],
                  darkMode: darkMode,
                ),

                const SizedBox(height: 32),

                // Quick Duration Buttons
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    Obx(() => QuickSelectButton(
                      label: '15 min',
                      isSelected: controller.duration.value == 15,
                      onTap: () => controller.setDuration(15),
                      selectedColor: TColors.secondary,
                      darkMode: darkMode,
                    )),
                    Obx(() => QuickSelectButton(
                      label: '30 min',
                      isSelected: controller.duration.value == 30,
                      onTap: () => controller.setDuration(30),
                      selectedColor: TColors.secondary,
                      darkMode: darkMode,
                    )),
                    Obx(() => QuickSelectButton(
                      label: '45 min',
                      isSelected: controller.duration.value == 45,
                      onTap: () => controller.setDuration(45),
                      selectedColor: TColors.secondary,
                      darkMode: darkMode,
                    )),
                    Obx(() => QuickSelectButton(
                      label: '60 min',
                      isSelected: controller.duration.value == 60,
                      onTap: () => controller.setDuration(60),
                      selectedColor: TColors.secondary,
                      darkMode: darkMode,
                    )),
                    Obx(() => QuickSelectButton(
                      label: '90 min',
                      isSelected: controller.duration.value == 90,
                      onTap: () => controller.setDuration(90),
                      selectedColor: TColors.secondary,
                      darkMode: darkMode,
                    )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntensityQuestion(BuildContext context, PhysicalActivityController controller, bool darkMode) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'What\'s your exercise intensity?',
            subtitle: 'Choose the intensity that best describes your typical workout',
            questionNumber: 'Question 3 of 3',
            icon: Icons.flash_on,
            iconColor: TColors.third,
          ),

          const SizedBox(height: 40),

          // Intensity Options
          Column(
            children: [
              _buildIntensityOption(
                'Light Intensity',
                'Easy activities that barely increase your heart rate',
                [
                  'Walking slowly (strolling)',
                  'Light household chores',
                  'Gentle stretching',
                  'Casual bike riding',
                  'Light gardening',
                ],
                Colors.green,
                Icons.directions_walk,
                'light',
                controller,
                darkMode,
              ),

              const SizedBox(height: 20),

              _buildIntensityOption(
                'Moderate Intensity',
                'Activities that make you breathe harder and sweat lightly',
                [
                  'Brisk walking or hiking',
                  'Swimming laps',
                  'Cycling at moderate pace',
                  'Dancing',
                  'Yoga or Pilates',
                  'Playing tennis (doubles)',
                ],
                Colors.orange,
                Icons.directions_bike,
                'moderate',
                controller,
                darkMode,
              ),

              const SizedBox(height: 20),

              _buildIntensityOption(
                'High Intensity',
                'Vigorous activities that make you breathe hard and sweat',
                [
                  'Running or jogging',
                  'High-intensity cycling',
                  'Swimming fast laps',
                  'Basketball, football, soccer',
                  'Boxing or martial arts',
                  'CrossFit or HIIT workouts',
                ],
                Colors.red,
                Icons.directions_run,
                'high',
                controller,
                darkMode,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntensityOption(
      String title,
      String description,
      List<String> examples,
      Color color,
      IconData icon,
      String value,
      PhysicalActivityController controller,
      bool darkMode,
      ) {
    return Obx(() => GestureDetector(
      onTap: () => controller.setIntensity(value),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: controller.intensity.value == value
              ? color.withOpacity(0.1)
              : darkMode ? TColors.darkerGrey.withOpacity(0.3) : TColors.softGrey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: controller.intensity.value == value
                ? color
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
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
                          fontWeight: FontWeight.bold,
                          color: controller.intensity.value == value
                              ? color
                              : darkMode ? TColors.white : TColors.black,
                        ),
                      ),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              'Examples:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: darkMode ? TColors.white : TColors.black,
              ),
            ),

            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: examples.map((example) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  example,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    ));
  }
}