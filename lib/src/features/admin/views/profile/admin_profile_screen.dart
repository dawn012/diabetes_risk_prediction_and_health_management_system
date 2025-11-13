import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../common/loaders/loaders.dart';
import '../../../../common/widgets/images/t_circular_image.dart';
import '../../../../utils/constants/admin_colors.dart';
import '../../../../utils/formatters/formatter.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/admin_profile_controller.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminProfileController());
    final darkMode = THelperFunctions.isDarkMode(context);
    final isWeb = THelperFunctions.screenWidth() > 600;

    return Scaffold(
      backgroundColor: TAdminColors.getBackgroundColor(darkMode),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isWeb ? 32 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            _buildPageHeader(context, darkMode, isWeb),
            SizedBox(height: isWeb ? 32 : 24),

            // Profile Content
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 1200) {
                  // Large screens: Two column layout
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            _buildProfileCard(
                                context, controller, darkMode, isWeb),
                            SizedBox(height: 24),
                            _buildSecurityCard(
                                context, controller, darkMode, isWeb),
                          ],
                        ),
                      ),
                      SizedBox(width: 24),
                      // Right Column
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            _buildPersonalInfoCard(
                                context, controller, darkMode, isWeb),
                            SizedBox(height: 24),
                            _buildActivityCard(
                                context, controller, darkMode, isWeb),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  // Medium and small screens: Single column
                  return Column(
                    children: [
                      _buildProfileCard(context, controller, darkMode, isWeb),
                      SizedBox(height: 24),
                      _buildPersonalInfoCard(
                          context, controller, darkMode, isWeb),
                      SizedBox(height: 24),
                      _buildSecurityCard(context, controller, darkMode, isWeb),
                      SizedBox(height: 24),
                      _buildActivityCard(context, controller, darkMode, isWeb),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context, bool darkMode, bool isWeb) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Settings',
          style: TextStyle(
            fontSize: isWeb ? 28 : 24,
            fontWeight: FontWeight.bold,
            color: TAdminColors.getOnSurfaceColor(darkMode),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Manage your personal information and account settings',
          style: TextStyle(
            fontSize: isWeb ? 16 : 14,
            color: TAdminColors.getOnSurfaceVariantColor(darkMode),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context,
      AdminProfileController controller, bool darkMode, bool isWeb) {
    return Container(
      padding: EdgeInsets.all(isWeb ? 32 : 24),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceColor(darkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TAdminColors.getBorderColor(darkMode)),
        boxShadow: [
          BoxShadow(
            color: darkMode ? Colors.black26 : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Image Section
          Stack(
            children: [
              Obx(() => TCircularImage(
                    image: controller.currentAdmin.value.profileImg.isNotEmpty
                        ? controller.currentAdmin.value.profileImg
                        : 'assets/images/user/default_avatar.png',
                    width: isWeb ? 120 : 100,
                    height: isWeb ? 120 : 100,
                    isNetworkImage:
                        controller.currentAdmin.value.profileImg.isNotEmpty,
                  )),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: TAdminColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: TAdminColors.getSurfaceColor(darkMode),
                      width: 2,
                    ),
                  ),
                  child: GestureDetector(
                    onTap: controller.updateProfileImage,
                    child: Icon(
                      Iconsax.camera_bold,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 24),

          // User Info
          Obx(() => Column(
                children: [
                  Text(
                    controller.currentAdmin.value.username.isEmpty
                        ? 'Admin User'
                        : controller.currentAdmin.value.username,
                    style: TextStyle(
                      fontSize: isWeb ? 24 : 20,
                      fontWeight: FontWeight.bold,
                      color: TAdminColors.getOnSurfaceColor(darkMode),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: TAdminColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: TAdminColors.primary.withOpacity(0.3)),
                    ),
                    child: Text(
                      controller.currentAdmin.value.userType.isEmpty
                          ? 'Administrator'
                          : controller
                              .currentAdmin.value.userType.capitalizeFirst!,
                      style: TextStyle(
                        color: TAdminColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.calendar_bold,
                        size: 16,
                        color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Joined ${THelperFunctions.getFormattedDate(controller.currentAdmin.value.joinDate)}',
                        style: TextStyle(
                          color:
                              TAdminColors.getOnSurfaceVariantColor(darkMode),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              )),

          SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: controller.editProfile,
                  icon: Icon(Iconsax.edit_2_bold, size: 18),
                  label: Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TAdminColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isWeb ? 16 : 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(BuildContext context,
      AdminProfileController controller, bool darkMode, bool isWeb) {
    return Container(
      padding: EdgeInsets.all(isWeb ? 32 : 24),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceColor(darkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TAdminColors.getBorderColor(darkMode)),
        boxShadow: [
          BoxShadow(
            color: darkMode ? Colors.black26 : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.user_edit_bold,
                color: TAdminColors.primary,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: isWeb ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: TAdminColors.getOnSurfaceColor(darkMode),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Obx(() => Column(
                children: [
                  _buildInfoRow(
                    'Email',
                    controller.currentAdmin.value.email,
                    Iconsax.sms_bold,
                    darkMode,
                    isWeb,
                  ),
                  _buildInfoRow(
                    'Phone',
                    controller.currentAdmin.value.phoneNumber.isEmpty
                        ? 'Not provided'
                        : TFormatter.formatPhoneNumber(
                            controller.currentAdmin.value.phoneNumber),
                    Iconsax.call_bold,
                    darkMode,
                    isWeb,
                  ),
                  _buildInfoRow(
                    'User ID',
                    controller.currentAdmin.value.userId,
                    Iconsax.code_bold,
                    darkMode,
                    isWeb,
                    copyable: true,
                  ),
                  // _buildInfoRow(
                  //   'Total Score',
                  //   '${controller.currentAdmin.value.totalScore} points',
                  //   Iconsax.medal_star_bold,
                  //   darkMode,
                  //   isWeb,
                  // ),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildSecurityCard(BuildContext context,
      AdminProfileController controller, bool darkMode, bool isWeb) {
    return Container(
      padding: EdgeInsets.all(isWeb ? 32 : 24),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceColor(darkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TAdminColors.getBorderColor(darkMode)),
        boxShadow: [
          BoxShadow(
            color: darkMode ? Colors.black26 : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.shield_tick_bold,
                color: TAdminColors.success,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Security & Access',
                style: TextStyle(
                  fontSize: isWeb ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: TAdminColors.getOnSurfaceColor(darkMode),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Obx(() => Column(
                children: [
                  _buildSecurityRow(
                    'Account Status',
                    controller.currentAdmin.value.accountAvailable
                        ? 'Active'
                        : 'Suspended',
                    controller.currentAdmin.value.accountAvailable
                        ? TAdminColors.success
                        : TAdminColors.error,
                    controller.currentAdmin.value.accountAvailable
                        ? Iconsax.tick_circle_bold
                        : Iconsax.close_circle_bold,
                    darkMode,
                    isWeb,
                  ),
                  _buildSecurityRow(
                    'Email Verification',
                    controller.currentAdmin.value.isVerify
                        ? 'Verified'
                        : 'Unverified',
                    controller.currentAdmin.value.isVerify
                        ? TAdminColors.success
                        : TAdminColors.warning,
                    controller.currentAdmin.value.isVerify
                        ? Iconsax.verify_bold
                        : Iconsax.warning_2_bold,
                    darkMode,
                    isWeb,
                  ),
                  _buildInfoRow(
                    'Login Attempts',
                    '${controller.currentAdmin.value.loginAttempt}',
                    Iconsax.login_bold,
                    darkMode,
                    isWeb,
                  ),
                ],
              )),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: controller.changePassword,
              icon: Icon(Iconsax.key_bold, size: 18),
              label: Text('Change Password'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: isWeb ? 16 : 14),
                side: BorderSide(color: TAdminColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context,
      AdminProfileController controller, bool darkMode, bool isWeb) {
    return Container(
      padding: EdgeInsets.all(isWeb ? 32 : 24),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceColor(darkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TAdminColors.getBorderColor(darkMode)),
        boxShadow: [
          BoxShadow(
            color: darkMode ? Colors.black26 : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.activity_bold,
                color: TAdminColors.info,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: isWeb ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: TAdminColors.getOnSurfaceColor(darkMode),
                ),
              ),
            ],
          ),

          SizedBox(height: 24),

          // Activity items
          Column(
            children: [
              _buildActivityItem(
                'Profile updated',
                '2 hours ago',
                Iconsax.user_edit_bold,
                TAdminColors.success,
                darkMode,
                isWeb,
              ),
              _buildActivityItem(
                'Password changed',
                '1 day ago',
                Iconsax.key_bold,
                TAdminColors.info,
                darkMode,
                isWeb,
              ),
              _buildActivityItem(
                'Login from new device',
                '3 days ago',
                Iconsax.mobile_bold,
                TAdminColors.warning,
                darkMode,
                isWeb,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      String label, String value, IconData icon, bool darkMode, bool isWeb,
      {bool copyable = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: TAdminColors.getSurfaceVariantColor(darkMode),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: TAdminColors.getOnSurfaceVariantColor(darkMode),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isWeb ? 16 : 14,
                    fontWeight: FontWeight.w500,
                    color: TAdminColors.getOnSurfaceColor(darkMode),
                  ),
                ),
              ],
            ),
          ),
          if (copyable)
            IconButton(
              onPressed: () {
                // Copy to clipboard logic
                TLoaders.customToast(message: 'Copied to clipboard');
              },
              icon: Icon(
                Iconsax.copy_bold,
                size: 18,
                color: TAdminColors.getOnSurfaceVariantColor(darkMode),
              ),
              tooltip: 'Copy',
            ),
        ],
      ),
    );
  }

  Widget _buildSecurityRow(String label, String value, Color statusColor,
      IconData statusIcon, bool darkMode, bool isWeb) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              statusIcon,
              size: 16,
              color: statusColor,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isWeb ? 16 : 14,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon,
      Color iconColor, bool darkMode, bool isWeb) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: iconColor,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isWeb ? 16 : 14,
                    fontWeight: FontWeight.w500,
                    color: TAdminColors.getOnSurfaceColor(darkMode),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  time,
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
}
