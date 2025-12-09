import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../utils/constants/admin_colors.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/admin_dashboard_controller.dart';
import '../achievement_management/achievement_management_screen.dart';
import '../community_management/community_management_screen.dart';
import '../manager_management/manager_management_screen.dart';
import '../profile/admin_profile_screen.dart';
import '../report/transaction_report_screen.dart';
import '../report/user_analytics_screen.dart';
import '../reward_management/reward_management_screen.dart';
import '../transaction_management/transaction_management_screen.dart';
import '../user_management/user_management_screen.dart';
import 'widgets/admin_header.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/dashboard_stats_cards.dart';
import 'widgets/recent_users_widget.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminDashboardController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: TAdminColors.getBackgroundColor(darkMode),
      body: Row(
        children: [
          // Sidebar
          AdminSidebar(),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Header
                AdminHeader(),

                // Content Area
                Expanded(
                  child: Obx(() => _buildContent(controller.selectedIndex.value, darkMode)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildContent(int selectedIndex, bool darkMode) {
    switch (selectedIndex) {
      case 0: // Dashboard
        return _buildDashboardContent(darkMode);
      case 1: // User Management
        return UserManagementScreen();
      case 2: // Manager Management
        return ManagerManagementScreen();
      case 3: // Community Management
        return CommunityManagementScreen();
      case 4: // Achievement Management
        return AchievementManagementScreen();
      case 5: // Reward Management
        return RewardManagementScreen();
      case 6: // Transaction Management
        return TransactionManagementScreen();
      case 7: // Analytics
        return _buildPlaceholder('Analytics', darkMode);
      case 71: return TransactionReportScreen();
      case 72: return UserAnalyticsScreen();
      case 8: // Profile
        return AdminProfileScreen();
      default:
        return _buildDashboardContent(darkMode);
    }
  }

  Widget _buildDashboardContent(bool darkMode) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard Overview',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: TAdminColors.getOnSurfaceColor(darkMode),
            ),
          ),
          SizedBox(height: 24),

          // Stats Cards
          DashboardStatsCards(),

          SizedBox(height: 32),

          // Recent Users
          RecentUsersWidget(),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String title, bool darkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.setting_bold,
            size: 64,
            color: TAdminColors.getOnSurfaceVariantColor(darkMode),
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: TAdminColors.getOnSurfaceColor(darkMode),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Coming soon...',
            style: TextStyle(
              color: TAdminColors.getOnSurfaceVariantColor(darkMode),
            ),
          ),
        ],
      ),
    );
  }
}