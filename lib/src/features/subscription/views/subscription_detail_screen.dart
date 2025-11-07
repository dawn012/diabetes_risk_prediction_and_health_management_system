import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../common/widgets/appbar/appbar.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/formatters/formatter.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../../../utils/extensions/subscription_extension.dart';
import '../controllers/subscription_controller.dart';
import '../controllers/payment_controller.dart';
import '../models/user_subscription_model.dart';
import 'payment_method_selection_screen.dart';

class SubscriptionDetailScreen extends StatelessWidget {
  final UserSubscriptionModel subscription;

  const SubscriptionDetailScreen({
    super.key,
    required this.subscription,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);
    final status = subscription.status;
    final subscriptionController = Get.put(SubscriptionController());
    final hasActiveSubscription = subscriptionController.activeSubscription.value != null;
    final hasPendingSubscription = subscriptionController.hasPendingSubscription.value;

    // Get latest payment for display
    final latestPayment = subscription.latestPayment;

    return Scaffold(
      backgroundColor: darkMode ? TColors.dark : TColors.light,
      appBar: TAppBar(
        title: Text(
          'Subscription Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: darkMode ? TColors.white : TColors.dark,
          ),
        ),
        backgroundColor: darkMode ? TColors.dark : TColors.white,
        showBackArrow: true,
      ),
      body: SingleChildScrollView(
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
                  color: status.color.withOpacity(0.3),
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
                  Container(
                    padding: const EdgeInsets.all(TSizes.md),
                    decoration: BoxDecoration(
                      color: status.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      subscription.status.icon,
                      color: status.color,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: TSizes.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: status.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.displayName.toUpperCase(),
                      style: TextStyle(
                        color: status.color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: TSizes.sm),
                  Text(
                    subscription.subscriptionPlan.planName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: darkMode ? TColors.white : TColors.dark,
                    ),
                  ),
                  const SizedBox(height: TSizes.xs),
                  Text(
                    subscription.status.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: darkMode ? TColors.darkGrey : TColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Subscription Information
            Text(
              'Subscription Information',
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
                    icon: Iconsax.box_bold,
                    iconColor: TColors.primary,
                    label: 'Plan Name',
                    value: subscription.subscriptionPlan.planName,
                  ),
                  _buildModernDetailRow(
                    darkMode: darkMode,
                    icon: Iconsax.calendar_bold,
                    iconColor: TColors.info,
                    label: 'Duration',
                    value: '${subscription.subscriptionPlan.durationDays} days',
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
                  _buildModernDetailRow(
                    darkMode: darkMode,
                    icon: subscription.autoRenew
                        ? Iconsax.refresh_bold
                        : Iconsax.close_circle_bold,
                    iconColor: subscription.autoRenew
                        ? TColors.success
                        : TColors.error,
                    label: 'Auto Renew',
                    value: subscription.autoRenew ? 'Yes' : 'No',
                    valueColor: subscription.autoRenew
                        ? TColors.success
                        : TColors.error,
                  ),
                  // Show cancel date for cancelled subscriptions
                  if (status == SubscriptionStatus.cancelled &&
                      subscription.cancelAt != null)
                    _buildModernDetailRow(
                      darkMode: darkMode,
                      icon: Iconsax.clock_bold,
                      iconColor: TColors.error,
                      label: 'Cancelled At',
                      value: TFormatter.formatFullDate(subscription.cancelAt!),
                      isLast: true,
                    ),

                  // Show payment information only if not pending
                  if (latestPayment != null && status != SubscriptionStatus.pending) ...[
                    _buildModernDetailRow(
                      darkMode: darkMode,
                      icon: Iconsax.money_bold,
                      iconColor: TColors.success,
                      label: 'Total Paid',
                      value: '${latestPayment.currency} ${subscription.totalAmountPaid.toStringAsFixed(2)}',
                    ),
                    if (subscription.paymentTransactions.length > 1)
                      _buildModernDetailRow(
                        darkMode: darkMode,
                        icon: Iconsax.receipt_text_bold,
                        iconColor: TColors.info,
                        label: 'Total Payments',
                        value: '${subscription.paymentTransactions.length} transactions',
                        isLast: true,
                      ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: TSizes.spaceBtwItems),

            // Plan Features
            if (subscription.subscriptionPlan.features.isNotEmpty) ...[
              Text(
                'Plan Features',
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

            // Action Buttons based on status
            if (status == SubscriptionStatus.pending) ...[
              // Pending status - show waiting message
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(TSizes.lg),
                decoration: BoxDecoration(
                  color: TColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                  border: Border.all(
                    color: TColors.warning.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Iconsax.clock_bold,
                      size: 48,
                      color: TColors.warning,
                    ),
                    const SizedBox(height: TSizes.md),
                    Text(
                      'Payment Processing',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkMode ? TColors.white : TColors.dark,
                      ),
                    ),
                    const SizedBox(height: TSizes.sm),
                    Text(
                      'Your payment is being processed. This usually takes a few moments. You will be notified once the payment is confirmed.',
                      style: TextStyle(
                        color: darkMode ? TColors.grey : TColors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else if (status == SubscriptionStatus.failed) ...[
              // Failed status - show retry button
              if (hasActiveSubscription || hasPendingSubscription)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(TSizes.md),
                  decoration: BoxDecoration(
                    color: TColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                    border: Border.all(
                      color: TColors.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.info_circle_bold,
                        color: TColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: TSizes.sm),
                      Expanded(
                        child: Text(
                          hasActiveSubscription
                              ? 'You already have an active subscription. Cancel it first to retry this payment.'
                              : 'You have a pending subscription. Please wait for it to be processed first.',
                          style: TextStyle(
                            color: darkMode ? TColors.grey : TColors.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final paymentController = Get.put(PaymentController());
                      paymentController.resetPaymentStatus();
                      subscriptionController.selectedPlan.value = subscription.subscriptionPlan;
                      Get.to(() => PaymentMethodScreen());
                    },
                    icon: const Icon(Iconsax.refresh_bold, size: 20),
                    label: const Text('Retry Payment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColors.error,
                      foregroundColor: TColors.white,
                      padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(TSizes.buttonRadius),
                      ),
                    ),
                  ),
                ),
            ] else ...[
              // Other statuses - show info notice
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(TSizes.md),
                decoration: BoxDecoration(
                  color: TColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                  border: Border.all(
                    color: TColors.info.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: TColors.info.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Iconsax.info_circle_bold,
                        color: TColors.info,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: TSizes.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Details',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: TColors.info,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'For complete payment information and transaction history, please visit the Transaction History section.',
                            style: TextStyle(
                              color: darkMode ? TColors.grey : TColors.textSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
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
    Color? valueColor,
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
                      color: valueColor ??
                          (darkMode ? TColors.white : TColors.dark),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 2,
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