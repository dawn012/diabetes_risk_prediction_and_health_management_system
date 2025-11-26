import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../common/widgets/appbar/appbar.dart';
import '../../../common/widgets/bottom_sheets/sort_bottom_sheet_widget.dart';
import '../../../common/widgets/filter_chip/filter_chips_widget.dart';
import '../../../common/widgets/search_bar/search_bar_widget.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/formatters/formatter.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../../../utils/extensions/subscription_extension.dart';
import '../controllers/subscription_controller.dart';
import '../controllers/subscription_history_controller.dart';
import '../controllers/payment_controller.dart';
import '../models/user_subscription_model.dart';
import 'subscription_detail_screen.dart';
import 'subscription_plan_selection_screen.dart';
import 'payment_method_selection_screen.dart';

class SubscriptionHistoryScreen extends StatelessWidget {
  const SubscriptionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subscriptionHistoryController = Get.put(SubscriptionHistoryController());
    final subscriptionController = Get.put(SubscriptionController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: darkMode ? TColors.dark : TColors.light,
        appBar: TAppBar(
          title: Text(
            'My Subscription',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: darkMode ? TColors.white : TColors.dark,
            ),
          ),
          backgroundColor: darkMode ? TColors.dark : TColors.white,
          showBackArrow: true,
          bottom: TabBar(
            indicatorColor: TColors.primary,
            labelColor: TColors.primary,
            unselectedLabelColor: darkMode ? TColors.grey : TColors.darkGrey,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'Active Plan'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildActivePlanTab(context, darkMode, subscriptionController),
            _buildHistoryTab(context, darkMode, subscriptionHistoryController, subscriptionController),
          ],
        ),
      ),
    );
  }

  // Active Plan Tab
  Widget _buildActivePlanTab(
      BuildContext context,
      bool darkMode,
      SubscriptionController subscriptionController,
      ) {
    return Obx(() {
      if (subscriptionController.isLoading.value) {
        return Center(
          child: CircularProgressIndicator(color: TColors.primary),
        );
      }

      if (subscriptionController.activeSubscription.value == null) {
        return _buildNoActiveSubscription(context, darkMode);
      }

      return _buildActivePlanContent(context, darkMode, subscriptionController);
    });
  }

  Widget _buildNoActiveSubscription(BuildContext context, bool darkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(TSizes.xl),
              decoration: BoxDecoration(
                color: TColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.crown_1_bold,
                size: 80,
                color: TColors.primary,
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwSections),
            Text(
              'No Active Subscription',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: darkMode ? TColors.white : TColors.dark,
              ),
            ),
            const SizedBox(height: TSizes.md),
            Text(
              'You don\'t have an active subscription.\nUpgrade to Premium to unlock exclusive features!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: darkMode ? TColors.darkGrey : TColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwSections),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: () => Get.to(() => const SubscriptionPlanScreen()),
                icon: const Icon(Iconsax.crown_bold, size: 20),
                label: const Text('Select Plan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.primary,
                  foregroundColor: TColors.white,
                  padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TSizes.buttonRadius),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePlanContent(
      BuildContext context,
      bool darkMode,
      SubscriptionController subscriptionController,
      ) {
    final subscription = subscriptionController.activeSubscription.value!;
    final daysRemaining = subscriptionController.getDaysRemaining();
    final totalDays = subscription.subscriptionPlan.durationDays;
    final progress = daysRemaining > 0 ? (totalDays - daysRemaining) / totalDays : 1.0;

    // Get latest successful payment for display
    final latestPayment = subscription.successfulPayment ?? subscription.latestPayment;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(TSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(TSizes.lg),
            decoration: BoxDecoration(
              color: darkMode ? TColors.black : TColors.white,
              borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
              border: Border.all(
                color: TColors.primary.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: darkMode
                      ? Colors.black.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(TSizes.md),
                      decoration: BoxDecoration(
                        color: TColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Iconsax.crown_1_bold,
                        color: TColors.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: TSizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subscription.subscriptionPlan.planName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: darkMode ? TColors.white : TColors.dark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: TColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ACTIVE',
                              style: TextStyle(
                                color: TColors.success,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TSizes.lg),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        (darkMode ? TColors.darkGrey : TColors.grey).withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: TSizes.lg),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Days Remaining',
                            style: TextStyle(
                              color: darkMode ? TColors.grey : TColors.darkGrey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                daysRemaining.toString(),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: TColors.primary,
                                ),
                              ),
                              Text(
                                ' / $totalDays days',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: darkMode ? TColors.grey : TColors.darkGrey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(TSizes.sm),
                      decoration: BoxDecoration(
                        color: TColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Iconsax.timer_1_bold,
                        color: TColors.primary,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TSizes.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: darkMode
                        ? TColors.darkGrey.withOpacity(0.3)
                        : TColors.grey.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(TColors.primary),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: TSizes.md),

          // Auto Renew Toggle
          Container(
            padding: const EdgeInsets.all(TSizes.md),
            decoration: BoxDecoration(
              color: darkMode ? TColors.black : TColors.white,
              borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
              boxShadow: [
                BoxShadow(
                  color: darkMode
                      ? Colors.black.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(TSizes.sm),
                  decoration: BoxDecoration(
                    color: TColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Iconsax.refresh_bold,
                    color: TColors.info,
                    size: 20,
                  ),
                ),
                const SizedBox(width: TSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-Renewal',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: darkMode ? TColors.white : TColors.dark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Obx(() => Text(
                        subscriptionController.autoRenew.value
                            ? 'Your plan will renew automatically'
                            : 'Enable to renew automatically',
                        style: TextStyle(
                          fontSize: 12,
                          color: darkMode ? TColors.grey : TColors.darkGrey,
                        ),
                      )),
                    ],
                  ),
                ),
                Obx(() => Switch(
                  value: subscriptionController.autoRenew.value,
                  onChanged: (value) => subscriptionController.toggleAutoRenew(),
                  activeColor: TColors.info,
                )),
              ],
            ),
          ),

          const SizedBox(height: TSizes.spaceBtwSections),

          Text(
            'Subscription Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: darkMode ? TColors.white : TColors.dark,
            ),
          ),
          const SizedBox(height: TSizes.md),

          Container(
            decoration: BoxDecoration(
              color: darkMode ? TColors.black : TColors.white,
              borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
              boxShadow: [
                BoxShadow(
                  color: darkMode
                      ? Colors.black.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildModernDetailRow(
                  darkMode: darkMode,
                  icon: Iconsax.receipt_text_bold,
                  iconColor: TColors.info,
                  label: 'Subscription ID',
                  value: subscription.subscriptionId,
                  copyable: true,
                  onCopy: () => THelperFunctions.copyToClipboard(subscription.subscriptionId),
                  isFirst: true,
                ),
                _buildModernDetailRow(
                  darkMode: darkMode,
                  icon: Iconsax.calendar_tick_bold,
                  iconColor: TColors.success,
                  label: 'Start Date',
                  value: TFormatter.formatFullDate(subscription.startDateTime),
                ),
                _buildModernDetailRow(
                  darkMode: darkMode,
                  icon: Iconsax.calendar_remove_bold,
                  iconColor: TColors.warning,
                  label: 'End Date',
                  value: TFormatter.formatFullDate(subscription.endDateTime),
                ),
                if (latestPayment != null) ...[
                  _buildModernDetailRow(
                    darkMode: darkMode,
                    icon: Iconsax.money_bold,
                    iconColor: TColors.primary,
                    label: 'Total Paid',
                    value: '${latestPayment.currency} ${subscription.totalAmountPaid.toStringAsFixed(2)}',
                  ),
                  if (subscription.paymentTransactions.length > 1)
                    _buildModernDetailRow(
                      darkMode: darkMode,
                      icon: Iconsax.receipt_text_bold,
                      iconColor: TColors.info,
                      label: 'Payments',
                      value: '${subscription.paymentTransactions.length} transactions',
                      isLast: true,
                    )
                  else
                    _buildModernDetailRow(
                      darkMode: darkMode,
                      icon: Iconsax.wallet_bold,
                      iconColor: TColors.info,
                      label: 'Transaction ID',
                      value: latestPayment.transactionId,
                      copyable: true,
                      onCopy: () => THelperFunctions.copyToClipboard(latestPayment.transactionId),
                      isLast: true,
                    ),
                ],
              ],
            ),
          ),

          const SizedBox(height: TSizes.spaceBtwItems),

          if (subscription.subscriptionPlan.features.isNotEmpty) ...[
            Text(
              'Premium Features',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: darkMode ? TColors.white : TColors.dark,
              ),
            ),
            const SizedBox(height: TSizes.md),
            Container(
              padding: const EdgeInsets.all(TSizes.md),
              decoration: BoxDecoration(
                color: darkMode ? TColors.black : TColors.white,
                borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                boxShadow: [
                  BoxShadow(
                    color: darkMode
                        ? Colors.black.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: subscription.subscriptionPlan.features
                    .asMap()
                    .entries
                    .map((entry) {
                  return Padding(
                    padding: EdgeInsets.only(
                      top: entry.key == 0 ? 0 : TSizes.sm,
                      bottom: entry.key == subscription.subscriptionPlan.features.length - 1
                          ? 0
                          : TSizes.sm,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: TColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Iconsax.tick_circle_bold,
                            color: TColors.success,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: TSizes.sm),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 14,
                              color: darkMode ? TColors.white : TColors.dark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: TSizes.spaceBtwSections),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => subscriptionController.showCancelSubscriptionDialog(context),
              icon: const Icon(Iconsax.close_circle_bold, size: 18),
              label: const Text('Cancel Subscription'),
              style: OutlinedButton.styleFrom(
                foregroundColor: TColors.error,
                side: BorderSide(color: TColors.error),
                padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TSizes.buttonRadius),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // History Tab - Modified to handle failed subscriptions
  Widget _buildHistoryTab(
      BuildContext context,
      bool darkMode,
      SubscriptionHistoryController controller,
      SubscriptionController subscriptionController,
      ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, TSizes.sm, TSizes.md, TSizes.sm),
          child: Row(
            children: [
              Expanded(
                child: Obx(() => SearchBarWidget(
                  controller: controller.searchController,
                  onChanged: controller.onSearchChanged,
                  onClear: controller.clearSearch,
                  hintText: 'Search subscriptions...',
                  hasText: controller.searchQuery.value.isNotEmpty,
                )),
              ),
              const SizedBox(width: TSizes.sm),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(TSizes.buttonRadius),
                  border: Border.all(
                    color: TColors.primary,
                    width: 1,
                  ),
                ),
                child: IconButton(
                  onPressed: () => SortBottomSheetWidget.show(
                    context,
                    sortOptions: controller.sortOptions,
                    selectedSortOption: controller.selectedSortOption,
                    onSortOptionChanged: controller.onSortOptionChanged,
                    getSortOptionLabel: controller.getSortOptionLabel,
                    darkMode: darkMode,
                  ),
                  icon: Icon(
                    Icons.sort_outlined,
                    color: TColors.primary,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(12),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),

        FilterChipsWidget(
          filters: controller.statusFilters,
          selectedFilter: controller.selectedStatus,
          onFilterSelected: controller.onStatusFilterChanged,
          getFilterLabel: controller.getStatusLabel,
          spaceBetweenChips: 10,
        ),

        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return Center(
                child: CircularProgressIndicator(color: TColors.primary),
              );
            }

            final historyList = controller.filteredSubscriptions;

            if (historyList.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(TSizes.defaultSpace),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.document_text_bold,
                        size: 80,
                        color: darkMode ? TColors.darkGrey : TColors.grey,
                      ),
                      const SizedBox(height: TSizes.md),
                      Text(
                        'No History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkMode ? TColors.white : TColors.dark,
                        ),
                      ),
                      const SizedBox(height: TSizes.sm),
                      Text(
                        'Your subscription history will appear here',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: darkMode ? TColors.darkGrey : TColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => controller.refreshData(),
              color: TColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.all(TSizes.md),
                itemCount: historyList.length,
                itemBuilder: (context, index) {
                  final subscription = historyList[index];
                  return _buildHistoryCard(
                    context,
                    subscription,
                    darkMode,
                    subscriptionController,
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(
      BuildContext context,
      UserSubscriptionModel subscription,
      bool darkMode,
      SubscriptionController subscriptionController,
      ) {
    final status = subscription.status;
    final hasActiveSubscription = subscriptionController.activeSubscription.value != null;
    final hasPendingSubscription = subscriptionController.hasPendingSubscription.value;
    final canRetryPayment = status == SubscriptionStatus.failed &&
        !hasActiveSubscription &&
        !hasPendingSubscription;

    final latestPayment = subscription.latestPayment;

    return Container(
      margin: const EdgeInsets.only(bottom: TSizes.sm),
      decoration: BoxDecoration(
        color: darkMode ? TColors.black : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: darkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
          onTap: () => Get.to(
                () => SubscriptionDetailScreen(subscription: subscription),
          ),
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
                        color: status.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        subscription.status.icon,
                        color: status.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: TSizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subscription.subscriptionPlan.planName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: darkMode ? TColors.white : TColors.dark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${subscription.subscriptionPlan.durationDays} days',
                            style: TextStyle(
                              color: darkMode
                                  ? TColors.darkGrey
                                  : TColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: status.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.displayName,
                        style: TextStyle(
                          color: status.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TSizes.sm),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        (darkMode ? TColors.darkGrey : TColors.grey).withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: TSizes.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Period',
                          style: TextStyle(
                            color: darkMode ? TColors.grey : TColors.darkGrey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          TFormatter.formatFullDate(subscription.startDateTime),
                          style: TextStyle(
                            color: darkMode ? TColors.white : TColors.dark,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Amount',
                          style: TextStyle(
                            color: darkMode ? TColors.grey : TColors.darkGrey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          latestPayment != null
                              ? '${latestPayment.currency} ${subscription.totalAmountPaid.toStringAsFixed(2)}'
                              : 'N/A',
                          style: TextStyle(
                            color: darkMode ? TColors.white : TColors.dark,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Retry Payment button for failed subscriptions
                if (status == SubscriptionStatus.failed) ...[
                  const SizedBox(height: TSizes.sm),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: canRetryPayment
                          ? () {
                        final paymentController = Get.put(PaymentController());
                        paymentController.resetPaymentStatus();
                        subscriptionController.selectedPlan.value = subscription.subscriptionPlan;
                        Get.to(() => PaymentMethodScreen());
                      }
                          : null,
                      icon: Icon(
                        canRetryPayment ? Iconsax.refresh_bold : Iconsax.lock_bold,
                        size: 18,
                      ),
                      label: Text(
                          hasActiveSubscription
                              ? 'Active Plan Exists'
                              : hasPendingSubscription
                              ? 'Pending Plan Exists'
                              : 'Retry Payment'
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canRetryPayment
                            ? TColors.error
                            : (darkMode ? TColors.darkGrey : TColors.grey),
                        foregroundColor: TColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(TSizes.buttonRadius),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernDetailRow({
    required bool darkMode,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool copyable = false,
    VoidCallback? onCopy,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        border: Border(
          top: isFirst ? BorderSide.none : BorderSide(
            color: darkMode
                ? TColors.darkGrey.withOpacity(0.1)
                : TColors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: iconColor,
            ),
          ),
          const SizedBox(width: TSizes.md),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: darkMode ? TColors.grey : TColors.darkGrey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: darkMode ? TColors.white : TColors.dark,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (copyable) ...[
                  const SizedBox(width: TSizes.xs),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onCopy,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Iconsax.copy_bold,
                          size: 16,
                          color: TColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}