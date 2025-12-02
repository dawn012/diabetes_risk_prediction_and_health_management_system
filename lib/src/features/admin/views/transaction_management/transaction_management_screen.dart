import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../common/widgets/pagination/pagination_widget.dart';
import '../../../../common/widgets/table/reusable_data_table.dart';
import '../../../../utils/constants/admin_colors.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/formatters/formatter.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../subscription/models/payment_transaction_model.dart';
import '../../controllers/transaction_management_controller.dart';
import 'transaction_detail_dialog.dart';
import 'widgets/transaction_management_header.dart';
import 'widgets/transaction_statistics_cards.dart';

class TransactionManagementScreen extends StatelessWidget {
  const TransactionManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TransactionManagementController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final headerHeight = 200.0;
            final statisticsHeight = 140.0;
            final paginationHeight = 80.0;
            final padding = 48.0;
            final availableTableHeight = constraints.maxHeight -
                headerHeight - statisticsHeight - paginationHeight - padding;

            return SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TransactionManagementHeader(controller: controller),
                    const SizedBox(height: 24),

                    TransactionStatisticsCards(controller: controller),
                    const SizedBox(height: 24),

                    Container(
                      height: availableTableHeight.clamp(400.0, double.infinity),
                      decoration: BoxDecoration(
                        color: TAdminColors.getSurfaceColor(darkMode),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: darkMode ? Colors.black26 : Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Obx(() {
                              return ReusableDataTable<PaymentTransactionModel>(
                                data: controller.displayedTransactions,
                                columns: _getTransactionTableColumns(controller, darkMode),
                                isLoading: controller.isLoading.value,
                                searchQuery: controller.searchController.text,
                                sortColumnIndex: controller.sortColumnIndex.value,
                                sortAscending: controller.sortAscending.value,
                                onSort: (columnIndex, ascending) =>
                                    controller.sortTransactions(columnIndex, ascending),
                                showCheckboxColumn: false,
                                selectedItems: controller.emptySelection,
                              );
                            }),
                          ),

                          Obx(() => PaginationWidget(
                            currentPage: controller.currentPage.value,
                            totalPages: controller.totalPages.value,
                            onPageChanged: controller.changePage,
                            totalItems: controller.totalCount.value,
                            itemsPerPage: controller.itemsPerPage.value,
                            startIndex: ((controller.currentPage.value - 1) *
                                controller.itemsPerPage.value) + 1,
                            endIndex: (controller.currentPage.value *
                                controller.itemsPerPage.value).clamp(0, controller.totalCount.value),
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<DataTableColumn<PaymentTransactionModel>> _getTransactionTableColumns(
      TransactionManagementController controller, bool darkMode) {
    return [
      DataTableColumn<PaymentTransactionModel>(
        label: 'Transaction ID',
        field: 'transactionId',
        minWidth: 180,
        flex: 3,
        sortable: true,
        builder: (transaction) {
          final query = controller.searchController.text;
          return RichText(
            text: TextSpan(
              children: controller.getHighlightedText(transaction.transactionId, query),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: TAdminColors.getOnSurfaceVariantColor(darkMode),
              ),
            ),
          );
        },
      ),
      DataTableColumn<PaymentTransactionModel>(
        label: 'Amount',
        field: 'amount',
        minWidth: 120,
        flex: 2,
        sortable: true,
        builder: (transaction) => Text(
          TFormatter.formatCurrency(transaction.amount),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: TAdminColors.getOnSurfaceColor(darkMode),
          ),
        ),
      ),
      DataTableColumn<PaymentTransactionModel>(
        label: 'Date & Time',
        field: 'transactionDateTime',
        minWidth: 160,
        flex: 3,
        sortable: true,
        builder: (transaction) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${transaction.transactionDateTime.day}/${transaction.transactionDateTime.month}/${transaction.transactionDateTime.year}',
              style: TextStyle(
                fontSize: 12,
                color: TAdminColors.getOnSurfaceColor(darkMode),
              ),
            ),
            Text(
              TFormatter.formatTime(transaction.transactionDateTime),
              style: TextStyle(
                fontSize: 10,
                color: TAdminColors.getOnSurfaceVariantColor(darkMode),
              ),
            ),
          ],
        ),
      ),
      DataTableColumn<PaymentTransactionModel>(
        label: 'Status',
        field: 'status',
        minWidth: 120,
        flex: 2,
        sortable: true,
        builder: (transaction) => _buildStatusChip(transaction.status, darkMode),
      ),
      DataTableColumn<PaymentTransactionModel>(
        label: 'Payment Method',
        field: 'paymentMethod',
        minWidth: 140,
        flex: 2,
        sortable: true,
        builder: (transaction) {
          final query = controller.searchController.text;
          return RichText(
            text: TextSpan(
              children: controller.getHighlightedText(
                transaction.paymentMethod.toUpperCase(),
                query,
                textColor: TAdminColors.getOnSurfaceColor(darkMode),
              ),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: TAdminColors.getOnSurfaceColor(darkMode),
              ),
            ),
          );
        },
      ),
      DataTableColumn<PaymentTransactionModel>(
        label: 'Actions',
        field: 'actions',
        minWidth: 100,
        flex: 2,
        sortable: false,
        builder: (transaction) => _buildActionButtons(transaction, controller, darkMode),
      ),
    ];
  }

  Widget _buildStatusChip(PaymentStatus status, bool darkMode) {
    Color chipColor;
    IconData chipIcon;

    switch (status) {
      case PaymentStatus.succeeded:
        chipColor = TAdminColors.success;
        chipIcon = Iconsax.tick_circle_bold;
        break;
      case PaymentStatus.failed:
        chipColor = TAdminColors.error;
        chipIcon = Iconsax.close_circle_bold;
        break;
      case PaymentStatus.pending:
        chipColor = TAdminColors.warning;
        chipIcon = Iconsax.clock_bold;
        break;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: chipColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: chipColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              chipIcon,
              size: 12,
              color: chipColor,
            ),
            SizedBox(width: 6),
            Text(
              status.displayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: chipColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
      PaymentTransactionModel transaction,
      TransactionManagementController controller,
      bool darkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => _showTransactionDetailDialog(transaction, controller),
          icon: const Icon(Iconsax.eye_bold, size: 16),
          tooltip: 'View Details',
          style: IconButton.styleFrom(
            backgroundColor: TAdminColors.info.withOpacity(0.1),
            foregroundColor: TAdminColors.info,
            minimumSize: const Size(32, 32),
          ),
        ),
      ],
    );
  }

  void _showTransactionDetailDialog(
      PaymentTransactionModel transaction,
      TransactionManagementController controller) {
    Get.dialog(
      TransactionDetailDialog(
        transaction: transaction,
        controller: controller,
      ),
      barrierDismissible: true,
    );
  }
}