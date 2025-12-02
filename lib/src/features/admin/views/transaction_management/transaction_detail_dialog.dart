import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../utils/constants/admin_colors.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/formatters/formatter.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../subscription/models/payment_transaction_model.dart';
import '../../controllers/transaction_management_controller.dart';

class TransactionDetailDialog extends StatefulWidget {
  final PaymentTransactionModel transaction;
  final TransactionManagementController controller;

  const TransactionDetailDialog({
    super.key,
    required this.transaction,
    required this.controller,
  });

  @override
  State<TransactionDetailDialog> createState() => _TransactionDetailDialogState();
}

class _TransactionDetailDialogState extends State<TransactionDetailDialog> {
  String? planName;
  String? subscriptionId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactionDetails();
  }

  Future<void> _loadTransactionDetails() async {
    try {
      subscriptionId = await widget.controller.paymentRepo
          .getSubscriptionIdByTransactionId(widget.transaction.transactionId);

      if (subscriptionId != null) {
        final subscription = await widget.controller.subscriptionRepo
            .getSubscriptionById(subscriptionId!);
        if (subscription != null) {
          setState(() {
            planName = subscription.subscriptionPlan.planName;
            isLoading = false;
          });
          return;
        }
      }

      setState(() {
        planName = 'Unknown Plan';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        planName = 'Error loading plan';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);
    final isWeb = THelperFunctions.screenWidth() > 800;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: isWeb ? 700 : MediaQuery.of(context).size.width * 0.95,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: TAdminColors.getSurfaceColor(darkMode),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: darkMode ? Colors.black54 : Colors.grey.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(darkMode),

            Divider(color: TAdminColors.getBorderColor(darkMode), height: 1),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Transaction Info
                    _buildTransactionInfo(darkMode),

                    SizedBox(height: 24),

                    // Payment Details
                    _buildPaymentDetails(darkMode),

                    SizedBox(height: 24),

                    // Subscription Info
                    _buildSubscriptionInfo(darkMode),

                    SizedBox(height: 24),

                    // Timeline
                    _buildTimeline(darkMode),
                  ],
                ),
              ),
            ),

            // Divider(color: TAdminColors.getBorderColor(darkMode), height: 1),

            // Footer
            // _buildFooter(darkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool darkMode) {
    return Container(
      padding: EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getStatusColor(widget.transaction.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Iconsax.receipt_text_bold,
              color: _getStatusColor(widget.transaction.status),
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaction Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: TAdminColors.getOnSurfaceColor(darkMode),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'ID: ${widget.transaction.transactionId}',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                  ),
                ),
              ],
            ),
          ),
          _buildStatusChip(darkMode),
          SizedBox(width: 16),
          IconButton(
            onPressed: () {
              if (Get.context != null) {
                Navigator.of(Get.context!, rootNavigator: true).pop(true);
              }
            },
            icon: Icon(
              Iconsax.close_circle_bold,
              color: TAdminColors.getOnSurfaceVariantColor(darkMode),
            ),
            style: IconButton.styleFrom(
              backgroundColor: TAdminColors.getSurfaceVariantColor(darkMode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool darkMode) {
    final status = widget.transaction.status;
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          SizedBox(width: 6),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionInfo(bool darkMode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceVariantColor(darkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TAdminColors.getBorderColor(darkMode)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.info_circle_bold,
                color: TAdminColors.primary,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Transaction Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: TAdminColors.getOnSurfaceColor(darkMode),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildInfoRow(
            'Transaction ID',
            widget.transaction.transactionId,
            Iconsax.hashtag_bold,
            darkMode,
            copyable: true,
          ),
          SizedBox(height: 12),
          _buildInfoRow(
            'Amount',
            TFormatter.formatCurrency(widget.transaction.amount),
            Iconsax.money_bold,
            darkMode,
          ),
          SizedBox(height: 12),
          _buildInfoRow(
            'Currency',
            widget.transaction.currency,
            Iconsax.dollar_circle_bold,
            darkMode,
          ),
          SizedBox(height: 12),
          _buildInfoRow(
            'Date & Time',
            TFormatter.formatDateTime(widget.transaction.transactionDateTime),
            Iconsax.calendar_bold,
            darkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails(bool darkMode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceVariantColor(darkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TAdminColors.getBorderColor(darkMode)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.card_bold,
                color: TAdminColors.primary,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Payment Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: TAdminColors.getOnSurfaceColor(darkMode),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildInfoRow(
            'Payment Method',
            widget.transaction.paymentMethod.toUpperCase(),
            Iconsax.wallet_bold,
            darkMode,
          ),
          SizedBox(height: 12),
          _buildInfoRow(
            'Status',
            widget.transaction.status.displayName,
            _getStatusIcon(widget.transaction.status),
            darkMode,
            valueColor: _getStatusColor(widget.transaction.status),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionInfo(bool darkMode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceVariantColor(darkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TAdminColors.getBorderColor(darkMode)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.box_bold,
                color: TAdminColors.primary,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Subscription Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: TAdminColors.getOnSurfaceColor(darkMode),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (isLoading)
            Center(
              child: CircularProgressIndicator(
                color: TAdminColors.primary,
                strokeWidth: 2,
              ),
            )
          else ...[
            _buildInfoRow(
              'Plan',
              planName ?? 'Unknown',
              Iconsax.category_bold,
              darkMode,
            ),
            if (subscriptionId != null) ...[
              SizedBox(height: 12),
              _buildInfoRow(
                'Subscription ID',
                subscriptionId!,
                Iconsax.hashtag_bold,
                darkMode,
                copyable: true,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTimeline(bool darkMode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceVariantColor(darkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TAdminColors.getBorderColor(darkMode)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.clock_bold,
                color: TAdminColors.primary,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Transaction Timeline',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: TAdminColors.getOnSurfaceColor(darkMode),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildTimelineItem(
            'Transaction Created',
            widget.transaction.transactionDateTime,
            Iconsax.add_circle_bold,
            TAdminColors.info,
            darkMode,
          ),
          if (widget.transaction.status == PaymentStatus.succeeded)
            _buildTimelineItem(
              'Payment Successful',
              widget.transaction.transactionDateTime,
              Iconsax.tick_circle_bold,
              TAdminColors.success,
              darkMode,
            )
          else if (widget.transaction.status == PaymentStatus.failed)
            _buildTimelineItem(
              'Payment Failed',
              widget.transaction.transactionDateTime,
              Iconsax.close_circle_bold,
              TAdminColors.error,
              darkMode,
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
      String title,
      DateTime dateTime,
      IconData icon,
      Color color,
      bool darkMode,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: TAdminColors.getOnSurfaceColor(darkMode),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  TFormatter.formatDateTime(dateTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      String label,
      String value,
      IconData icon,
      bool darkMode, {
        bool copyable = false,
        Color? valueColor,
      }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: TAdminColors.getOnSurfaceVariantColor(darkMode),
        ),
        SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: TAdminColors.getOnSurfaceVariantColor(darkMode),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? TAdminColors.getOnSurfaceColor(darkMode),
                    fontWeight: copyable ? FontWeight.w400 : FontWeight.w500,
                    fontFamily: copyable ? 'monospace' : null,
                  ),
                ),
              ),
              if (copyable)
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    Get.snackbar(
                      'Copied',
                      'Copied to clipboard',
                      snackPosition: SnackPosition.BOTTOM,
                      duration: Duration(seconds: 2),
                    );
                  },
                  icon: Icon(
                    Iconsax.copy_bold,
                    size: 16,
                    color: TAdminColors.primary,
                  ),
                  tooltip: 'Copy to clipboard',
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(bool darkMode) {
    return Container(
      padding: EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () {
              if (Get.context != null) {
                Navigator.of(Get.context!, rootNavigator: true).pop(true);
              }
            },
            child: Text('Close'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.succeeded:
        return TAdminColors.success;
      case PaymentStatus.failed:
        return TAdminColors.error;
      case PaymentStatus.pending:
        return TAdminColors.warning;
    }
  }

  IconData _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.succeeded:
        return Iconsax.tick_circle_bold;
      case PaymentStatus.failed:
        return Iconsax.close_circle_bold;
      case PaymentStatus.pending:
        return Iconsax.clock_bold;
    }
  }
}