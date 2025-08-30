import 'package:get/get.dart';

import '../../../data/repositories/authentication/authentication_repository.dart';

class AdminDashboardController extends GetxController {
  static AdminDashboardController get instance => Get.find();

  final selectedIndex = 0.obs;
  final sidebarExpanded = true.obs;
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
          {'icon': 'community', 'title': 'Community Management', 'index': 2, 'roles': ['admin']},
          {'icon': 'achievement', 'title': 'Achievement Management', 'index': 3, 'roles': ['admin']},
          {'icon': 'analytics', 'title': 'Analytics', 'index': 4, 'roles': ['admin']},
          {'icon': 'settings', 'title': 'Settings', 'index': 5, 'roles': ['admin']},
        ]);
        break;

      case 'user manager':
        items.addAll([
          {'icon': 'user_management', 'title': 'User Management', 'index': 1, 'roles': ['user manager']},
          {'icon': 'analytics', 'title': 'User Analytics', 'index': 4, 'roles': ['user manager']},
        ]);
        break;

      case 'community manager':
        items.addAll([
          {'icon': 'community', 'title': 'Community Management', 'index': 2, 'roles': ['community manager']},
          {'icon': 'analytics', 'title': 'Community Analytics', 'index': 4, 'roles': ['community manager']},
        ]);
        break;

      case 'achievement manager':
        items.addAll([
          {'icon': 'achievement', 'title': 'Achievement Management', 'index': 3, 'roles': ['achievement manager']},
          {'icon': 'analytics', 'title': 'Achievement Analytics', 'index': 4, 'roles': ['achievement manager']},
        ]);
        break;
    }

    // Filter items based on user role
    menuItems.value = items.where((item) {
      final roles = item['roles'] as List<String>;
      return roles.contains(role);
    }).toList();
  }

  void selectMenuItem(int index) {
    selectedIndex.value = index;
  }

  void toggleSidebar() {
    sidebarExpanded.value = !sidebarExpanded.value;
  }

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
}