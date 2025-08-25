import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../common/widgets/custom_shapes/containers/primary_header_container.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/helpers/helper_functions.dart';
import 'widgets/home_appbar.dart';

import 'dart:async';

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

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// -- Header Container with Floating Tips --
            Stack(
              children: [
                TPrimaryHeaderContainer(
                  child: Column(
                    children: [
                      /// -- Appbar --
                      THomeAppBar(title: 'Dashboard'),
                      SizedBox(height: TSizes.spaceBtwSections),

                      /// -- Spacer for floating card --
                      SizedBox(height: 110), // 为浮动卡片留出空间
                      SizedBox(height: TSizes.spaceBtwSections),
                    ],
                  ),
                ),

                /// -- Floating Health Tips Card --
                Positioned(
                  bottom: 0,
                  left: TSizes.defaultSpace,
                  right: TSizes.defaultSpace,
                  child: Transform.translate(
                    offset: const Offset(0, 40), // 向下偏移，跨越边界
                    child: _buildFloatingHealthTips(context, darkMode),
                  ),
                ),
              ],
            ),

            /// -- Main Content with top margin for floating card --
            Container(
              margin: const EdgeInsets.only(top: 60), // 为浮动卡片留出空间
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              child: Column(
                children: [
                  /// -- Blood Glucose Section --
                  _buildHealthMetricCard(
                    context,
                    title: "Blood Glucose",
                    subtitle: "Track glucose levels",
                    value: "25",
                    unit: "mmol/L (avg.)",
                    status: "vs. prev. 14 Days",
                    color: darkMode
                        ? Colors.red.shade900.withOpacity(0.3)
                        : Colors.red.shade100,
                    icon: Icons.opacity,
                    iconColor: Colors.red,
                    hasChart: true,
                    hasData: true,
                    darkMode: darkMode,
                  ),

                  SizedBox(height: TSizes.spaceBtwItems),

                  /// -- Blood Pressure Section --
                  _buildHealthMetricCard(
                    context,
                    title: "Blood Pressure",
                    subtitle: "Last reading (24 hours)",
                    color: darkMode
                        ? Colors.red.shade900.withOpacity(0.2)
                        : Colors.red.shade50,
                    icon: Icons.favorite,
                    iconColor: Colors.red,
                    hasChart: false,
                    hasData: false,
                    darkMode: darkMode,
                  ),

                  SizedBox(height: TSizes.spaceBtwItems),

                  /// -- Additional Blood Pressure Card --
                  _buildHealthMetricCard(
                    context,
                    title: "Blood Pressure",
                    subtitle: "",
                    color: darkMode
                        ? Colors.blue.shade900.withOpacity(0.2)
                        : Colors.blue.shade50,
                    icon: Icons.monitor_heart_outlined,
                    iconColor: Colors.blue,
                    hasChart: false,
                    hasData: false,
                    darkMode: darkMode,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Floating Health Tips Widget
  Widget _buildFloatingHealthTips(BuildContext context, bool darkMode) {
    return Column(
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
            child: Stack(
              children: [
                /// PageView for tips
                PageView.builder(
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
              ],
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

  /// Health Metric Card Widget
  Widget _buildHealthMetricCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    String? value,
    String? unit,
    String? status,
    required Color color,
    required IconData icon,
    required Color iconColor,
    required bool hasChart,
    required bool hasData,
    required bool darkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        border:
            darkMode ? Border.all(color: Colors.grey.shade800, width: 1) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// -- Header --
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: darkMode ? Colors.grey.shade800 : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              SizedBox(width: TSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: darkMode ? TColors.white : TColors.black,
                          ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: darkMode
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: darkMode ? Colors.grey.shade500 : Colors.grey.shade400,
              ),
            ],
          ),

          SizedBox(height: TSizes.md),

          /// -- Content --
          if (hasData && hasChart)
            _buildChartContent(context, value!, unit!, status!, darkMode)
          else
            _buildNoDataContent(context, darkMode),
        ],
      ),
    );
  }

  /// Chart Content Widget
  Widget _buildChartContent(BuildContext context, String value, String unit,
      String status, bool darkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Value Display
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
            ),
            SizedBox(width: TSizes.xs),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                unit,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: darkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
              ),
            ),
          ],
        ),

        SizedBox(height: TSizes.xs),

        /// Status
        Text(
          status,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: darkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
        ),

        SizedBox(height: TSizes.md),

        /// Simple Chart Representation
        _buildSimpleChart(darkMode),
      ],
    );
  }

  /// No Data Content Widget
  Widget _buildNoDataContent(BuildContext context, bool darkMode) {
    return Center(
      child: Column(
        children: [
          SizedBox(height: TSizes.lg),
          Icon(
            Icons.insert_chart_outlined,
            size: 48,
            color: darkMode ? Colors.grey.shade600 : Colors.grey.shade300,
          ),
          SizedBox(height: TSizes.sm),
          Text(
            'No Data',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: darkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
          ),
          SizedBox(height: TSizes.lg),
        ],
      ),
    );
  }

  /// Simple Line Chart Widget
  Widget _buildSimpleChart(bool darkMode) {
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  // X 轴日期
                  final dates = ['Aug 6', 'Aug 7', 'Aug 8', 'Aug 9', 'Aug 10', 'Aug 11', 'Aug 12'];
                  int index = value.toInt();
                  if (index >= 0 && index < dates.length) {
                    return Text(
                      dates[index],
                      style: TextStyle(fontSize: 10, color: darkMode ? Colors.white : Colors.black),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          minX: 0,
          maxX: 6,
          minY: 0,
          maxY: 15, // mmol 上限
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              color: Colors.orange,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
              spots: const [
                FlSpot(0, 5.5),
                FlSpot(1, 6.2),
                FlSpot(2, 7.1),
                FlSpot(3, 8.3),
                FlSpot(4, 6.8),
                FlSpot(5, 5.9),
                FlSpot(6, 7.5),
              ],
            ),
          ],
        ),
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
    return Stack(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(
            Iconsax.notification_bold,
            color: iconColor,
          ),
        ),
        Positioned(
          right: 5,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: TColors.black,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Center(
              child: Text(
                '2',
                style: Theme.of(context).textTheme.labelLarge!.apply(
                      color: TColors.white,
                      fontSizeFactor: 0.8,
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
