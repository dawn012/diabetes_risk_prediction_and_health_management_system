import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../utils/constants/admin_colors.dart';
import '../../../../../utils/formatters/formatter.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/transaction_management_controller.dart';

class TransactionStatisticsCards extends StatelessWidget {
  final TransactionManagementController controller;

  const TransactionStatisticsCards({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    return Obx(() => Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Revenue',
            TFormatter.formatCurrency(controller.totalRevenue.value),
            Iconsax.money_4_bold,
            TAdminColors.success,
            darkMode,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Successful',
            '${controller.successfulTransactions.value}',
            Iconsax.tick_circle_bold,
            TAdminColors.info,
            darkMode,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Failed',
            '${controller.failedTransactions.value}',
            Iconsax.close_circle_bold,
            TAdminColors.error,
            darkMode,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Average Transaction',
            TFormatter.formatCurrency(controller.averageTransaction.value),
            Iconsax.chart_21_bold,
            TAdminColors.warning,
            darkMode,
          ),
        ),
      ],
    ));
  }

  Widget _buildStatCard(
      String label,
      String value,
      IconData icon,
      Color color,
      bool darkMode,
      ) {
    return Container(
      padding: const EdgeInsets.all(20),
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
            offset: const Offset(0, 4),
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: TAdminColors.getOnSurfaceColor(darkMode),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
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