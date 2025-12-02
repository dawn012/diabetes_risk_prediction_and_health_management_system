import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../data/repositories/authentication/authentication_repository.dart';

class AdminDashboardController extends GetxController {
  static AdminDashboardController get instance => Get.find();

  final selectedIndex = 0.obs;
  final sidebarExpanded = true.obs;
  final analyticsExpanded = false.obs;
  final authRepo = AuthenticationRepository.instance;
  final userRole = ''.obs;

  // SideBar menu items based on role
  final menuItems = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initializeMenuItems();
  }

  void _initializeMenuItems() async {
    final role = await authRepo.getUserRole();
    userRole.value = role;

    // Define menu items based on role
    List<Map<String, dynamic>> items = [
      {
        'icon': 'dashboard',
        'title': 'Dashboard',
        'index': 0,
        'type': 'menu',
        'roles': ['admin', 'user manager', 'community manager', 'achievement manager', 'reward manager']
      },
    ];

    // Add role-specific menu items
    switch (role) {
      case 'admin':
        items.addAll([
          {'icon': 'user_management', 'title': 'User Management', 'index': 1, 'type': 'menu', 'roles': ['admin']},
          {'icon': 'manager_management', 'title': 'Manager Management', 'index': 2, 'type': 'menu', 'roles': ['admin']},
          {'icon': 'community', 'title': 'Community Management', 'index': 3, 'type': 'menu', 'roles': ['admin']},
          {'icon': 'achievement', 'title': 'Achievement Management', 'index': 4, 'type': 'menu', 'roles': ['admin']},
          {'icon': 'reward', 'title': 'Reward Management', 'index': 5, 'type': 'menu', 'roles': ['admin']},
          {'icon': 'transaction', 'title': 'Transaction Management', 'index': 6, 'type': 'menu', 'roles': ['admin']},
          {'icon': 'analytics', 'title': 'Analytics', 'index': 7, 'type': 'expandable', 'roles': ['admin']},
          {'icon': 'profile', 'title': 'Profile', 'index': 8, 'type': 'menu', 'roles': ['admin']},
        ]);
        break;

      case 'user manager':
        items.addAll([
          {'icon': 'user_management', 'title': 'User Management', 'index': 1, 'type': 'menu', 'roles': ['user manager']},
          {'icon': 'analytics', 'title': 'Analytics', 'index': 7, 'type': 'expandable', 'roles': ['user manager']},
          {'icon': 'profile', 'title': 'Profile', 'index': 8, 'type': 'menu', 'roles': ['user manager']},
        ]);
        break;

      case 'community manager':
        items.addAll([
          {'icon': 'community', 'title': 'Community Management', 'index': 3, 'type': 'menu', 'roles': ['community manager']},
          {'icon': 'profile', 'title': 'Profile', 'index': 8, 'type': 'menu', 'roles': ['community manager']},
        ]);
        break;

      case 'achievement manager':
        items.addAll([
          {'icon': 'achievement', 'title': 'Achievement Management', 'index': 4, 'type': 'menu', 'roles': ['achievement manager']},
          {'icon': 'profile', 'title': 'Profile', 'index': 8, 'type': 'menu', 'roles': ['achievement manager']},
        ]);
        break;

      case 'reward manager':
        items.addAll([
          {'icon': 'reward', 'title': 'Reward Management', 'index': 5, 'type': 'menu', 'roles': ['reward manager']},
          {'icon': 'profile', 'title': 'Profile', 'index': 8, 'type': 'menu', 'roles': ['reward manager']},
        ]);
        break;
    }

    // Filter items based on user role
    menuItems.value = items.where((item) {
      final roles = item['roles'] as List<String>;
      return roles.contains(role);
    }).toList();
  }

  /// Convert icon string to IconData
  IconData getIconData(String iconName) {
    switch (iconName) {
      case 'dashboard':
        return Iconsax.element_3_bold;
      case 'user_management':
      case 'manager_management':
        return Iconsax.people_bold;
      case 'community':
        return Iconsax.messages_3_bold;
      case 'achievement':
        return Iconsax.award_bold;
      case 'reward':
        return Iconsax.gift_bold;
      case 'transaction':
        return Iconsax.transaction_minus_bold;
      case 'analytics':
        return Iconsax.chart_bold;
      case 'profile':
        return Iconsax.user_bold;
      default:
        return Iconsax.element_3_bold;
    }
  }

  /// Toggle sidebar expansion
  void toggleSidebar() {
    sidebarExpanded.value = !sidebarExpanded.value;

    // Close analytics menu when sidebar is collapsed
    if (!sidebarExpanded.value) {
      analyticsExpanded.value = false;
    }
  }

  /// Toggle analytics submenu
  void toggleAnalyticsMenu() {
    if (sidebarExpanded.value) {
      analyticsExpanded.value = !analyticsExpanded.value;
    }
  }

  /// Select menu item with enhanced logic for analytics submenu
  void selectMenuItem(int index) {
    // Handle main menu items
    if (index < 70) {
      selectedIndex.value = index;

      // If selecting Analytics main item, toggle submenu
      if (index == 7 && sidebarExpanded.value) {
        toggleAnalyticsMenu();
        return;
      }

      // Close analytics submenu when selecting other items
      if (index != 7) {
        analyticsExpanded.value = false;
      }
    }

    // Handle analytics submenu items (60-69)
    else if (index >= 70 && index < 80) {
      selectedIndex.value = index;

      // Ensure analytics menu is expanded when selecting submenu
      if (sidebarExpanded.value) {
        analyticsExpanded.value = true;
      }
    }

    print('Selected menu item: $index');
  }

  /// Get page title based on selected index
  String getPageTitle() {
    switch (selectedIndex.value) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'User Management';
      case 2:
        return 'Management Management';
      case 3:
        return 'Community Management';
      case 4:
        return 'Achievement Management';
      case 5:
        return 'Reward Management';
      case 6:
        return 'Transaction Management';
      case 7:
        return 'Analytics';
      case 71:
        return 'Transaction Reports';
      case 72:
        return 'User Analytics';
      case 73:
        return 'Performance Reports';
      case 8:
        return 'Profile';
      default:
        return 'Dashboard';
    }
  }

  /// Check if analytics submenu should be shown for specific roles
  bool shouldShowAnalyticsSubmenu(int subIndex) {
    switch (subIndex) {
      case 71: // Transaction Reports
        return isAdmin; // Only admin can see transaction reports
      case 72: // User Analytics
        return isAdmin || isUserManager;
      case 73: // Performance Reports
        return isAdmin;
      default:
        return false;
    }
  }

  /// Get analytics submenu items based on role
  List<Map<String, dynamic>> getAnalyticsSubMenuItems() {
    List<Map<String, dynamic>> subItems = [];

    if (isAdmin) {
      subItems.addAll([
        {'icon': 'receipt_text', 'title': 'Transaction Reports', 'index': 71},
        {'icon': 'people', 'title': 'User Analytics', 'index': 72},
        {'icon': 'trend_up', 'title': 'Performance Reports', 'index': 73},
      ]);
    } else if (isUserManager) {
      subItems.add({'icon': 'people', 'title': 'User Analytics', 'index': 72});
    } else if (isCommunityManager) {
      subItems.add({'icon': 'messages_3', 'title': 'Community Analytics', 'index': 72});
    } else if (isAchievementManager) {
      subItems.add({'icon': 'award', 'title': 'Achievement Analytics', 'index': 72});
    }

    return subItems;
  }

  // Legacy getter methods (keeping for compatibility)
  String get currentUserRole => userRole.value;

  bool get isAdmin => userRole.value == 'admin';
  bool get isUserManager => userRole.value == 'user manager';
  bool get isCommunityManager => userRole.value == 'community manager';
  bool get isAchievementManager => userRole.value == 'achievement manager';
  bool get isRewardManager => userRole.value == 'reward manager';

  bool canAccessUserManagement() {
    return isAdmin || isUserManager;
  }

  bool canAccessCommunityManagement() {
    return isAdmin || isCommunityManager;
  }

  bool canAccessAchievementManagement() {
    return isAdmin || isAchievementManager;
  }

  bool canAccessRewardManagement() {
    return isAdmin || isRewardManager;
  }

  bool canAccessSettings() {
    return isAdmin;
  }

  /// Check if current user has access to specific analytics features
  bool canAccessTransactionReports() {
    return isAdmin;
  }

  bool canAccessUserAnalytics() {
    return isAdmin || isUserManager;
  }

  bool canAccessPerformanceReports() {
    return isAdmin;
  }
}