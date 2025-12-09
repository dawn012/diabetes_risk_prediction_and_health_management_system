import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../utils/constants/admin_colors.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/dashboard_stats_controller.dart';

class DashboardStatsCards extends StatelessWidget {
  const DashboardStatsCards({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DashboardStatsController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return Obx(() {
      if (controller.isLoading.value) {
        return GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1.5,
          children: List.generate(
            4,
                (index) => _buildLoadingCard(darkMode),
          ),
        );
      }

      return GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.5,
        children: [
          _buildStatCard(
            'Total Users',
            controller.totalUsers.value.toString(),
            '',
            Iconsax.people_bold,
            TAdminColors.primary,
            darkMode,
          ),
          _buildStatCard(
            'Active Users',
            controller.activeUsersThisMonth.value.toString(),
            'This Month',
            Iconsax.user_tick_bold,
            TAdminColors.success,
            darkMode,
          ),
          _buildStatCard(
            'New Users',
            controller.newUsersThisMonth.value.toString(),
            'This Month',
            Iconsax.user_add_bold,
            TAdminColors.warning,
            darkMode,
          ),
          _buildStatCard(
            'Subscription Users',
            controller.totalSubscriptionUsers.value.toString(),
            'Active Now',
            Iconsax.crown_bold,
            TAdminColors.secondary,
            darkMode,
          ),
        ],
      );
    });
  }

  Widget _buildLoadingCard(bool darkMode) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceColor(darkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TAdminColors.getBorderColor(darkMode),
        ),
        boxShadow: [
          BoxShadow(
            color: darkMode ? Colors.black26 : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TAdminColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: TAdminColors.primary,
              ),
            ),
          ),
          Spacer(),
          Container(
            width: 80,
            height: 28,
            decoration: BoxDecoration(
              color: TAdminColors.getSurfaceVariantColor(darkMode),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: 4),
          Container(
            width: 100,
            height: 14,
            decoration: BoxDecoration(
              color: TAdminColors.getSurfaceVariantColor(darkMode),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title,
      String value,
      String subtitle,
      IconData icon,
      Color color,
      bool darkMode,
      ) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceColor(darkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TAdminColors.getBorderColor(darkMode),
        ),
        boxShadow: [
          BoxShadow(
            color: darkMode ? Colors.black26 : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ],
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: TAdminColors.getOnSurfaceColor(darkMode),
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: TAdminColors.getOnSurfaceVariantColor(darkMode),
            ),
          ),
        ],
      ),
    );
  }
}