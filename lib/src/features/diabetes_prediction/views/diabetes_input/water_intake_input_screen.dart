import 'package:flutter/material.dart' hide NavigationMode;
import 'package:get/get.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/health_data_range.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../controllers/water_intake_controller.dart';
import 'widgets/diabetes_prediction_input_screen.dart';
import 'widgets/water_info_dialog.dart';

class WaterIntakeInputScreen extends StatelessWidget {
  const WaterIntakeInputScreen({
    super.key,
    this.initialWaterIntake,
    this.mode = NavigationMode.flow,
  });

  final double? initialWaterIntake;
  final NavigationMode mode;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WaterIntakeController());
    final userController = UserController.instance;
    final darkMode = THelperFunctions.isDarkMode(context);

    // 计算合适的分段数量
    int _calculateDivisions() {
      final range = HealthDataRanges.maxWaterLiters - HealthDataRanges.minWaterLiters;
      // 每0.1升一个分段
      return (range / 0.1).clamp(20, 100).toInt();
    }

    // 生成范围标签
    List<String> _generateRangeLabels() {
      final min = HealthDataRanges.minWaterLiters;
      final max = HealthDataRanges.maxWaterLiters;
      final mid = ((max - min) / 2) + min;

      return [
        '${min.toDouble()}L',
        '${mid.toStringAsFixed(1)}L',
        '${max.toDouble()}L'
      ];
    }

    // 如果有传入初始值，在构建时设置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.navigationMode.value = mode;
      if (initialWaterIntake != null) {
        controller.setWaterIntake(initialWaterIntake!);
      }
    });

    return Obx(() => DiabetesPredictionInputScreen(
      title: 'Water Intake',
      progressValue: 0.75, // 6/8 steps completed
      showBackButton: controller.canGoBack.value,
      showCloseButton: true,
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
                  title: 'Daily Water Intake',
                  subtitle: 'How much water do you drink per day on average?',
                  questionNumber: 'Step 6 of 8',
                  icon: Icons.local_drink,
                  iconColor: Colors.blue,
                ),
                // Info button positioned at top-right
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () async {
                        WaterInfoDialog.show(age: userController.user.value.profile.age, gender: userController.user.value.profile.gender);
                      },
                      icon: Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                        size: 24,
                      ),
                      tooltip: 'View recommended water intake',
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.all(12),
                      ),
                    ),
                  ),
                ),
              ],
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
                            HealthDataRanges.unitWater,
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
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )),

                  const SizedBox(height: 32),

                  // Slider - 使用数据范围
                  Obx(() => CustomSlider(
                    value: controller.waterIntake.value,
                    min: HealthDataRanges.minWaterLiters,
                    max: HealthDataRanges.maxWaterLiters,
                    divisions: _calculateDivisions(),
                    onChanged: (value) => controller.setWaterIntake(value),
                    activeColor: controller.getHydrationStatusColor(),
                    darkMode: darkMode,
                  )),

                  const SizedBox(height: 16),

                  // Scale indicators - 动态生成
                  RangeIndicators(
                    labels: _generateRangeLabels(),
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

                  const SizedBox(height: 32),

                  // Quick Select Buttons
                  _buildQuickSelectButtons(controller, darkMode),

                  const SizedBox(height: 24),

                  // Water Intake Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: TColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: TColors.info.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: TColors.info,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Recommended daily water intake varies by age and gender.',
                            style: TextStyle(
                              fontSize: 12,
                              color: darkMode
                                  ? TColors.darkGrey
                                  : TColors.darkerGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
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

  // 构建快速选择按钮
  Widget _buildQuickSelectButtons(WaterIntakeController controller, bool darkMode) {
    // 使用固定的常用水量值
    final quickSelectValues = [1.0, 1.5, 2.0, 2.5, 3.0, 4.0];

    // 过滤掉超出范围的值
    final validValues = quickSelectValues.where((value) =>
    value >= HealthDataRanges.minWaterLiters &&
        value <= HealthDataRanges.maxWaterLiters
    ).toList();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: validValues.map((value) {
        return Obx(() => QuickSelectButton(
          label: '${value.toStringAsFixed(1)}L',
          isSelected: (controller.waterIntake.value - value).abs() < 0.1,
          onTap: () => controller.setWaterIntake(value),
          selectedColor: Colors.blue,
          darkMode: darkMode,
        ));
      }).toList(),
    );
  }
}