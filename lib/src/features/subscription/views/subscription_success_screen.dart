import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../navigation_menu.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../controllers/payment_controller.dart';
import '../controllers/subscription_controller.dart';
import '../models/user_subscription_model.dart';
import 'subscription_history_screen.dart';

class SubscriptionSuccessScreen extends StatelessWidget {
  const SubscriptionSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);
    final paymentController = Get.find<PaymentController>();
    final subscriptionController = Get.find<SubscriptionController>();

    // Get subscription from arguments
    final UserSubscriptionModel subscription = Get.arguments as UserSubscriptionModel;

    return Scaffold(
      backgroundColor: darkMode ? TColors.black : TColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Success Icon Animation Container
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: TColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: TColors.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: TColors.success.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Success Title
              Text(
                'Payment Successful!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: darkMode ? TColors.white : TColors.black,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Success Subtitle
              Text(
                'Your ${subscription.subscriptionPlan.planName} subscription has been activated',
                style: TextStyle(
                  fontSize: 16,
                  color: darkMode ? Colors.grey[400] : Colors.grey[600],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Payment Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: darkMode ? Colors.grey[900] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: darkMode ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: TColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Iconsax.card_bold,
                            color: TColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Payment Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: darkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Transaction ID
                    _DetailRow(
                      label: 'Transaction ID',
                      value: subscription.successfulPayment!.transactionId.isNotEmpty
                          ? '${subscription.successfulPayment!.transactionId.substring(0, 16)}...'
                          : 'N/A',
                      darkMode: darkMode,
                    ),

                    const SizedBox(height: 16),

                    // Subscription ID
                    _DetailRow(
                      label: 'Subscription ID',
                      value: '#${subscription.subscriptionId.substring(0, 8).toUpperCase()}',
                      darkMode: darkMode,
                    ),

                    const SizedBox(height: 16),

                    // Amount
                    _DetailRow(
                      label: 'Amount Paid',
                      value: 'RM${subscription.successfulPayment!.amount.toStringAsFixed(2)}',
                      darkMode: darkMode,
                      isAmount: true,
                    ),

                    const SizedBox(height: 16),

                    // Payment Method
                    _DetailRow(
                      label: 'Payment Method',
                      value: _getPaymentMethodName(subscription.successfulPayment!.paymentMethod),
                      darkMode: darkMode,
                    ),

                    const SizedBox(height: 16),

                    // Payment Date
                    _DetailRow(
                      label: 'Payment Date',
                      value: _formatDate(subscription.successfulPayment!.transactionDateTime),
                      darkMode: darkMode,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Subscription Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: TColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: TColors.primary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Plan Icon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [TColors.primary, TColors.primary.withOpacity(0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Iconsax.crown_1_bold,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          subscription.subscriptionPlan.planName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Subscription Period
                    _SubscriptionDetailRow(
                      icon: Iconsax.calendar_bold,
                      label: 'Start Date',
                      value: THelperFunctions.getFormattedDate(
                        subscription.startDateTime,
                        format: 'dd MMM yyyy',
                      ),
                      darkMode: darkMode,
                    ),

                    const SizedBox(height: 12),

                    _SubscriptionDetailRow(
                      icon: Iconsax.calendar_tick_bold,
                      label: 'End Date',
                      value: THelperFunctions.getFormattedDate(
                        subscription.endDateTime,
                        format: 'dd MMM yyyy',
                      ),
                      darkMode: darkMode,
                    ),

                    const SizedBox(height: 12),

                    _SubscriptionDetailRow(
                      icon: Iconsax.clock_bold,
                      label: 'Duration',
                      value: '${subscription.subscriptionPlan.durationDays} days',
                      darkMode: darkMode,
                    ),

                    const SizedBox(height: 12),

                    _SubscriptionDetailRow(
                      icon: subscription.autoRenew ? Iconsax.refresh_bold : Iconsax.close_circle_bold,
                      label: 'Auto Renew',
                      value: subscription.autoRenew ? 'Enabled' : 'Disabled',
                      darkMode: darkMode,
                      valueColor: subscription.autoRenew ? TColors.success : TColors.error,
                    ),

                    const SizedBox(height: 20),

                    // Features Section
                    if (subscription.subscriptionPlan.features.isNotEmpty) ...[
                      Divider(
                        color: darkMode ? Colors.grey[700] : Colors.grey[300],
                        height: 1,
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Plan Features',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: darkMode ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),

                      const SizedBox(height: 12),

                      ...subscription.subscriptionPlan.features.map((feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.tick_circle_bold,
                              size: 18,
                              color: TColors.success,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                feature,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: darkMode ? Colors.grey[300] : Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Action Buttons
              Column(
                children: [
                  // Download Receipt Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        paymentController.downloadReceipt(subscription);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Iconsax.document_download_bold, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Download Receipt',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Back to Home Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        // Refresh subscription status
                        subscriptionController.refreshSubscriptionStatus();

                        // Navigate to home and clear navigation stack
                        Get.offAll(() => NavigationMenu());
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TColors.primary,
                        side: const BorderSide(color: TColors.primary),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Iconsax.home_bold, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Back to Home',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // View Subscription Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: TextButton(
                      onPressed: () {
                        // Navigate to subscription details page
                        Get.offAll(() => SubscriptionHistoryScreen());
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: darkMode ? Colors.grey[400] : Colors.grey[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'View Subscription Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _getPaymentMethodName(String method) {
    switch (method.toLowerCase()) {
      case 'stripe':
        return 'Stripe';
      case 'paypal':
        return 'PayPal';
      case 'razorpay':
        return 'RazorPay';
      case 'credit_card':
        return 'Credit Card';
      case 'debit_card':
        return 'Debit Card';
      default:
        return 'Card Payment';
    }
  }

  String _formatDate(DateTime dateTime) {
    if (dateTime.year == 0) {
      return DateTime.now().toString().split('.')[0];
    }
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

// Detail Row Widget for Payment Details
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool darkMode;
  final bool isAmount;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.darkMode,
    this.isAmount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: darkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isAmount ? FontWeight.bold : FontWeight.w500,
            color: isAmount
                ? TColors.primary
                : (darkMode ? Colors.white : Colors.black),
          ),
        ),
      ],
    );
  }
}

// Subscription Detail Row Widget with Icon
class _SubscriptionDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool darkMode;
  final Color? valueColor;

  const _SubscriptionDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.darkMode,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: TColors.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: darkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? (darkMode ? Colors.white : Colors.black),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}