import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../utils/constants/admin_colors.dart';
import '../../../../../utils/helpers/helper_functions.dart';

class DashboardStatsCards extends StatelessWidget {
  const DashboardStatsCards({super.key});

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

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
          '1,247',
          '+12.5%',
          Iconsax.people_bold,
          TAdminColors.primary,
          darkMode,
        ),
        _buildStatCard(
          'Active Users',
          '1,089',
          '+8.2%',
          Iconsax.user_tick_bold,
          TAdminColors.success,
          darkMode,
        ),
        _buildStatCard(
          'Banned Users',
          '158',
          '-5.1%',
          Iconsax.user_remove_bold,
          TAdminColors.error,
          darkMode,
        ),
        _buildStatCard(
          'New Today',
          '23',
          '+15.3%',
          Iconsax.user_add_bold,
          TAdminColors.warning,
          darkMode,
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title,
      String value,
      String change,
      IconData icon,
      Color color,
      bool darkMode,
      ) {
    final isPositive = change.startsWith('+');

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
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPositive ? TAdminColors.success : TAdminColors.error).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isPositive ? TAdminColors.success : TAdminColors.error,
                  ),
                ),
              ),
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