import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../utils/constants/admin_colors.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../reward/models/reward_model.dart';
import '../../controllers/reward_management_controller.dart';

class RewardDetailDialog extends StatelessWidget {
  final RewardModel reward;
  final RewardManagementController controller;

  const RewardDetailDialog({
    super.key,
    required this.reward,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 600,
        constraints: BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: TAdminColors.getSurfaceColor(darkMode),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(darkMode),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reward preview section
                    _buildRewardPreviewSection(darkMode),

                    SizedBox(height: 24),

                    // Basic information
                    _buildBasicInfoSection(darkMode),

                    SizedBox(height: 24),

                    // Type and pricing information
                    _buildPricingSection(darkMode),
                  ],
                ),
              ),
            ),

            // Footer
            _buildFooter(darkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool darkMode) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceVariantColor(darkMode),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.gift_bold,
            size: 24,
            color: TAdminColors.primary,
          ),
          SizedBox(width: 16),
          Text(
            'Reward Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: TAdminColors.getOnSurfaceColor(darkMode),
            ),
          ),
          Spacer(),
          IconButton(
            onPressed: () => Get.back(),
            icon: Icon(
              Iconsax.close_circle_bold,
              color: TAdminColors.getOnSurfaceVariantColor(darkMode),
            ),
            style: IconButton.styleFrom(
              backgroundColor: TAdminColors.getSurfaceColor(darkMode),
              minimumSize: Size(40, 40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardPreviewSection(bool darkMode) {
    return Row(
      children: [
        // Reward image
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: TAdminColors.getBorderColor(darkMode),
              width: 3,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: reward.icon.isNotEmpty
                ? Image.network(
              reward.icon,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: TAdminColors.getSurfaceVariantColor(darkMode),
                  child: Icon(
                    Iconsax.gallery_slash_bold,
                    size: 48,
                    color: TAdminColors.error,
                  ),
                );
              },
            )
                : Container(
              color: TAdminColors.getSurfaceVariantColor(darkMode),
              child: Icon(
                Iconsax.gallery_bold,
                size: 48,
                color: TAdminColors.getOnSurfaceVariantColor(darkMode),
              ),
            ),
          ),
        ),

        SizedBox(width: 20),

        // Reward info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      reward.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: TAdminColors.getOnSurfaceColor(darkMode),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  _buildStatusBadge(darkMode),
                ],
              ),
              SizedBox(height: 8),
              _buildTypeBadge(darkMode),
              SizedBox(height: 12),
              Text(
                reward.description,
                style: TextStyle(
                  fontSize: 14,
                  color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool darkMode) {
    Color statusColor = reward.isActive ? TAdminColors.success : TAdminColors.error;
    String statusText = reward.isActive ? 'Active' : 'Disabled';
    IconData statusIcon = reward.isActive ? Iconsax.eye_bold : Iconsax.eye_slash_bold;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 14,
            color: statusColor,
          ),
          SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(bool darkMode) {
    Color typeColor;
    IconData typeIcon;
    String typeLabel;

    switch (reward.rewardType) {
      case RewardType.avatarFrame:
        typeColor = TAdminColors.primary;
        typeIcon = Iconsax.frame_bold;
        typeLabel = 'Avatar Frame';
        break;
      case RewardType.virtualItem:
        typeColor = TAdminColors.warning;
        typeIcon = Iconsax.medal_bold;
        typeLabel = 'Virtual Item';
        break;
      case RewardType.coupon:
        typeColor = TAdminColors.success;
        typeIcon = Iconsax.ticket_discount_bold;
        typeLabel = 'Coupon';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: typeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: typeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            typeIcon,
            size: 14,
            color: typeColor,
          ),
          SizedBox(width: 6),
          Text(
            typeLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: typeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: TAdminColors.getOnSurfaceColor(isDark),
          ),
        ),
        SizedBox(height: 16),

        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: TAdminColors.getSurfaceVariantColor(isDark),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: TAdminColors.getBorderColor(isDark),
            ),
          ),
          child: Column(
            children: [
              _buildInfoRow(
                'Reward ID',
                reward.rewardId,
                Iconsax.card_bold,
                isDark,
                copyable: true,
              ),
              _buildDivider(isDark),
              _buildInfoRow(
                'Title',
                reward.title,
                Icons.title,
                isDark,
              ),
              _buildDivider(isDark),
              _buildInfoRow(
                'Description',
                reward.description,
                Iconsax.document_text_bold,
                isDark,
              ),
              _buildDivider(isDark),
              _buildInfoRow(
                'Created Date',
                _formatFullDate(reward.createdAt),
                Iconsax.calendar_add_bold,
                isDark,
              ),
              _buildDivider(isDark),
              _buildInfoRow(
                'Last Updated',
                _formatFullDate(reward.updatedAt),
                Iconsax.refresh_bold,
                isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPricingSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pricing & Availability',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: TAdminColors.getOnSurfaceColor(isDark),
          ),
        ),
        SizedBox(height: 16),

        Row(
          children: [
            // Cost Points Card
            Expanded(
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: TAdminColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: TAdminColors.warning.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Iconsax.coin_bold,
                          size: 24,
                          color: TAdminColors.warning,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Cost Points',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: TAdminColors.getOnSurfaceVariantColor(isDark),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      '${reward.costPoints}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: TAdminColors.warning,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Points required to redeem',
                      style: TextStyle(
                        fontSize: 12,
                        color: TAdminColors.getOnSurfaceVariantColor(isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(width: 16),

            // Available Quantity Card
            Expanded(
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: reward.availableQuantity == null
                      ? TAdminColors.success.withOpacity(0.1)
                      : (reward.availableQuantity! > 0
                      ? TAdminColors.info.withOpacity(0.1)
                      : TAdminColors.error.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: reward.availableQuantity == null
                        ? TAdminColors.success.withOpacity(0.3)
                        : (reward.availableQuantity! > 0
                        ? TAdminColors.info.withOpacity(0.3)
                        : TAdminColors.error.withOpacity(0.3)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          reward.availableQuantity == null
                              ? Icons.all_inclusive
                              : Iconsax.box_bold,
                          size: 24,
                          color: reward.availableQuantity == null
                              ? TAdminColors.success
                              : (reward.availableQuantity! > 0
                              ? TAdminColors.info
                              : TAdminColors.error),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Available',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: TAdminColors.getOnSurfaceVariantColor(isDark),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      reward.availableQuantity == null
                          ? 'Unlimited'
                          : '${reward.availableQuantity}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: reward.availableQuantity == null
                            ? TAdminColors.success
                            : (reward.availableQuantity! > 0
                            ? TAdminColors.info
                            : TAdminColors.error),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      reward.availableQuantity == null
                          ? 'No quantity limit'
                          : (reward.availableQuantity! > 0
                          ? 'Units remaining in stock'
                          : 'Out of stock'),
                      style: TextStyle(
                        fontSize: 12,
                        color: TAdminColors.getOnSurfaceVariantColor(isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(
      String label,
      String value,
      IconData icon,
      bool isDark, {
        bool copyable = false,
      }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: TAdminColors.getOnSurfaceVariantColor(isDark),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: TAdminColors.getOnSurfaceColor(isDark),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: TAdminColors.getOnSurfaceVariantColor(isDark),
                    ),
                  ),
                ),
                if (copyable) ...[
                  SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: value));
                      Get.snackbar(
                        'Copied',
                        '$label copied to clipboard',
                        duration: Duration(seconds: 2),
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                    icon: Icon(
                      Iconsax.copy_bold,
                      size: 16,
                      color: TAdminColors.getOnSurfaceVariantColor(isDark),
                    ),
                    style: IconButton.styleFrom(
                      minimumSize: Size(32, 32),
                      padding: EdgeInsets.all(4),
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

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      color: TAdminColors.getBorderColor(isDark).withOpacity(0.5),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceVariantColor(isDark),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: reward.isActive
                  ? TAdminColors.success.withOpacity(0.1)
                  : TAdminColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: reward.isActive
                    ? TAdminColors.success.withOpacity(0.3)
                    : TAdminColors.error.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  reward.isActive ? Iconsax.eye_bold : Iconsax.eye_slash_bold,
                  size: 14,
                  color: reward.isActive ? TAdminColors.success : TAdminColors.error,
                ),
                SizedBox(width: 6),
                Text(
                  reward.isActive ? 'Active' : 'Disabled',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: reward.isActive ? TAdminColors.success : TAdminColors.error,
                  ),
                ),
              ],
            ),
          ),

          Spacer(),

          // Action buttons
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => Get.back(),
                icon: Icon(Iconsax.arrow_left_2_bold, size: 16),
                label: Text('Close'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Get.back();
                  controller.openEditRewardDialog(reward);
                },
                icon: Icon(Iconsax.edit_bold, size: 16),
                label: Text('Edit Reward'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TAdminColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}