import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../utils/constants/admin_colors.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/helpers/export_helper.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/transaction_report_controller.dart';
import 'widgets/admin_bar_chart.dart';
import 'widgets/admin_chart_export_button.dart';
import 'widgets/admin_chart_type_toggle.dart';
import 'widgets/admin_dropdown.dart';
import 'widgets/admin_line_chart.dart';
import 'widgets/admin_period_selector.dart';
import 'widgets/admin_stat_card.dart';

class TransactionReportScreen extends StatelessWidget {
  const TransactionReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TransactionReportController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 800;

            return SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                padding: EdgeInsets.all(isTablet ? 24 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(controller, darkMode, isTablet),
                    const SizedBox(height: 24),

                    // Filters
                    _buildFiltersSection(controller, darkMode, isTablet),
                    const SizedBox(height: 24),

                    // Charts Section
                    Obx(() {
                      if (controller.isLoading.value) {
                        return _buildLoadingState(darkMode);
                      }

                      if (controller.transactions.isEmpty) {
                        return _buildEmptyState(darkMode);
                      }

                      return Column(
                        children: [
                          // Chart Controls
                          _buildChartControls(controller, darkMode, isTablet),
                          const SizedBox(height: 16),

                          // Charts Container
                          _buildChartsContainer(controller, darkMode, isTablet),
                          const SizedBox(height: 24),

                          // Data Table
                          _buildDataTable(controller, darkMode, isTablet),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(TransactionReportController controller, bool darkMode, bool isTablet) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transaction Reports',
                style: TextStyle(
                  fontSize: isTablet ? 28 : 24,
                  fontWeight: FontWeight.bold,
                  color: TAdminColors.getOnSurfaceColor(darkMode),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Analyze subscription purchase trends and revenue patterns',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                ),
              ),
            ],
          ),
        ),
        // Export Button
        Obx(() => AdminChartExportButton(
          exportData: ChartExportData(
            title: 'Transaction Report - ${controller.getReportTitle()}',
            data: controller.getExportData(),
            chartKey: controller.chartKey,
            timeRange: controller.getTimeRangeText(),
            hasData: controller.transactions.isNotEmpty,
          ),
          tooltip: 'Export Report',
          showLabel: true,
        )),
      ],
    );
  }

  Widget _buildFiltersSection(TransactionReportController controller, bool darkMode, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceColor(darkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TAdminColors.getBorderColor(darkMode)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Report Filters',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: TAdminColors.getOnSurfaceColor(darkMode),
            ),
          ),
          const SizedBox(height: 16),

          // Period Selection
          Wrap(
            spacing: isTablet ? 24 : 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              // Report Period
              Obx(() => AdminPeriodSelector(
                selectedPeriod: controller.selectedPeriod.value,
                onPeriodChanged: (period) => controller.setPeriod(period),
                darkMode: darkMode,
              )),

              // Year Selector
              Obx(() => AdminDropdown<int>(
                label: 'Year',
                value: controller.selectedYear.value,
                items: controller.availableYears,
                onChanged: (year) => controller.setYear(year!),
                getLabel: (year) => year.toString(),
                darkMode: darkMode,
                width: isTablet ? 150 : 120,
              )),

              // Month Selector (conditional)
              Obx(() {
                if (controller.selectedPeriod.value == ReportPeriod.monthly) {
                  return AdminDropdown<int>(
                    label: 'Month',
                    value: controller.selectedMonth.value,
                    items: controller.availableMonths,
                    onChanged: (month) => controller.setMonth(month!),
                    getLabel: (month) => controller.getMonthName(month),
                    darkMode: darkMode,
                    width: isTablet ? 150 : 120,
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),

          const SizedBox(height: 16),

          // Apply Button
          Row(
            children: [
              Obx(() => SizedBox(
                width: isTablet ? 200 : 150,
                child: ElevatedButton(
                  onPressed: controller.hasValidSelection
                      ? () => controller.loadTransactionData()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TAdminColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: TAdminColors.getOnSurfaceVariantColor(darkMode).withOpacity(0.3),
                  ),
                  child: Text(controller.isLoading.value ? 'Loading...' : 'Apply Filters'),
                ),
              )),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => controller.resetFilters(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  side: BorderSide(color: TAdminColors.getBorderColor(darkMode)),
                ),
                child: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartControls(TransactionReportController controller, bool darkMode, bool isTablet) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Subscription Purchase Analytics',
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.w600,
              color: TAdminColors.getOnSurfaceColor(darkMode),
            ),
          ),
        ),

        // Chart Type Toggle
        Obx(() => AdminChartTypeToggle(
          selectedType: controller.chartType.value,
          onTypeChanged: (type) => controller.setChartType(type),
          darkMode: darkMode,
        )),
      ],
    );
  }

  Widget _buildChartsContainer(TransactionReportController controller, bool darkMode, bool isTablet) {
    return Container(
      height: isTablet ? 500 : 400,
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceColor(darkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TAdminColors.getBorderColor(darkMode)),
      ),
      child: Column(
        children: [
          // Chart Title & Stats
          Row(
            children: [
              Expanded(
                child: Obx(() => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.getChartTitle(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: TAdminColors.getOnSurfaceColor(darkMode),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        AdminStatCard(
                          label: 'Total Transactions',
                          value: controller.totalTransactions.toString(),
                          color: TAdminColors.info,
                          darkMode: darkMode,
                        ),
                        const SizedBox(width: 16),
                        AdminStatCard(
                          label: 'Total Revenue',
                          value: 'RM ${controller.totalRevenue.toStringAsFixed(2)}',
                          color: TAdminColors.success,
                          darkMode: darkMode,
                        ),
                      ],
                    ),
                  ],
                )),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Chart
          Expanded(
            child: Obx(() => controller.chartType.value == ChartType.line
                ? AdminLineChart(
              spots: controller.getChartData(),
              xLabels: controller.getXAxisLabels(),
              minY: 0,
              maxY: controller.getMaxY(),
              yAxisUnit: controller.getYAxisUnit(),
              yAxisLabel: controller.getYAxisLabel(),
              title: controller.getChartTitle(),
              timeRange: controller.getTimeRangeText(),
              chartKey: controller.chartKey,
              periodFilter: controller.selectedPeriod.value.name,
              trendFilter: controller.selectedYear.value.toString(),
            )
                : AdminBarChart(
              barGroups: controller.getBarChartData(),
              xLabels: controller.getXAxisLabels(),
              minY: 0,
              maxY: controller.getMaxY(),
              yAxisUnit: controller.getYAxisUnit(),
              yAxisLabel: controller.getYAxisLabel(),
              title: controller.getChartTitle(),
              timeRange: controller.getTimeRangeText(),
              chartKey: controller.chartKey,
              periodFilter: controller.selectedPeriod.value.name,
              trendFilter: controller.selectedYear.value.toString(),
            )
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(TransactionReportController controller, bool darkMode, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceColor(darkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TAdminColors.getBorderColor(darkMode)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Transaction Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: TAdminColors.getOnSurfaceColor(darkMode),
                ),
              ),
              const Spacer(),
              Obx(() => Text(
                'Total: ${controller.transactions.length} transactions',
                style: TextStyle(
                  fontSize: 14,
                  color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                ),
              )),
            ],
          ),
          const SizedBox(height: 16),

          // Table
          Obx(() => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateColor.resolveWith(
                    (states) => TAdminColors.getTableHeaderColor(darkMode),
              ),
              dataRowColor: WidgetStateColor.resolveWith(
                    (states) => states.contains(WidgetState.hovered)
                    ? TAdminColors.getTableRowHoverColor(darkMode)
                    : TAdminColors.getTableRowColor(darkMode),
              ),
              columns: [
                DataColumn(
                  label: Text(
                    controller.selectedPeriod.value == ReportPeriod.monthly ? 'Week' : 'Month',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: TAdminColors.getOnSurfaceColor(darkMode),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Transactions',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: TAdminColors.getOnSurfaceColor(darkMode),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Revenue (RM)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: TAdminColors.getOnSurfaceColor(darkMode),
                    ),
                  ),
                ),
              ],
              rows: controller.getTableData().map((data) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        data['period'].toString(),
                        style: TextStyle(
                          color: TAdminColors.getOnSurfaceColor(darkMode),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        data['count'].toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: TAdminColors.primary,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        'RM ${data['revenue'].toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: TAdminColors.success,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool darkMode) {
    return Container(
      height: 600,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceColor(darkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TAdminColors.getBorderColor(darkMode)),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: TAdminColors.primary),
            SizedBox(height: 16),
            Text('Loading transaction data...'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool darkMode) {
    return Container(
      height: 600,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceColor(darkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TAdminColors.getBorderColor(darkMode)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: TAdminColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.chart_fail_bold,
                size: 64,
                color: TAdminColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Transaction Data Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: TAdminColors.getOnSurfaceColor(darkMode),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No successful transactions were found for the selected period.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: TAdminColors.getOnSurfaceVariantColor(darkMode),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or selecting a different time period.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: TAdminColors.getOnSurfaceVariantColor(darkMode),
              ),
            ),
          ],
        ),
      ),
    );
  }
}