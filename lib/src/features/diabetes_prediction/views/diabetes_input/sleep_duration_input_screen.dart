import 'package:flutter/material.dart' hide NavigationMode;
import 'package:get/get.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/health_data_range.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../controllers/sleep_duration_controller.dart';
import 'widgets/diabetes_prediction_input_screen.dart';
import 'widgets/sleep_info_dialog.dart';

class SleepDurationInputScreen extends StatelessWidget {
  const SleepDurationInputScreen({
    super.key,
    this.initialSleepDuration,
    this.mode = NavigationMode.flow,
  });

  final double? initialSleepDuration;
  final NavigationMode mode;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SleepDurationController());
    final userController = UserController.instance;
    final darkMode = THelperFunctions.isDarkMode(context);

    // 如果有传入初始值，在构建时设置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.navigationMode.value = mode;
      if (initialSleepDuration != null) {
        controller.setSleepDuration(initialSleepDuration!);
      }
    });

    return Obx(() => DiabetesPredictionInputScreen(
      title: 'Sleep Duration',
      progressValue: 0.625,
      // 5/8 steps completed
      showBackButton: controller.canGoBack.value,
      showCloseButton: true,
      // onClose: () => controller.handleClose(context),
      canProceed: controller.canProceed,
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
                  title: 'How long do you sleep?',
                  subtitle: 'Average sleep duration per night in the past week',
                  questionNumber: 'Step 5 of 8',
                  icon: Icons.bedtime,
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
                      onPressed: () async {
                        SleepInfoDialog.show(age: userController.user.value.profile.age);
                      },
                      icon: Icon(
                        Icons.info_outline,
                        color: TColors.primary,
                        size: 24,
                      ),
                      tooltip: 'View recommended sleep duration',
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.all(12),
                      ),
                    ),
                  ),
                ),
              ],
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
                      color: controller
                          .getSleepQualityColor()
                          .withOpacity(0.1),
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
                            'per night',
                            style: TextStyle(
                              fontSize: 12,
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

                  // Sleep Quality Description
                  Obx(() => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: controller
                          .getSleepQualityColor()
                          .withOpacity(0.1),
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
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )),

                  const SizedBox(height: 32),

                  // Slider
                  Obx(() => CustomSlider(
                    value: controller.sleepDuration.value,
                    min: HealthDataRanges.minSleepHours,
                    max: HealthDataRanges.maxSleepHours,
                    divisions: 18,
                    // 0.5 hour increments
                    onChanged: (value) =>
                        controller.setSleepDuration(value),
                    activeColor: controller.getSleepQualityColor(),
                    darkMode: darkMode,
                  )),

                  const SizedBox(height: 16),

                  // Scale indicators
                  RangeIndicators(
                    labels: [
                      '${HealthDataRanges.minSleepHours.toInt()}h',
                      '7-9h (Optimal)',
                      '${HealthDataRanges.maxSleepHours.toInt()}h'
                    ],
                    colors: [
                      Colors.red,
                      Colors.green,
                      Colors.orange,
                    ],
                    darkMode: darkMode,
                  ),

                  const SizedBox(height: 32),

                  // Divider
                  Divider(
                    color: darkMode
                        ? TColors.darkerGrey.withOpacity(0.3)
                        : TColors.grey.withOpacity(0.3),
                  ),

                  const SizedBox(height: 12),

                  // Quick select buttons
                  _buildQuickSelectButtons(controller, darkMode),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    ));
  }

  // 构建快速选择按钮 \
  Widget _buildQuickSelectButtons(SleepDurationController controller, bool darkMode) {
    // 使用固定的常用睡眠时长值
    final quickSelectValues = [5.0, 6.0, 6.5, 7.0, 7.5, 8.0, 9.0, 10.0];

    // 过滤掉超出范围的值
    final validValues = quickSelectValues.where((value) =>
    value >= HealthDataRanges.minSleepHours &&
        value <= HealthDataRanges.maxSleepHours
    ).toList();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: validValues.map((value) {
        return Obx(() => QuickSelectButton(
          label: '${value.toDouble()}h',
          isSelected: (controller.sleepDuration.value - value).abs() < 0.1,
          onTap: () => controller.setSleepDuration(value),
          selectedColor: TColors.primary,
          darkMode: darkMode,
        ));
      }).toList(),
    );
  }
}