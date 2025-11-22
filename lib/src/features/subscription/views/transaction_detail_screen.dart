import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../common/widgets/appbar/appbar.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/formatters/formatter.dart';
import '../../../utils/helpers/export_helper.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../../../utils/extensions/subscription_extension.dart';
import '../models/payment_transaction_model.dart';
import '../models/user_subscription_model.dart';

class TransactionDetailScreen extends StatelessWidget {
  final UserSubscriptionModel subscription;
  final String transactionId; // 用来定位具体的 transaction

  const TransactionDetailScreen({
    super.key,
    required this.subscription,
    required this.transactionId,
  });

  // 从 subscription 的 paymentTransactions 列表中找到对应的 transaction
  PaymentTransactionModel get transaction {
    return subscription.paymentTransactions.firstWhere(
          (t) => t.transactionId == transactionId,
      orElse: () => subscription.paymentTransactions.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: darkMode ? TColors.dark : TColors.light,
      appBar: TAppBar(
        title: Text(
          'Transaction Details',
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
            _buildStatusCard(darkMode),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Download Receipt Button (Only for successful transactions)
            if (transaction.status == PaymentStatus.succeeded)
              _buildDownloadReceiptButton(darkMode),

            if (transaction.status == PaymentStatus.succeeded)
              const SizedBox(height: TSizes.spaceBtwSections),

            // Transaction Information
            Text(
              'Transaction Information',
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
                    icon: Iconsax.document_text_bold,
                    iconColor: TColors.primary,
                    label: 'Transaction ID',
                    value: transaction.transactionId,
                    copyable: true,
                    onCopy: () => THelperFunctions.copyToClipboard(transaction.transactionId),
                    isFirst: true,
                  ),
                  _buildModernDetailRow(
                    darkMode: darkMode,
                    icon: Iconsax.receipt_text_bold,
                    iconColor: TColors.info,
                    label: 'Subscription ID',
                    value: subscription.subscriptionId,
                    copyable: true,
                    onCopy: () => THelperFunctions.copyToClipboard(subscription.subscriptionId),
                  ),
                  _buildModernDetailRow(
                    darkMode: darkMode,
                    icon: Iconsax.box_bold,
                    iconColor: TColors.secondary,
                    label: 'Plan Name',
                    value: subscription.subscriptionPlan.planName,
                  ),
                  _buildModernDetailRow(
                    darkMode: darkMode,
                    icon: Iconsax.money_bold,
                    iconColor: TColors.success,
                    label: 'Amount',
                    value: '${transaction.currency} ${transaction.amount.toStringAsFixed(2)}',
                  ),
                  _buildModernDetailRow(
                    darkMode: darkMode,
                    icon: transaction.paymentMethod.paymentMethodIcon,
                    iconColor: TColors.accent,
                    label: 'Payment Method',
                    value: transaction.paymentMethod,
                  ),
                  _buildModernDetailRow(
                    darkMode: darkMode,
                    icon: Iconsax.clock_bold,
                    iconColor: TColors.warning,
                    label: 'Date & Time',
                    value: TFormatter.formatFullDate(transaction.transactionDateTime),
                  ),
                  _buildModernDetailRow(
                    darkMode: darkMode,
                    icon: transaction.status.icon,
                    iconColor: transaction.status.color,
                    label: 'Status',
                    value: transaction.status.displayName.toUpperCase(),
                    valueColor: transaction.status.color,
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Help Section
            _buildHelpSection(darkMode),

            const SizedBox(height: TSizes.spaceBtwSections),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool darkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TSizes.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: transaction.status.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: transaction.status.color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(TSizes.md),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              transaction.status.icon,
              color: TColors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: TSizes.md),
          Text(
            transaction.status.displayName.toUpperCase(),
            style: const TextStyle(
              color: TColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: TSizes.sm),
          Text(
            '${transaction.currency} ${transaction.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: TColors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: TSizes.xs),
          Text(
            transaction.status.message,
            style: TextStyle(
              color: TColors.white.withOpacity(0.9),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadReceiptButton(bool darkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            TColors.success,
            TColors.successLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: TColors.success.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(TSizes.sm),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(TSizes.sm),
            ),
            child: Icon(
              Iconsax.document_download_bold,
              color: TColors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: TSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Receipt',
                  style: TextStyle(
                    color: TColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Download your transaction receipt',
                  style: TextStyle(
                    color: TColors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => ExportHelper.exportReceipt(
              subscription: subscription,
            ),
            icon: Icon(
              Iconsax.arrow_down_bold,
              size: 16,
              color: TColors.success,
            ),
            label: const Text(
              'Download',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: TColors.white,
              foregroundColor: TColors.success,
              padding: const EdgeInsets.symmetric(
                horizontal: TSizes.md,
                vertical: TSizes.sm + 2,
              ),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TSizes.buttonRadius),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(bool darkMode) {
    return Container(
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
                  'Need Help?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: TColors.info,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'If you have any questions about this transaction, please contact our support team.',
                  style: TextStyle(
                    color: darkMode ? TColors.grey : TColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: TSizes.sm),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to support
                  },
                  icon: Icon(Iconsax.message_text_bold, size: 16),
                  label: const Text('Contact Support'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TColors.info,
                    side: BorderSide(color: TColors.info),
                    padding: const EdgeInsets.symmetric(
                      horizontal: TSizes.md,
                      vertical: TSizes.sm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TSizes.buttonRadius),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
          top: isFirst
              ? BorderSide.none
              : BorderSide(
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