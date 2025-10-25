import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/blood_glucose_controller.dart';
import '../../controllers/exercise_controller.dart';
import 'connect_exercise_apps_screen.dart';
import 'exercise_goals_info_screen.dart';
import 'set_goals_screen.dart';
import 'step_goal_info_screen.dart';
import 'widgets/activity_bar_chart.dart';
import 'widgets/activity_time_range_picker.dart';
import 'widgets/health_data_list_screen.dart';

class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ExerciseController>();
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: darkMode ? TColors.dark : TColors.light,
      appBar: AppBar(
        backgroundColor: TColors.primary,
        title: const Text(
          'Exercise',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () async {
              // 直接导航到 SetGoalsScreen，不等待返回值
              Get.to(() => const SetGoalsScreen());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: TColors.primary,
            child: TabBar(
              controller: controller.tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.6),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Week'),
                Tab(text: 'Month'),
              ],
            ),
          ),

          // Time Range Dropdown
          Obx(() =>
              ActivityTimeRangePicker(
                selectedRange: controller.selectedTimeRange.value,
                onRangeChanged: controller.updateTimeRange,
                isWeekView: controller.tabController.index == 0,
              )),

          // Content
          Expanded(
            child: TabBarView(
              controller: controller.tabController,
              children: [
                _buildWeekView(controller, darkMode),
                _buildMonthView(controller, darkMode),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekView(ExerciseController controller, bool darkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      child: Column(
        children: [
          // Connection Card (only show if not connected)
          Obx(() {
            if (controller.shouldShowConnectionCard) {
              return Column(
                children: [
                  _buildConnectionCard(darkMode, controller),
                  const SizedBox(height: TSizes.spaceBtwSections),
                ],
              );
            }
            return const SizedBox.shrink();
          }),

          // Exercise Card
          _buildExerciseCard(controller, darkMode, isWeekView: true),

          const SizedBox(height: TSizes.spaceBtwSections),

          // Steps Card
          _buildStepsCard(controller, darkMode, isWeekView: true),
        ],
      ),
    );
  }

  Widget _buildMonthView(ExerciseController controller, bool darkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      child: Column(
        children: [
          // Connection Card (only show if not connected)
          Obx(() {
            if (controller.shouldShowConnectionCard) {
              return Column(
                children: [
                  _buildConnectionCard(darkMode, controller),
                  const SizedBox(height: TSizes.spaceBtwSections),
                ],
              );
            }
            return const SizedBox.shrink();
          }),

          // Exercise Card
          _buildExerciseCard(controller, darkMode, isWeekView: false),

          const SizedBox(height: TSizes.spaceBtwSections),

          // Steps Card
          _buildStepsCard(controller, darkMode, isWeekView: false),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(bool darkMode, ExerciseController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: darkMode ? TColors.darkContainer : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Connect to your exercise app to sync your exercise activities and steps. Tap the button below to start!',
                  style: TextStyle(
                    color: darkMode ? TColors.white : TColors.textPrimary,
                    fontSize: TSizes.fontSizeMd,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: darkMode ? TColors.white : TColors.textSecondary,
                ),
                onPressed: () => controller.connectApp(),
              ),
            ],
          ),
          const SizedBox(height: TSizes.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Get.to(() => const ConnectExerciseAppsScreen()),
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.primary,
                padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
                ),
              ),
              child: const Text(
                'Connect',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: TSizes.fontSizeMd,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(ExerciseController controller, bool darkMode,
      {required bool isWeekView}) {
    return GestureDetector(
      onTap: () {
        // 跳转到运动记录列表页面
        Get.to(() =>
            HealthDataListScreen(
              title: 'Exercise Records',
              healthDataList: controller.allExerciseLogs,
              healthDataType: HealthDataType.physicalActivity,
            ));
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        decoration: BoxDecoration(
          color: darkMode ? TColors.darkContainer : Colors.white,
          borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Exercise',
                  style: TextStyle(
                    color: darkMode ? TColors.white : TColors.textPrimary,
                    fontSize: TSizes.fontSizeLg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    // View all records icon
                    IconButton(
                      icon: Icon(
                        Icons.list_alt,
                        color: darkMode ? TColors.white : TColors.textSecondary,
                      ),
                      onPressed: () {
                        Get.to(() =>
                            HealthDataListScreen(
                              title: 'Exercise Records',
                              healthDataList: controller.allExerciseLogs,
                              healthDataType: HealthDataType.physicalActivity,
                            ));
                      },
                      tooltip: 'View all records',
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.info_outline,
                        color: darkMode ? TColors.white : TColors.textSecondary,
                      ),
                      onPressed: () =>
                          Get.to(() => const ExerciseGoalsInfoScreen()),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: TSizes.md),

            // Goal Progress (only show for week view)
            if (isWeekView) ...[
              Obx(() => _buildExerciseGoalProgress(controller, darkMode)),
              const SizedBox(height: TSizes.lg),
            ] else
              const SizedBox(height: TSizes.md),

            // Chart
            Obx(() =>
                ActivityBarChart(
                  data: controller.exerciseChartData.value,
                  isWeekView: isWeekView,
                  maxValue: 160,
                  goalValue: controller.weeklyExerciseGoal.toDouble(),
                  showLegend: true,
                  legendItems: const [
                    LegendItem(
                        color: Color(0xFF06B6D4), label: 'Low-intensity'),
                    LegendItem(
                        color: Color(0xFFF59E0B), label: 'Moderate-intensity'),
                    LegendItem(
                        color: Color(0xFFEF4444), label: 'High-intensity'),
                  ],
                  unit: 'min',
                  // Required for export functionality
                  title: 'Daily Activity',
                  timeRange: controller.selectedTimeRange.value,
                  periodFilter: controller.selectedPeriodFilter.value,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseGoalProgress(ExerciseController controller,
      bool darkMode) {
    return Row(
      children: [
        // Circular Progress
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            children: [
              CircularProgressIndicator(
                value: controller.exerciseProgress.value,
                backgroundColor: TColors.grey,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    TColors.primary),
                strokeWidth: 6,
              ),
              Center(
                child: Icon(
                  Icons.directions_run,
                  color: TColors.primary,
                  size: 24,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: TSizes.md),

        // Progress Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() =>
                  Text(
                    'Weekly goal of ${controller.weeklyExerciseGoal} min',
                    style: TextStyle(
                      color: darkMode ? TColors.white : TColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  )),
              const SizedBox(height: TSizes.xs),
              Obx(() =>
                  Text(
                    '${controller.remainingMinutes
                        .value} min left to achieve weekly goal',
                    style: TextStyle(
                      color: darkMode ? TColors.textSecondary : TColors
                          .textSecondary,
                      fontSize: TSizes.fontSizeSm,
                    ),
                  )),
              const SizedBox(height: TSizes.xs),
              Obx(() =>
                  Text(
                    '${controller.lowIntensityMinutes.value} min low-intensity',
                    style: TextStyle(
                      color: const Color(0xFF06B6D4),
                      fontSize: TSizes.fontSizeSm,
                    ),
                  )),
              Obx(() =>
                  Text(
                    '${controller.moderateIntensityMinutes
                        .value} min moderate-intensity',
                    style: TextStyle(
                      color: const Color(0xFFF59E0B),
                      fontSize: TSizes.fontSizeSm,
                    ),
                  )),
              Obx(() =>
                  Text(
                    '${controller.highIntensityMinutes
                        .value} min high-intensity',
                    style: TextStyle(
                      color: const Color(0xFFEF4444),
                      fontSize: TSizes.fontSizeSm,
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepsCard(ExerciseController controller, bool darkMode,
      {required bool isWeekView}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: darkMode ? TColors.darkContainer : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Steps',
                style: TextStyle(
                  color: darkMode ? TColors.white : TColors.textPrimary,
                  fontSize: TSizes.fontSizeLg,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.info_outline,
                  color: darkMode ? TColors.white : TColors.textSecondary,
                ),
                onPressed: () => Get.to(() => const StepsGoalInfoScreen()),
              ),
            ],
          ),

          const SizedBox(height: TSizes.md),

          // Steps Summary
          Obx(() => _buildStepsSummary(controller, darkMode, isWeekView)),

          const SizedBox(height: TSizes.lg),

          // Chart
          Obx(() =>
              ActivityBarChart(
                data: controller.stepsChartData.value,
                isWeekView: isWeekView,
                maxValue: isWeekView ? 12000 : 60000,
                // Higher max for weekly totals in month view
                goalValue: controller.dailyStepsGoal.toDouble(),
                showLegend: true,
                legendItems: const [
                  LegendItem(color: TColors.primary, label: 'Steps'),
                ],
                singleColor: TColors.primary,
                showNoData: !controller.hasStepsData.value,
                unit: 'steps',
                // Required for export functionality
                title: 'Daily Steps',
                timeRange: controller.selectedTimeRange.value,
                periodFilter: controller.selectedPeriodFilter.value,
              )),
        ],
      ),
    );
  }

  Widget _buildStepsSummary(ExerciseController controller, bool darkMode,
      bool isWeekView) {
    if (controller.hasStepsData.value) {
      return Row(
        children: [
          Text(
            'Average ',
            style: TextStyle(
              color: darkMode ? TColors.white : TColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Obx(() =>
              Text(
                '${controller.averageSteps.value} steps',
                style: TextStyle(
                  color: TColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: TSizes.fontSizeMd,
                ),
              )),
          Text(
            ' per ${isWeekView ? 'day' : 'week'}',
            style: TextStyle(
              color: darkMode ? TColors.white : TColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(TSizes.md),
        decoration: BoxDecoration(
          color: TColors.lightGrey.withOpacity(0.5),
          borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: TColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: TSizes.sm),
            Expanded(
              child: Text(
                'Connect your exercise app to view your steps data',
                style: TextStyle(
                  color: TColors.textSecondary,
                  fontSize: TSizes.fontSizeSm,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}