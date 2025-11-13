import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../utils/constants/admin_colors.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../authentication/models/user_model.dart';

class UserDetailDialog extends StatelessWidget {
  final UserModel user;

  const UserDetailDialog({
    super.key,
    required this.user,
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
          child: CircleAvatar(
            radius: 38,
            backgroundImage: user.profileImg.isNotEmpty
                ? NetworkImage(user.profileImg)
                : null,
            child: user.profileImg.isEmpty
                ? Icon(
              Iconsax.user_bold,
              size: 32,
              color: TAdminColors.getOnSurfaceVariantColor(darkMode),
            )
                : null,
          ),
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
      statusColor = TAdminColors.warning;
      statusText = 'Pending';
      statusIcon = Iconsax.shield_bulk;
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
              _buildDivider(isDark),
              _buildInfoRow(
                'User Type',
                user.userType.isEmpty ? 'Regular User' : user.userType,
                Iconsax.user_tag_bold,
                isDark,
              ),
              _buildDivider(isDark),
              _buildInfoRow(
                'Phone Number',
                user.formattedPhoneNo,
                Iconsax.call_bold,
                isDark,
                copyable: true,
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

            // Login Attempts card
            // Expanded(
            //   child: _buildStatCard(
            //     'Login Attempts',
            //     '${user.loginAttempt}',
            //     Iconsax.login_bold,
            //     user.loginAttempt > 3 ? TAdminColors.warning : TAdminColors.success,
            //     isDark,
            //   ),
            // ),
          ],
        ),

        // if (user.lastAttemptTime > 0) ...[
        //   SizedBox(height: 16),
        //   Container(
        //     width: double.infinity,
        //     padding: EdgeInsets.all(16),
        //     decoration: BoxDecoration(
        //       color: TAdminColors.getSurfaceVariantColor(isDark),
        //       borderRadius: BorderRadius.circular(12),
        //       border: Border.all(
        //         color: TAdminColors.getBorderColor(isDark),
        //       ),
        //     ),
        //     child: Row(
        //       children: [
        //         Icon(
        //           Iconsax.clock_bold,
        //           size: 20,
        //           color: TAdminColors.getOnSurfaceVariantColor(isDark),
        //         ),
        //         SizedBox(width: 12),
        //         Column(
        //           crossAxisAlignment: CrossAxisAlignment.start,
        //           children: [
        //             Text(
        //               'Last Login Attempt',
        //               style: TextStyle(
        //                 fontSize: 14,
        //                 fontWeight: FontWeight.w500,
        //                 color: TAdminColors.getOnSurfaceColor(isDark),
        //               ),
        //             ),
        //             Text(
        //               _formatTimestamp(user.lastAttemptTime),
        //               style: TextStyle(
        //                 fontSize: 12,
        //                 color: TAdminColors.getOnSurfaceVariantColor(isDark),
        //               ),
        //             ),
        //           ],
        //         ),
        //       ],
        //     ),
        //   ),
        // ],
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

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1
          ? ''
          : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1
          ? ''
          : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}