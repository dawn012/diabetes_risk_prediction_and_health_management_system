import 'package:diabetes_risk_prediction_and_health_management_system/src/features/achievement/views/user_achievement_screen.dart';
import 'package:diabetes_risk_prediction_and_health_management_system/src/features/health_data_entry/views/health_data_entry/health_data_entry_screen.dart';
import 'package:diabetes_risk_prediction_and_health_management_system/src/features/health_data_entry/views/dashboard.dart';
import 'package:diabetes_risk_prediction_and_health_management_system/src/features/reminder/views/reminder_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import 'src/features/achievement/views/leaderboard_screen.dart';
import 'src/features/community/views/community_menu.dart';
import 'src/features/diabetes_prediction/controllers/diabetes_prediction_flow_manager.dart';
import 'src/features/meal_recommendation/views/meal_recommendation_form.dart';
import 'src/features/personalization/views/settings/settings.dart';
import 'src/utils/constants/colors.dart';
import 'src/utils/helpers/helper_functions.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'navigation_fab',
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: _AddMenu(darkMode: darkMode),
            ),
          );
        },
        backgroundColor: TColors.primary,
        shape: const CircleBorder(),
        child: Icon(Icons.add, color: TColors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: SafeArea(
        // 让 BottomAppBar 也有安全区
        child: Obx(
          () => BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 6,
            color: darkMode ? TColors.black : TColors.white,
            child: SizedBox(
              height: kBottomNavigationBarHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Iconsax.home_1_bold, "Dashboard", 0, controller, darkMode),
                  _buildNavItem(Iconsax.calendar_1_bold, "Meal Plan", 1, controller, darkMode),
                  const SizedBox(width: 40),
                  _buildNavItem(Iconsax.profile_2user_bold, "Community", 2, controller, darkMode),
                  _buildNavItem(Iconsax.more_outline, "More", 3, controller, darkMode),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Obx(
        () => controller.screens[controller.selectedIndex.value],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index,
      NavigationController controller, bool darkMode) {
    final isSelected = controller.selectedIndex.value == index;
    return Flexible( // 使用 Flexible 包装
      child: InkWell(
        onTap: () => controller.selectedIndex.value = index,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected
                    ? (darkMode ? TColors.white : TColors.primary)
                    : Colors.grey,
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected
                        ? (darkMode ? TColors.white : TColors.primary)
                        : Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis, // 防止文字溢出
                  textAlign: TextAlign.center,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class NavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;

  final screens = [
    const Dashboard(),
    const MealRecommendationForm(),
    const CommunityMenu(),
    // const MealRecommendationForm(),
    const SettingsScreen(),
  ];
}

class _AddMenu extends StatelessWidget {
  final bool darkMode;

  const _AddMenu({required this.darkMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: darkMode ? TColors.darkContainer : TColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Health Data Entry",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: darkMode ? TColors.white : TColors.black,
            ),
          ),
          // const SizedBox(height: 10),
          // Text(
          //   "How should I log for better health?",
          //   style: TextStyle(
          //     fontSize: 14,
          //     color: darkMode ? TColors.grey : TColors.darkGrey,
          //   ),
          // ),
          const SizedBox(height: 20),

          // 第一行按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMenuButton("Glucose", Icons.monitor_heart_outlined, () {
                Get.back();
                Get.to(() => const HealthDataEntryScreen(initialSections: ['Blood Glucose']));
              }),
              _buildMenuButton("Pressure", Icons.favorite_border, () {
                Get.back();
                Get.to(() => const HealthDataEntryScreen(initialSections: ['Blood Pressure & Pulse']));
              }),
              _buildMenuButton("Weight", Icons.monitor_weight_outlined, () {
                Get.back();
                Get.to(() => const HealthDataEntryScreen(initialSections: ['Weight & Body Fat']));
              }),
            ],
          ),
          const SizedBox(height: 15),

          // 第二行按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMenuButton("Exercise", Icons.directions_run_outlined, () {
                Get.back();
                Get.to(() => const HealthDataEntryScreen(initialSections: ['Exercise'],));
              }),
              _buildMenuButton("Note", Icons.note, () {
                Get.back();
                Get.to(() => const HealthDataEntryScreen(initialSections: ['Note'],));
              }),
              // _buildMenuButton("Diet", Icons.restaurant_outlined),
            ],
          ),
          const SizedBox(height: 20),

          Text(
            "Shortcuts",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: darkMode ? TColors.white : TColors.black,
            ),
          ),
          const SizedBox(height: 15),

          // 快捷方式行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildShortcutButton("Predict Risk", Icons.analytics_outlined, () {
                Get.back();
                final flowManager = Get.put(DiabetesPredictionFlowManager());
                flowManager.enterPredictionFlow();
              }),
              _buildShortcutButton("Reminder", Icons.notifications_outlined, () {
                Get.back();
                Get.to(() => const ReminderScreen());
              }),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildShortcutButton("Achievement", Icons.emoji_events_outlined, () {
                Get.back();
                Get.to(() => const UserAchievementScreen());
              }),
              _buildShortcutButton("Leaderboard", Icons.leaderboard_outlined, () {
                Get.back();
                Get.to(() => const LeaderboardScreen());
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: TColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              size: 35,
              color: TColors.primary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: darkMode ? TColors.white : TColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutButton(String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: darkMode ? TColors.darkerGrey : TColors.light,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 35,
                color: TColors.primary,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: darkMode ? TColors.white : TColors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
