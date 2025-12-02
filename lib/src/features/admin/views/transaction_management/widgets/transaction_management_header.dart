import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../utils/constants/admin_colors.dart';
import '../../../../../utils/constants/enums.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/transaction_management_controller.dart';
import 'custom_date_range_dialog.dart';

class TransactionManagementHeader extends StatelessWidget {
  final TransactionManagementController controller;

  const TransactionManagementHeader({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Transaction Management',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: TAdminColors.getOnSurfaceColor(darkMode),
                        ),
                      ),
                      SizedBox(width: 16),
                      Obx(() => Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: TAdminColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: TAdminColors.primary.withOpacity(0.3)),
                        ),
                        child: Text(
                          '${controller.totalCount.value} Transactions',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: TAdminColors.primary,
                          ),
                        ),
                      )),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'View and analyze all payment transactions',
                    style: TextStyle(
                      fontSize: 16,
                      color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 24),

            // Search and actions
            Row(
              children: [
                // Search bar
                Container(
                  width: 320,
                  child: TextField(
                    controller: controller.searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by ID, amount, method...',
                      hintStyle: TextStyle(
                        color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                      ),
                      prefixIcon: Icon(
                        Iconsax.search_normal_1_bold,
                        color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                        size: 20,
                      ),
                      suffixIcon: ValueListenableBuilder(
                        valueListenable: controller.searchController,
                        builder: (context, value, child) {
                          return value.text.isNotEmpty
                              ? IconButton(
                            icon: Icon(
                              Iconsax.close_circle_bold,
                              color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                              size: 20,
                            ),
                            onPressed: () {
                              controller.searchController.clear();
                            },
                          )
                              : const SizedBox.shrink();
                        },
                      ),
                      filled: true,
                      fillColor: TAdminColors.getSurfaceVariantColor(darkMode),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: TAdminColors.primary, width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    style: TextStyle(
                      color: TAdminColors.getOnSurfaceColor(darkMode),
                    ),
                  ),
                ),

                SizedBox(width: 16),

                // Refresh button
                Container(
                  decoration: BoxDecoration(
                    color: TAdminColors.getSurfaceVariantColor(darkMode),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: TAdminColors.getBorderColor(darkMode),
                    ),
                  ),
                  child: IconButton(
                    onPressed: controller.refreshTransactions,
                    icon: Obx(() => AnimatedRotation(
                      turns: controller.isLoading.value ? 1.0 : 0.0,
                      duration: Duration(milliseconds: 1000),
                      child: Icon(
                        Iconsax.refresh_bold,
                        color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                        size: 20,
                      ),
                    )),
                    tooltip: 'Refresh transactions',
                    style: IconButton.styleFrom(
                      minimumSize: Size(48, 48),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        SizedBox(height: 24),

        // Filter controls
        Row(
          children: [
            // Period filter
            Container(
              height: 48,
              child: Obx(() => _buildPeriodFilter(darkMode)),
            ),

            SizedBox(width: 16),

            // Status filter
            Container(
              height: 48,
              child: Obx(() => _buildStatusFilter(darkMode)),
            ),

            const Spacer(),

            // Entries per page
            Row(
              children: [
                Text(
                  'Show',
                  style: TextStyle(
                    color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 48,
                  child: Obx(() => DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: controller.itemsPerPage.value,
                      onChanged: controller.changeItemsPerPage,
                      items: controller.itemsPerPageOptions
                          .map((items) => DropdownMenuItem(
                        value: items,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Text(
                            '$items',
                            style: TextStyle(
                              color: TAdminColors.getOnSurfaceColor(darkMode),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ))
                          .toList(),
                      style: TextStyle(
                        color: TAdminColors.getOnSurfaceColor(darkMode),
                      ),
                      dropdownColor: TAdminColors.getSurfaceColor(darkMode),
                      borderRadius: BorderRadius.circular(8),
                      icon: Icon(
                        Iconsax.arrow_down_1_bold,
                        color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                      ),
                    ),
                  )),
                ),
                const SizedBox(width: 8),
                Text(
                  'entries',
                  style: TextStyle(
                    color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodFilter(bool darkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceVariantColor(darkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: TAdminColors.getBorderColor(darkMode),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controller.selectedPeriod.value,
          onChanged: (value) {
            if (value == 'custom') {
              _showCustomDateRangeDialog();
            } else if (value != null) {
              controller.changePeriodFilter(value);
            }
          },
          items: [
            DropdownMenuItem<String>(
              value: 'all',
              child: _buildPeriodItem('All Time', Iconsax.calendar_bold, darkMode),
            ),
            DropdownMenuItem<String>(
              value: '7days',
              child: _buildPeriodItem('Last 7 Days', Iconsax.calendar_1_bold, darkMode),
            ),
            DropdownMenuItem<String>(
              value: '30days',
              child: _buildPeriodItem('Last 30 Days', Iconsax.calendar_2_bold, darkMode),
            ),
            DropdownMenuItem<String>(
              value: '90days',
              child: _buildPeriodItem('Last 90 Days', Iconsax.calendar_tick_bold, darkMode),
            ),
            DropdownMenuItem<String>(
              value: 'custom',
              child: _buildPeriodItem('Custom Range', Iconsax.calendar_edit_bold, darkMode),
            ),
          ],
          style: TextStyle(
            color: TAdminColors.getOnSurfaceColor(darkMode),
          ),
          dropdownColor: TAdminColors.getSurfaceColor(darkMode),
          borderRadius: BorderRadius.circular(8),
          icon: Icon(
            Iconsax.arrow_down_1_bold,
            color: TAdminColors.getOnSurfaceVariantColor(darkMode),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodItem(String text, IconData icon, bool darkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: TAdminColors.getOnSurfaceVariantColor(darkMode),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: TAdminColors.getOnSurfaceColor(darkMode),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFilter(bool darkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceVariantColor(darkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: TAdminColors.getBorderColor(darkMode),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PaymentStatus?>(
          value: controller.selectedStatus.value,
          onChanged: (value) => controller.changeStatusFilter(value),
          items: [
            DropdownMenuItem<PaymentStatus?>(
              value: null,
              child: _buildStatusItem('All Status', Iconsax.filter_bold, null, darkMode),
            ),
            ...PaymentStatus.values.map((status) {
              IconData icon;
              Color color;

              switch (status) {
                case PaymentStatus.succeeded:
                  icon = Iconsax.tick_circle_bold;
                  color = TAdminColors.success;
                  break;
                case PaymentStatus.failed:
                  icon = Iconsax.close_circle_bold;
                  color = TAdminColors.error;
                  break;
                case PaymentStatus.pending:
                  icon = Iconsax.clock_bold;
                  color = TAdminColors.warning;
                  break;
              }

              return DropdownMenuItem<PaymentStatus?>(
                value: status,
                child: _buildStatusItem(status.displayName, icon, color, darkMode),
              );
            }).toList(),
          ],
          style: TextStyle(
            color: TAdminColors.getOnSurfaceColor(darkMode),
          ),
          dropdownColor: TAdminColors.getSurfaceColor(darkMode),
          borderRadius: BorderRadius.circular(8),
          icon: Icon(
            Iconsax.arrow_down_1_bold,
            color: TAdminColors.getOnSurfaceVariantColor(darkMode),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem(String text, IconData icon, Color? color, bool darkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: color ?? TAdminColors.getOnSurfaceVariantColor(darkMode),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: TAdminColors.getOnSurfaceColor(darkMode),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showCustomDateRangeDialog() {
    Get.dialog(
      CustomDateRangeDialog(
        controller: controller,
      ),
      barrierDismissible: true,
    );
  }
}