import 'package:get/get.dart';

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
        'roles': ['admin', 'user manager', 'community manager', 'achievement manager']
      },
    ];

    // Add role-specific menu items
    switch (role) {
      case 'admin':
        items.addAll([
          {'icon': 'user_management', 'title': 'User Management', 'index': 1, 'roles': ['admin']},
          {'icon': 'manager_management', 'title': 'Manager Management', 'index': 2, 'roles': ['admin']},
          {'icon': 'community', 'title': 'Community Management', 'index': 3, 'roles': ['admin']},
          {'icon': 'achievement', 'title': 'Achievement Management', 'index': 4, 'roles': ['admin']},
          {'icon': 'analytics', 'title': 'Analytics', 'index': 5, 'roles': ['admin']},
          {'icon': 'settings', 'title': 'Settings', 'index': 6, 'roles': ['admin']},
        ]);
        break;

      case 'user manager':
        items.addAll([
          {'icon': 'user_management', 'title': 'User Management', 'index': 1, 'roles': ['user manager']},
          {'icon': 'analytics', 'title': 'User Analytics', 'index': 5, 'roles': ['user manager']},
        ]);
        break;

      case 'community manager':
        items.addAll([
          {'icon': 'community', 'title': 'Community Management', 'index': 3, 'roles': ['community manager']},
          {'icon': 'analytics', 'title': 'Community Analytics', 'index': 5, 'roles': ['community manager']},
        ]);
        break;

      case 'achievement manager':
        items.addAll([
          {'icon': 'achievement', 'title': 'Achievement Management', 'index': 4, 'roles': ['achievement manager']},
          {'icon': 'analytics', 'title': 'Achievement Analytics', 'index': 5, 'roles': ['achievement manager']},
        ]);
        break;
    }

    // Filter items based on user role
    menuItems.value = items.where((item) {
      final roles = item['roles'] as List<String>;
      return roles.contains(role);
    }).toList();
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
    if (index < 50) {
      selectedIndex.value = index;

      // If selecting Analytics main item, toggle submenu
      if (index == 5 && sidebarExpanded.value) {
        toggleAnalyticsMenu();
        return;
      }

      // Close analytics submenu when selecting other items
      if (index != 5) {
        analyticsExpanded.value = false;
      }
    }
    // Handle analytics submenu items (50-59)
    else if (index >= 50 && index < 60) {
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
        return 'Analytics';
      case 51:
        return 'Transaction Reports';
      case 52:
        return 'User Analytics';
      case 53:
        return 'Performance Reports';
      case 6:
        return 'Profile';
      default:
        return 'Dashboard';
    }
  }

  /// Check if analytics submenu should be shown for specific roles
  bool shouldShowAnalyticsSubmenu(int subIndex) {
    switch (subIndex) {
      case 41: // Transaction Reports
        return isAdmin; // Only admin can see transaction reports
      case 42: // User Analytics
        return isAdmin || isUserManager;
      case 43: // Performance Reports
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
        {'icon': 'receipt_text', 'title': 'Transaction Reports', 'index': 41},
        {'icon': 'people', 'title': 'User Analytics', 'index': 42},
        {'icon': 'trend_up', 'title': 'Performance Reports', 'index': 43},
      ]);
    } else if (isUserManager) {
      subItems.add({'icon': 'people', 'title': 'User Analytics', 'index': 42});
    } else if (isCommunityManager) {
      subItems.add({'icon': 'messages_3', 'title': 'Community Analytics', 'index': 42});
    } else if (isAchievementManager) {
      subItems.add({'icon': 'award', 'title': 'Achievement Analytics', 'index': 42});
    }

    return subItems;
  }

  // Legacy getter methods (keeping for compatibility)
  String get currentUserRole => userRole.value;

  bool get isAdmin => userRole.value == 'admin';
  bool get isUserManager => userRole.value == 'user manager';
  bool get isCommunityManager => userRole.value == 'community manager';
  bool get isAchievementManager => userRole.value == 'achievement manager';

  bool canAccessUserManagement() {
    return isAdmin || isUserManager;
  }

  bool canAccessCommunityManagement() {
    return isAdmin || isCommunityManager;
  }

  bool canAccessAchievementManagement() {
    return isAdmin || isAchievementManager;
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