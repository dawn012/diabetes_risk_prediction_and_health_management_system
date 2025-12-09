import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../utils/constants/admin_colors.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../authentication/models/user_model.dart';

class UserDetailDialog extends StatelessWidget {
  final UserModel user;
  final bool isPremium;

  const UserDetailDialog({
    super.key,
    required this.user,
    this.isPremium = false,
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
                    // Profile section
                    _buildProfileSection(darkMode),

                    SizedBox(height: 24),

                    // Account information
                    _buildAccountInfoSection(darkMode),

                    SizedBox(height: 24),

                    // Statistics section
                    _buildStatisticsSection(darkMode),
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
            Iconsax.user_bold,
            size: 24,
            color: TAdminColors.primary,
          ),
          SizedBox(width: 16),
          Text(
            'User Details',
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

  Widget _buildProfileSection(bool darkMode) {
    return Row(
      children: [
        // Profile image
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: TAdminColors.getBorderColor(darkMode),
              width: 3,
            ),
          ),
          child: _buildProfileAvatar(darkMode),
        ),

        SizedBox(width: 20),

        // User info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    user.username,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: TAdminColors.getOnSurfaceColor(darkMode),
                    ),
                  ),
                  SizedBox(width: 12),
                  _buildStatusBadge(darkMode),

                  // Premium Chip
                  if (isPremium) ...[
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: TAdminColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: TAdminColors.warning.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.crown_bold,
                            size: 14,
                            color: TAdminColors.warning,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Premium',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: TAdminColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 4),
              Text(
                user.email,
                style: TextStyle(
                  fontSize: 16,
                  color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Member since ${_formatDate(user.joinDate)}',
                style: TextStyle(
                  fontSize: 14,
                  color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileAvatar(bool darkMode) {
    // 如果有头像URL且不为空，显示网络图片
    if (user.profileImg.isNotEmpty) {
      return CircleAvatar(
        radius: 38,
        backgroundImage: NetworkImage(user.profileImg),
        backgroundColor: TAdminColors.primary.withOpacity(0.1),
      );
    }

    // 否则显示默认头像图标
    return CircleAvatar(
      radius: 38,
      backgroundColor: TAdminColors.primary.withOpacity(0.2),
      child: Icon(
        Iconsax.user_bold,
        size: 32,
        color: TAdminColors.primary,
      ),
    );
  }

  Widget _buildStatusBadge(bool darkMode) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (!user.accountAvailable) {
      statusColor = TAdminColors.banned;
      statusText = 'Banned';
      statusIcon = Iconsax.user_remove_bold;
    } else if (user.isVerify) {
      statusColor = TAdminColors.success;
      statusText = 'Verified';
      statusIcon = Iconsax.shield_tick_bold;
    } else {
      statusColor = TAdminColors.error; // 红色显示 Not verified
      statusText = 'Not verified';
      statusIcon = Iconsax.shield_cross_bold;
    }

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

  Widget _buildAccountInfoSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: TAdminColors.getOnSurfaceColor(isDark),
          ),
        ),
        SizedBox(height: 16),

        // Info grid
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
                'User ID',
                user.userId,
                Iconsax.card_bold,
                isDark,
                copyable: true,
              ),
              _buildInfoRow(
                'Email',
                user.email,
                Icons.email,
                isDark,
                copyable: true,
              ),
              _buildDivider(isDark),
              _buildInfoRow(
                'Role',
                user.userType.isEmpty ? 'Regular User' : user.userType,
                Iconsax.user_tag_bold,
                isDark,
              ),
              _buildDivider(isDark),
              _buildInfoRow(
                'Phone Number',
                user.formattedPhoneNo.isNotEmpty ? user.formattedPhoneNo : 'Not provided',
                Iconsax.call_bold,
                isDark,
                copyable: user.formattedPhoneNo.isNotEmpty,
              ),
              _buildDivider(isDark),
              _buildInfoRow(
                'Join Date',
                _formatFullDate(user.joinDate),
                Iconsax.calendar_bold,
                isDark,
              ),
              _buildDivider(isDark),
              _buildInfoRow(
                'Email Verified',
                user.isVerify ? 'Yes' : 'No',
                user.isVerify ? Iconsax.tick_circle_bold : Iconsax.close_circle_bold,
                isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Statistics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: TAdminColors.getOnSurfaceColor(isDark),
          ),
        ),
        SizedBox(height: 16),

        Row(
          children: [
            // Total Score card
            Expanded(
              child: _buildStatCard(
                'Total Score',
                '${user.totalScore}',
                Iconsax.star_bold,
                TAdminColors.primary,
                isDark,
              ),
            ),
            SizedBox(width: 16),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label,
      String value,
      IconData icon,
      bool isDark, {
        bool copyable = false,
      }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
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

  Widget _buildStatCard(String title,
      String value,
      IconData icon,
      Color color,
      bool isDark,) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: color,
              ),
              Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: TAdminColors.getOnSurfaceColor(isDark),
            ),
          ),
        ],
      ),
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
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () => Get.back(),
            child: Text('Close'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TAdminColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatFullDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}