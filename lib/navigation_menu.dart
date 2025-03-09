import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import 'src/features/community/views/community_menu.dart';
import 'src/features/home/views/home.dart';
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
      bottomNavigationBar: Obx(
          () => NavigationBar(
              height: 80,
              elevation: 0,
              selectedIndex: controller.selectedIndex.value,  // 默认选中的索引（第一个 "Home"）
              onDestinationSelected: (index) => controller.selectedIndex.value = index,  // 用户选择的 index，需要传递给 selectedIndex
              backgroundColor: darkMode ? TColors.black : TColors.white,
              indicatorColor: darkMode ? TColors.white.withValues(alpha: 0.1) : TColors.black.withValues(alpha: 0.1),
              destinations: [  // 定义导航项（Tabs）
                NavigationDestination(icon: Icon(Iconsax.home_1_bold), label: 'Home'),
                NavigationDestination(icon: Icon(Iconsax.calendar_1_bold), label: 'Planning'),
                NavigationDestination(icon: Icon(Iconsax.profile_2user_bold), label: 'Community'),
                NavigationDestination(icon: Icon(Iconsax.user_bold), label: 'Profile'),
              ]
          ),
      ),
      body: Obx(() => controller.screens[controller.selectedIndex.value]),
    );
  }
}

class NavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;

  final screens = [const HomeScreen(), Container(color: Colors.purple,), const CommunityMenu(), const SettingsScreen(),];
}
