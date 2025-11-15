import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../utils/constants/admin_colors.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../authentication/models/admin_model.dart';

class ManagerDetailDialog extends StatelessWidget {
  final AdminModel manager;

  const ManagerDetailDialog({
    super.key,
    required this.manager,
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

                    // Role information
                    _buildRoleSection(darkMode),
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
            Iconsax.shield_tick_bold,
            size: 24,
            color: TAdminColors.primary,
          ),
          SizedBox(width: 16),
          Text(
            'Manager Details',
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
          child: CircleAvatar(
            radius: 38,
            backgroundImage: manager.profileImg.isNotEmpty
                ? NetworkImage(manager.profileImg)
                : null,
            child: manager.profileImg.isEmpty
                ? Icon(
              Iconsax.user_bold,
              size: 32,
              color: TAdminColors.getOnSurfaceVariantColor(darkMode),
            )
                : null,
          ),
        ),

        SizedBox(width: 20),

        // Manager info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    manager.username,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: TAdminColors.getOnSurfaceColor(darkMode),
                    ),
                  ),
                  SizedBox(width: 12),
                  _buildStatusBadge(darkMode),
                ],
              ),
              SizedBox(height: 4),
              Text(
                manager.email,
                style: TextStyle(
                  fontSize: 16,
                  color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Manager since ${_formatDate(manager.joinDate)}',
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

  Widget _buildStatusBadge(bool darkMode) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (!manager.accountAvailable) {
      statusColor = TAdminColors.banned;
      statusText = 'Banned';
      statusIcon = Iconsax.user_remove_bold;
    } else if (manager.isVerify) {
      statusColor = TAdminColors.success;
      statusText = 'Verified';
      statusIcon = Iconsax.shield_tick_bold;
    } else {
      statusColor = TAdminColors.error;
      statusText = 'Not Verified';
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
                'Manager ID',
                manager.userId,
                Iconsax.card_bold,
                isDark,
                copyable: true,
              ),
              _buildDivider(isDark),
              _buildInfoRow(
                'Email',
                manager.email,
                Icons.email,
                isDark,
                copyable: true,
              ),
              _buildDivider(isDark),
              _buildInfoRow(
                'Role',
                manager.userType.isEmpty ? 'Regular Manager' : manager.userType,
                Iconsax.user_tag_bold,
                isDark,
              ),
              _buildDivider(isDark),
              _buildInfoRow(
                'Phone Number',
                manager.formattedPhoneNo.isNotEmpty ? manager.formattedPhoneNo : 'Not provided',
                Iconsax.call_bold,
                isDark,
                copyable: manager.formattedPhoneNo.isNotEmpty,
              ),
              _buildDivider(isDark),
              _buildInfoRow(
                'Join Date',
                _formatFullDate(manager.joinDate),
                Iconsax.calendar_bold,
                isDark,
              ),
              _buildDivider(isDark),
              _buildInfoRow(
                'Email Verified',
                manager.isVerify ? 'Yes' : 'No',
                manager.isVerify ? Iconsax.tick_circle_bold : Iconsax.close_circle_bold,
                isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSection(bool isDark) {
    final roleColor = TAdminColors.getRoleColor(manager.userType);
    final displayRole = manager.userType.split(' ').map((word) =>
    word[0].toUpperCase() + word.substring(1)
    ).join(' ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Role Information',
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
            color: roleColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: roleColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Iconsax.shield_tick_bold,
                size: 32,
                color: roleColor,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayRole,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: roleColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _getRoleDescription(manager.userType),
                      style: TextStyle(
                        fontSize: 14,
                        color: TAdminColors.getOnSurfaceVariantColor(isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getRoleDescription(String role) {
    switch (role.toLowerCase()) {
      case 'user manager':
        return 'Can manage user accounts, ban/restore users, and edit user information';
      case 'community manager':
        return 'Can manage community content, moderate discussions, and handle reports';
      case 'achievement manager':
        return 'Can create and manage achievements, assign rewards, and track progress';
      default:
        return 'Administrative role with specific management permissions';
    }
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