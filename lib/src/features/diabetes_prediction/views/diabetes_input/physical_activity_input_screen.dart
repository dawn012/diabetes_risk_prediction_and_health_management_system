import 'package:flutter/material.dart' hide NavigationMode;
import 'package:get/get.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/health_data_range.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/physical_activity_controller.dart';
import 'widgets/diabetes_prediction_input_screen.dart';

class PhysicalActivityInputScreen extends StatelessWidget {
  const PhysicalActivityInputScreen({
    super.key,
    this.initialDuration,
    this.mode = NavigationMode.flow,
  });

  final int? initialDuration;
  final NavigationMode mode;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PhysicalActivityController());
    final darkMode = THelperFunctions.isDarkMode(context);

    // 计算进度值的最大值（使用数据范围）
    double getMaxProgressValue() {
      return HealthDataRanges.maxActivityDurationMin.toDouble();
    }

    // 如果有传入初始值，在构建时设置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.navigationMode.value = mode;
      if (initialDuration != null) {
        controller.setDuration(initialDuration!);
      }
    });

    return Obx(() => DiabetesPredictionInputScreen(
      title: 'Physical Activity',
      progressValue: 0.375, // 3/8 steps completed
      showBackButton: controller.canGoBack.value,
      showCloseButton: true,
      // onClose: () => controller.handleClose(context),
      canProceed: controller.canProceed.value,
      isLoading: controller.isLoading.value,
      onContinue: () => controller.saveAndContinue(),
      onSave: () => controller.saveAndContinue(),
      continueButtonText: 'Continue',
      showSyncButton: controller.shouldShowSyncButton.value,
      onSync: () => controller.syncFromHealthLogs(),
      navigationMode: controller.navigationMode.value,
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Daily Physical Activity',
              subtitle: 'How many minutes do you usually exercise per day?',
              questionNumber: 'Step 3 of 8',
              icon: Icons.directions_run,
              iconColor: TColors.secondary,
            ),

            const SizedBox(height: 40),

            // Duration Selector
            InputContainer(
              darkMode: darkMode,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer, color: TColors.secondary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Average Minutes per Day',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: darkMode ? TColors.white : TColors.black,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Time Display with Circular Progress
                  Obx(() => Container(
                    width: 220,
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Circular Progress Background
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: CircularProgressIndicator(
                            value: controller.duration.value / getMaxProgressValue(),
                            strokeWidth: 12,
                            backgroundColor: darkMode
                                ? TColors.darkerGrey
                                : TColors.grey.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              TColors.secondary,
                            ),
                          ),
                        ),

                        // Center Content
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${controller.duration.value}',
                              style: TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.bold,
                                color: TColors.secondary,
                              ),
                            ),
                            Text(
                              'minutes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: darkMode
                                    ? TColors.darkGrey
                                    : TColors.darkerGrey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6
                              ),
                              decoration: BoxDecoration(
                                color: _getActivityLevelColor(
                                    controller.duration.value
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getActivityLevel(controller.duration.value),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _getActivityLevelColor(
                                      controller.duration.value
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),

                  const SizedBox(height: 32),

                  // Duration Slider - 使用数据范围
                  Obx(() => CustomSlider(
                    value: controller.duration.value.toDouble(),
                    min: 0,
                    max: getMaxProgressValue(),
                    divisions: _calculateDivisions(),
                    onChanged: (value) => controller.setDuration(value.toInt()),
                    activeColor: TColors.secondary,
                    darkMode: darkMode,
                  )),

                  const SizedBox(height: 16),

                  // Range indicators - 动态生成标签
                  RangeIndicators(
                    labels: _generateRangeLabels(),
                    darkMode: darkMode,
                  ),

                  const SizedBox(height: 32),

                  // Quick Duration Buttons - 使用智能分段
                  _buildQuickSelectButtons(controller, darkMode),

                  const SizedBox(height: 24),

                  // Activity Info Card
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
                            'WHO recommends at least 150 minutes of moderate activity per week (≈22 min/day). '
                                'Maximum reasonable duration: ${HealthDataRanges.maxActivityDurationMin} minutes.',
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
          ],
        ),
      ),
    ));
  }

  // 计算合适的分段数量
  int _calculateDivisions() {
    final range = HealthDataRanges.maxActivityDurationMin - 0;
    // 每5分钟一个分段，但最多不超过60个分段
    return (range / 5).clamp(20, 60).toInt();
  }

  // 生成范围标签
  List<String> _generateRangeLabels() {
    final min = 0;
    final max = HealthDataRanges.maxActivityDurationMin;
    final mid = ((max - min) ~/ 2) + min;

    return [
      '$min min',
      '$mid min',
      '$max min'
    ];
  }

  // 构建快速选择按钮
  Widget _buildQuickSelectButtons(PhysicalActivityController controller, bool darkMode) {
    // 使用固定的常用值
    final quickSelectValues = [0, 15, 30, 60, 120, 180];

    // 过滤掉超出范围的值
    final validValues = quickSelectValues.where((value) =>
    value >= 0 &&
        value <= HealthDataRanges.maxActivityDurationMin
    ).toList();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: validValues.map((value) {
        return Obx(() => QuickSelectButton(
          label: '$value min',
          isSelected: controller.duration.value == value,
          onTap: () => controller.setDuration(value),
          selectedColor: TColors.secondary,
          darkMode: darkMode,
        ));
      }).toList(),
    );
  }

  String _getActivityLevel(int minutes) {
    if (minutes == 0) return 'Sedentary';
    if (minutes < 15) return 'Minimal';
    if (minutes < 30) return 'Light';
    if (minutes < 60) return 'Moderate';
    if (minutes < 120) return 'Active';
    return 'Very Active';
  }

  Color _getActivityLevelColor(int minutes) {
    if (minutes == 0) return Colors.grey;
    if (minutes < 15) return Colors.orange;
    if (minutes < 30) return Colors.amber;
    if (minutes < 60) return Colors.lightGreen;
    if (minutes < 120) return Colors.green;
    return Colors.green[800]!;
  }
}