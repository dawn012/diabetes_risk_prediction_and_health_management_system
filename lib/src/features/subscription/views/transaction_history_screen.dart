import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../common/loaders/loaders.dart';
import '../../../common/widgets/appbar/appbar.dart';
import '../../../common/widgets/filter_chip/filter_chips_widget.dart';
import '../../../common/widgets/search_bar/search_bar_widget.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/formatters/formatter.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../../../utils/extensions/subscription_extension.dart';
import '../controllers/transaction_history_controller.dart';
import '../models/payment_transaction_model.dart';
import 'transaction_detail_screen.dart';
import 'widgets/empty_state_widget.dart';
import 'widgets/sort_bottom_sheet_widget.dart';
import 'widgets/status_badge_widget.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TransactionHistoryController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: darkMode ? TColors.dark : TColors.light,
      appBar: TAppBar(
        title: Text(
          'Transaction History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: darkMode ? TColors.white : TColors.dark,
          ),
        ),
        backgroundColor: darkMode ? TColors.dark : TColors.white,
        showBackArrow: true,
        actions: [
          IconButton(
            onPressed: () => SortBottomSheetWidget.show(
              context,
              sortOptions: controller.sortOptions,
              selectedSortOption: controller.selectedSortOption,
              onSortOptionChanged: controller.onSortOptionChanged,
              getSortOptionLabel: controller.getSortOptionLabel,
              darkMode: darkMode,
            ),
            icon: Icon(Icons.sort_outlined, color: TColors.primary),
            tooltip: 'Sort',
          ),
        ],
      ),
      body: Column(
        children: [
          Obx(() => SearchBarWidget(
            controller: controller.searchController,
            onChanged: controller.onSearchChanged,
            onClear: controller.clearSearch,
            hintText: 'Search transactions...',
            hasText: controller.searchQuery.value.isNotEmpty,
          )),
          FilterChipsWidget(
            filters: controller.statusFilters,
            selectedFilter: controller.selectedStatus,
            onFilterSelected: controller.onStatusFilterChanged,
            getFilterLabel: controller.getStatusLabel,
            spaceBetweenChips: 20,
          ),
          const SizedBox(height: TSizes.sm),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(child: CircularProgressIndicator(color: TColors.primary));
              }

              if (controller.filteredTransactions.isEmpty) {
                return EmptyStateWidget(
                  icon: Iconsax.receipt_text_bold,
                  title: 'No transactions found',
                  subtitle: 'Your transaction history will appear here',
                  darkMode: darkMode,
                );
              }

              return RefreshIndicator(
                onRefresh: () async => controller.refreshData(),
                color: TColors.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TSizes.md,
                    vertical: TSizes.sm,
                  ),
                  itemCount: controller.filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = controller.filteredTransactions[index];
                    return _buildTransactionCard(
                      context,
                      transaction,
                      darkMode,
                      controller,
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
      BuildContext context,
      PaymentTransactionModel transaction,
      bool darkMode,
      TransactionHistoryController controller,
      ) {
    final planName = controller.getPlanName(transaction.transactionId);
    final subscription = controller.getSubscription(transaction.transactionId);

    return Container(
      margin: const EdgeInsets.only(bottom: TSizes.sm),
      decoration: BoxDecoration(
        color: darkMode ? TColors.black : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: darkMode ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
          onTap: () {
            if (subscription != null) {
              Get.to(() => TransactionDetailScreen(
                subscription: subscription, // 传递完整的 subscription
                transactionId: transaction.transactionId, // 传递 transactionId 用于定位
              ));
            } else {
              TLoaders.errorSnackBar(
                title: 'Error',
                message: 'Unable to load transaction details',
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(TSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: transaction.status.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        transaction.status.icon,
                        color: transaction.status.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: TSizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            planName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: darkMode ? TColors.white : TColors.dark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            TFormatter.formatRelativeDate(transaction.transactionDateTime),
                            style: TextStyle(
                              color: darkMode ? TColors.darkGrey : TColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${transaction.currency} ${transaction.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: transaction.status.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        StatusBadgeWidget(
                          statusText: transaction.status.displayName,
                          statusColor: transaction.status.color,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: TSizes.sm),
                Container(
                  height: 1,
                  color: darkMode ? TColors.darkGrey.withOpacity(0.3) : TColors.grey.withOpacity(0.3),
                ),
                const SizedBox(height: TSizes.sm),
                Row(
                  children: [
                    Icon(
                      transaction.paymentMethod.paymentMethodIcon,
                      color: darkMode ? TColors.grey : TColors.darkGrey,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      transaction.paymentMethod,
                      style: TextStyle(
                        color: darkMode ? TColors.grey : TColors.darkGrey,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'ID: ${_truncateId(transaction.transactionId)}',
                      style: TextStyle(
                        color: darkMode ? TColors.grey : TColors.darkGrey,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _truncateId(String id) {
    if (id.length <= 8) return id;
    return '${id.substring(0, 4)}...${id.substring(id.length - 4)}';
  }
}