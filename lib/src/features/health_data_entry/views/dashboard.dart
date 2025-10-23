import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../common/widgets/custom_shapes/containers/primary_header_container.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../controllers/blood_glucose_controller.dart';
import '../controllers/blood_pressure_controller.dart';
import '../controllers/exercise_controller.dart';
import '../controllers/weight_controller.dart';
import 'health_data_analytics/blood_glucose_analytics_screen.dart';
import 'health_data_analytics/blood_pressure_analytics_screen.dart';
import 'health_data_analytics/weight_analytics_screen.dart';
import 'health_data_analytics/exercise_screen.dart';
import 'health_data_entry/health_data_entry_screen.dart';
import 'widgets/home_appbar.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late PageController _pageController;
  late Timer _timer;
  int _currentPage = 0;

  final List<HealthTip> _healthTips = [
    HealthTip(
      title: "Stay Hydrated",
      content:
          "Maintaining a healthy lifestyle provides a combination of balanced nutrition, regular physical activity, sufficient sleep, and stress management.",
    ),
    HealthTip(
      title: "Regular Exercise",
      content:
          "Engaging in regular physical activity helps maintain cardiovascular health, strengthens muscles, and improves mental wellbeing.",
    ),
    HealthTip(
      title: "Balanced Diet",
      content:
          "A nutritious diet rich in fruits, vegetables, whole grains, and lean proteins supports overall health and disease prevention.",
    ),
    HealthTip(
      title: "Quality Sleep",
      content:
          "Getting 7-9 hours of quality sleep each night is essential for physical recovery, mental clarity, and immune system function.",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentPage < _healthTips.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    // Initialize controllers
    final glucoseController = Get.put(BloodGlucoseController());
    final pressureController = Get.put(BloodPressureController());
    final weightController = Get.put(WeightController());
    final exerciseController = Get.put(ExerciseController());

    return Scaffold(
      backgroundColor:
          darkMode ? const Color(0xFF0A0A0B) : const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// -- Header Container with Floating Tips --
            SizedBox(
              height: 230,
              child: Stack(
                clipBehavior: Clip.none,  // 允许子组件溢出
                children: [
                  TPrimaryHeaderContainer(
                    child: Column(
                      children: [
                        /// -- Appbar --
                        THomeAppBar(title: 'Dashboard'),
                        const SizedBox(height: TSizes.spaceBtwSections),

                        // /// -- Spacer for floating card --
                        // const SizedBox(height: 10), // Space for floating card
                        const SizedBox(height: TSizes.spaceBtwSections),
                      ],
                    ),
                  ),

                  /// -- Floating Health Tips Card --
                  Positioned(
                    top: 100,
                    left: TSizes.defaultSpace,
                    right: TSizes.defaultSpace,
                    child: Transform.translate(
                      offset: const Offset(0, 40), // Offset to span boundary
                      child: _buildFloatingHealthTips(context, darkMode),
                    ),
                  ),
                ],
              ),
            ),

            /// -- Main Content with top margin for floating card --
            Container(
              margin: const EdgeInsets.only(top: 120), // Space for floating card
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              child: Column(
                children: [
                  // Health Metrics Cards (Single Column)
                  _buildHealthMetricsList(
                    context,
                    darkMode,
                    glucoseController,
                    pressureController,
                    weightController,
                    exerciseController,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      /// -- Floating Action Button for Quick Data Entry --
      floatingActionButton: FloatingActionButton(
        heroTag: 'dashboard_fab',
        onPressed: () => Get.to(() => const HealthDataEntryScreen()),
        backgroundColor: TColors.primary,
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  /// Floating Health Tips Widget
  Widget _buildFloatingHealthTips(BuildContext context, bool darkMode) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          height: 170,
          decoration: BoxDecoration(
            color: darkMode ? TColors.dark : Colors.white,
            borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
            boxShadow: [
              BoxShadow(
                color: darkMode
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.2),
                spreadRadius: 0,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
            child: PageView.builder( // 直接使用 PageView，不需要 Stack
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _healthTips.length,
              itemBuilder: (context, index) {
                return _buildHealthTipContent(
                    context, _healthTips[index], darkMode);
              },
            ),
          ),
        ),
        SizedBox(height: TSizes.lg),

        /// Page indicators
        _buildPageIndicators(darkMode),
      ],
    );
  }

  /// Health Tip Content
  Widget _buildHealthTipContent(
      BuildContext context, HealthTip tip, bool darkMode) {
    return Padding(
      padding: const EdgeInsets.all(TSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.tips_and_updates_outlined,
                  color: TColors.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: TSizes.sm),
              Text(
                tip.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: darkMode ? TColors.white : TColors.black,
                    ),
              ),
            ],
          ),
          SizedBox(height: TSizes.sm),
          Expanded(
            child: Text(
              tip.content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: darkMode ? TColors.grey : Colors.grey.shade600,
                    height: 1.4,
                  ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Page Indicators
  Widget _buildPageIndicators(bool darkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _healthTips.length,
        (index) => _buildDot(
          isActive: index == _currentPage,
          darkMode: darkMode,
        ),
      ),
    );
  }

  /// Dot Indicator
  Widget _buildDot({required bool isActive, required bool darkMode}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isActive ? 20 : 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isActive
            ? TColors.primary
            : (darkMode ? Colors.grey.shade600 : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildHealthMetricsList(
    BuildContext context,
    bool darkMode,
    BloodGlucoseController glucoseController,
    BloodPressureController pressureController,
    WeightController weightController,
    ExerciseController exerciseController,
  ) {
    return Column(
      children: [
        // Blood Glucose Card
        Obx(() => _buildGlucoseCard(context, darkMode, glucoseController)),

        const SizedBox(height: TSizes.lg),

        // Blood Pressure Card
        Obx(() => _buildPressureCard(context, darkMode, pressureController)),

        const SizedBox(height: TSizes.lg),

        // Weight Card
        Obx(() => _buildWeightCard(context, darkMode, weightController)),

        const SizedBox(height: TSizes.lg),

        // Exercise Card
        Obx(() => _buildExerciseCard(context, darkMode, exerciseController)),

        const SizedBox(height: TSizes.lg),

        // Steps Card (placeholder - you can implement StepsController similarly)
        _buildStepsCard(context, darkMode),
      ],
    );
  }

  // Blood Glucose Card
  Widget _buildGlucoseCard(
      BuildContext context, bool darkMode, BloodGlucoseController controller) {
    final hasData = controller.past14DaysCount.value > 0;

    return GestureDetector(
      onTap: () => Get.to(() => const BloodGlucoseAnalyticsScreen()),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: darkMode ? const Color(0xFF1A1A1B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: darkMode
                ? Colors.grey.shade800.withOpacity(0.5)
                : Colors.grey.shade100,
          ),
          boxShadow: [
            BoxShadow(
              color: darkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53E3E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.opacity,
                    color: Color(0xFFE53E3E),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Blood Glucose',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              darkMode ? Colors.white : const Color(0xFF2D3748),
                        ),
                      ),
                      Text(
                        'Past 14 Days | All Periods',
                        style: TextStyle(
                          fontSize: 13,
                          color: darkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: darkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (hasData) ...[
              // Fixed average value display - large value with small unit
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    controller.averageValue.value.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF8C42),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'mmol/L (avg.)',
                    style: TextStyle(
                      fontSize: 16,
                      color: darkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGlucoseStatRow('Good', controller.goodCount.value,
                            TColors.glucoseGood),
                        const SizedBox(height: 8),
                        _buildGlucoseStatRow('High', controller.highCount.value,
                            TColors.glucoseHigh),
                        const SizedBox(height: 8),
                        _buildGlucoseStatRow('Low', controller.lowCount.value,
                            TColors.glucoseLow),
                        const SizedBox(height: 8),
                        _buildGlucoseStatRow(
                            'Total',
                            controller.past14DaysCount.value,
                            darkMode
                                ? Colors.grey.shade400
                                : Colors.grey.shade600),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Reduced gap between stats and chart
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 120,
                      child:
                          _buildGlucoseDistributionChart(controller, darkMode),
                    ),
                  ),
                ],
              ),
            ] else ...[
              _buildNoDataWidget(
                  darkMode, 'Track your blood glucose levels to see insights'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGlucoseStatRow(String label, int count, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 16), // Fixed spacing
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Blood Pressure Card
  Widget _buildPressureCard(
      BuildContext context, bool darkMode, BloodPressureController controller) {
    final hasData = controller.past14DaysCount.value > 0;

    return GestureDetector(
      onTap: () => Get.to(() => const BloodPressureAnalyticsScreen()),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: darkMode ? const Color(0xFF1A1A1B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: darkMode
                ? Colors.grey.shade800.withOpacity(0.5)
                : Colors.grey.shade100,
          ),
          boxShadow: [
            BoxShadow(
              color: darkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53E3E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFFE53E3E),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Blood Pressure',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              darkMode ? Colors.white : const Color(0xFF2D3748),
                        ),
                      ),
                      Text(
                        'Past 14 Days | All Periods',
                        style: TextStyle(
                          fontSize: 13,
                          color: darkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: darkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (hasData) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${controller.systolicAverage.value.toStringAsFixed(0)}/${controller.diastolicAverage.value.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9F7AEA),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'mmHg (avg.)',
                    style: TextStyle(
                      fontSize: 16,
                      color: darkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFF667EEA),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Systolic',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF667EEA),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFF48BB78),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Diastolic',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF48BB78),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: _buildPressureTrendChart(controller, darkMode),
              ),
            ] else ...[
              _buildNoDataWidget(
                  darkMode, 'Track your blood pressure to see trends'),
            ],
          ],
        ),
      ),
    );
  }

// Weight Card
  Widget _buildWeightCard(
      BuildContext context, bool darkMode, WeightController controller) {
    final hasData = controller.past14DaysCount.value > 0;
    final hasSingleRecord = controller.past14DaysCount.value == 1;

    String subtitle;
    String value;
    String? changeText;

    if (!hasData) {
      subtitle = 'Last Record | All Periods';
      value = 'No Data';
    } else if (hasSingleRecord) {
      final time = DateFormat('HH:mm')
          .format(controller.latestWeightRecord.value!.logDateTime);
      subtitle = 'Last Record: $time | All Periods';
      value = '${controller.weightCurrent.value.toStringAsFixed(1)} kg';
    } else {
      final change =
          controller.weightCurrent.value - controller.weightEarliest.value;
      final changePrefix = change >= 0 ? 'Increase' : 'Decrease';
      changeText = '$changePrefix ${change.abs().toStringAsFixed(1)} kg';
      subtitle =
          'Last Record: ${DateFormat('HH:mm').format(controller.latestWeightRecord.value!.logDateTime)} | All Periods';
      value = '${controller.weightCurrent.value.toStringAsFixed(1)} kg';
    }

    return GestureDetector(
      onTap: () => Get.to(() => const WeightAnalyticsScreen()),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: darkMode ? const Color(0xFF1A1A1B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: darkMode
                ? Colors.grey.shade800.withOpacity(0.5)
                : Colors.grey.shade100,
          ),
          boxShadow: [
            BoxShadow(
              color: darkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38B2AC).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.monitor_weight_outlined,
                    color: Color(0xFF38B2AC),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weight',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              darkMode ? Colors.white : const Color(0xFF2D3748),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: darkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: darkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (hasData) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    controller.weightCurrent.value.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF38B2AC),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'kg',
                    style: TextStyle(
                      fontSize: 16,
                      color: darkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),

              // Show change text for multiple records
              if (changeText != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Past 14 Days | $changeText',
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        darkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],

              if (!hasSingleRecord) ...[
                const SizedBox(height: 20),
                SizedBox(
                  height: 120,
                  child: _buildWeightTrendChart(controller, darkMode),
                ),
              ],
            ] else ...[
              _buildNoDataWidget(
                  darkMode, 'Track your weight to monitor changes'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(
      BuildContext context, bool darkMode, ExerciseController controller) {
    return GestureDetector(
      onTap: () => Get.to(() => const ExerciseScreen()),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: darkMode ? const Color(0xFF1A1A1B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: darkMode
                ? Colors.grey.shade800.withOpacity(0.5)
                : Colors.grey.shade100,
          ),
          boxShadow: [
            BoxShadow(
              color: darkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.directions_run_rounded,
                    color: Color(0xFF4A90E2),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exercise',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              darkMode ? Colors.white : const Color(0xFF2D3748),
                        ),
                      ),
                      Text(
                        'Total Time This Week',
                        style: TextStyle(
                          fontSize: 13,
                          color: darkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: darkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(children: [
              Text(
                controller.weeklyExerciseMinutes.value > 0
                    ? '${controller.weeklyExerciseMinutes.value}'
                    : 'No Data',
                style: TextStyle(
                  fontSize:
                      controller.weeklyExerciseMinutes.value > 0 ? 32 : 24,
                  fontWeight: FontWeight.bold,
                  color: controller.weeklyExerciseMinutes.value > 0
                      ? const Color(0xFF4A90E2)
                      : (darkMode
                          ? Colors.grey.shade500
                          : Colors.grey.shade400),
                ),
              ),

              const SizedBox(width: 8),
              Text(
                'min',
                style: TextStyle(
                  fontSize: 16,
                  color: darkMode
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                ),
              ),
            ]),
            const SizedBox(height: 20),
            Text(
              'Weekly Goal: 150 min',
              style: TextStyle(
                fontSize: 14,
                color: darkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsCard(BuildContext context, bool darkMode) {
    // This is a placeholder - you can implement a StepsController similarly
    const todaySteps = 0; // Replace with actual data
    const isConnected = false; // Replace with actual connection status

    return GestureDetector(
      onTap: () {
        // TODO: Navigate to steps screen
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: darkMode ? const Color(0xFF1A1A1B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: darkMode
                ? Colors.grey.shade800.withOpacity(0.5)
                : Colors.grey.shade100,
          ),
          boxShadow: [
            BoxShadow(
              color: darkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.directions_walk_rounded,
                    color: Color(0xFF4A90E2),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Steps',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              darkMode ? Colors.white : const Color(0xFF2D3748),
                        ),
                      ),
                      Text(
                        'Total Today',
                        style: TextStyle(
                          fontSize: 13,
                          color: darkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: darkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              isConnected ? '$todaySteps steps' : 'Not Connected',
              style: TextStyle(
                fontSize: isConnected ? 32 : 24,
                fontWeight: FontWeight.bold,
                color: isConnected
                    ? const Color(0xFF4A90E2)
                    : (darkMode ? Colors.grey.shade500 : Colors.grey.shade400),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Daily Goal: 7,500 steps',
              style: TextStyle(
                fontSize: 14,
                color: darkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlucoseDistributionChart(
      BloodGlucoseController controller, bool darkMode) {
    if (controller.past14DaysCount.value == 0) {
      return _buildNoDataWidget(darkMode, 'No glucose data');
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 3,
        centerSpaceRadius: 35, // Larger center space for bigger chart
        sections: [
          if (controller.goodCount.value > 0)
            PieChartSectionData(
              value: controller.goodCount.value.toDouble(),
              color: TColors.glucoseGood,
              radius: 35,
              // Larger radius
              showTitle: true,
              title:
                  '${((controller.goodCount.value / controller.past14DaysCount.value) * 100).toInt()}%',
              titleStyle: const TextStyle(
                fontSize: 14, // Slightly larger text
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          if (controller.highCount.value > 0)
            PieChartSectionData(
              value: controller.highCount.value.toDouble(),
              color: TColors.glucoseHigh,
              radius: 35,
              showTitle: true,
              title:
                  '${((controller.highCount.value / controller.past14DaysCount.value) * 100).toInt()}%',
              titleStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          if (controller.lowCount.value > 0)
            PieChartSectionData(
              value: controller.lowCount.value.toDouble(),
              color: TColors.glucoseLow,
              radius: 35,
              showTitle: true,
              title:
                  '${((controller.lowCount.value / controller.past14DaysCount.value) * 100).toInt()}%',
              titleStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPressureTrendChart(
      BloodPressureController controller, bool darkMode) {

    // 直接使用 controller 中已经生成的趋势数据和标签
    final systolicData = controller.systolicTrendsData;
    final diastolicData = controller.diastolicTrendsData;
    final dateLabels = controller.trendsLabels;

    final dataCount = systolicData.length;

    // 动态计算 Y 轴范围
    double calculateMinY() {
      if (systolicData.isEmpty && diastolicData.isEmpty) return 0;

      final allValues = [
        ...systolicData.map((spot) => spot.y),
        ...diastolicData.map((spot) => spot.y)
      ];

      final minValue = allValues.reduce((a, b) => a < b ? a : b);
      // 确保最小值不会太低，但也不要过度压缩图表
      return (minValue ~/ 10) * 10 - 10;
    }

    double calculateMaxY() {
      if (systolicData.isEmpty && diastolicData.isEmpty) return 200;

      final allValues = [
        ...systolicData.map((spot) => spot.y),
        ...diastolicData.map((spot) => spot.y)
      ];

      final maxValue = allValues.reduce((a, b) => a > b ? a : b);
      // 确保最大值不会太高，但留有适当空间
      double calculatedMin = (maxValue ~/ 10 + 1) * 10 + 10;
      return calculatedMin < 0 ? 0 : calculatedMin;
    }

    double calculateYInterval(double minY, double maxY) {
      final range = maxY - minY;
      if (range <= 20) return 5;
      if (range <= 50) return 10;
      if (range <= 100) return 20;
      return 50;
    }

    final minY = calculateMinY();
    final maxY = calculateMaxY();
    final yInterval = calculateYInterval(minY, maxY);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: darkMode ? Colors.grey.shade800 : Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: yInterval,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: darkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < dateLabels.length) {
                  return Text(
                    dateLabels[index].split('\n')[0], // 只取日期部分，去掉时间
                    style: TextStyle(
                      fontSize: 12,
                      color: darkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (dataCount - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: systolicData,
            isCurved: true,
            color: const Color(0xFF667EEA),
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFF667EEA),
                  strokeColor: Colors.white,
                  strokeWidth: 2,
                );
              },
            ),
          ),
          LineChartBarData(
            spots: diastolicData,
            isCurved: true,
            color: const Color(0xFF48BB78),
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFF48BB78),
                  strokeColor: Colors.white,
                  strokeWidth: 2,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightTrendChart(WeightController controller, bool darkMode) {
    // 使用 controller 中已经生成的趋势数据和标签
    final weightData = controller.weightTrendsData;
    final dateLabels = controller.trendsLabels;

    // 动态计算 Y 轴范围
    double calculateDynamicMinY() {
      if (weightData.isEmpty) return 50;

      final allValues = weightData.map((spot) => spot.y).toList();
      final minValue = allValues.reduce((a, b) => a < b ? a : b);

      // 向下取整到最近的5，并留一些边距，但确保不小于20
      double calculatedMin = (minValue ~/ 5) * 5 - 5;
      return calculatedMin < 0 ? 0 : calculatedMin;
    }

    double calculateDynamicMaxY() {
      if (weightData.isEmpty) return 100;

      final allValues = weightData.map((spot) => spot.y).toList();
      final maxValue = allValues.reduce((a, b) => a > b ? a : b);

      // 向上取整到最近的5，并留一些边距
      return (maxValue ~/ 5 + 1) * 5 + 5;
    }

    double calculateYInterval(double minY, double maxY) {
      final range = maxY - minY;
      if (range <= 20) return 5;
      if (range <= 40) return 10;
      if (range <= 80) return 20;
      return 25;
    }

    // 使用动态计算的 Y 轴范围
    final dynamicMinY = calculateDynamicMinY();
    final dynamicMaxY = calculateDynamicMaxY();
    final yInterval = calculateYInterval(dynamicMinY, dynamicMaxY);

    // 处理 X 轴标签：只显示日期部分，去掉时间
    List<String> getDateOnlyLabels() {
      return dateLabels.map((label) {
        // 如果标签包含换行符（日期和时间），只取日期部分
        if (label.contains('\n')) {
          return label.split('\n')[0];
        }
        // 如果已经是纯日期，直接返回
        return label;
      }).toList();
    }

    final dateOnlyLabels = getDateOnlyLabels();
    final dataCount = weightData.length;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval, // 使用动态间隔
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: darkMode ? Colors.grey.shade800 : Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: yInterval, // 使用动态间隔
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: darkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1, // 每个数据点都显示标签
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < dateOnlyLabels.length) {
                  return Text(
                    dateOnlyLabels[index],
                    style: TextStyle(
                      fontSize: 12,
                      color: darkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (dataCount - 1).toDouble(),
        minY: dynamicMinY, // 使用动态计算的最小值
        maxY: dynamicMaxY, // 使用动态计算的最大值
        lineBarsData: [
          LineChartBarData(
            spots: weightData,
            isCurved: true,
            color: const Color(0xFF38B2AC),
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFF38B2AC),
                  strokeColor: Colors.white,
                  strokeWidth: 2,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataWidget(bool darkMode, String message) {
    return Container(
      height: 100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_chart_outlined_rounded,
            size: 32,
            color: darkMode ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: darkMode ? Colors.grey.shade500 : Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Health Tip Model
class HealthTip {
  final String title;
  final String content;

  HealthTip({
    required this.title,
    required this.content,
  });
}

class TNotificationIcon extends StatelessWidget {
  const TNotificationIcon({
    super.key,
    required this.iconColor,
    required this.onPressed,
  });

  final Color iconColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: IconButton(
        onPressed: onPressed,
        icon: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Iconsax.notification_bold,
                color: Colors.white,
                size: 20,
              ),
            ),
            // Notification badge
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF4757),
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: const Text(
                  '3',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
