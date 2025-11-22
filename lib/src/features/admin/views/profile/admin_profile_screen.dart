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
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
          // Profile Image Section with Edit Controls
          Obx(() {
            final admin = controller.currentAdmin.value;
            final hasProfileImage = admin.profileImg.isNotEmpty;
            final username = admin.username.isNotEmpty ? admin.username : 'Admin';
            final isEditing = controller.isEditingImage.value;
            final selectedImage = controller.selectedImageBytes.value;

            return Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    if (hasProfileImage || selectedImage != null) {
                      _showImagePreview(
                        context,
                        selectedImage != null
                            ? MemoryImage(selectedImage)
                            : NetworkImage(admin.profileImg) as ImageProvider,
                      );
                    }
                  },
                  child: selectedImage != null
                      ? Container(
                    width: isWeb ? 120 : 100,
                    height: isWeb ? 120 : 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: MemoryImage(selectedImage),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                      : hasProfileImage
                      ? TCircularImage(
                    image: admin.profileImg,
                    width: isWeb ? 120 : 100,
                    height: isWeb ? 120 : 100,
                    isNetworkImage: true,
                  )
                      : Container(
                    width: isWeb ? 120 : 100,
                    height: isWeb ? 120 : 100,
                    decoration: BoxDecoration(
                      color: TAdminColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        username.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: isWeb ? 36 : 32,
                        ),
                      ),
                    ),
                  ),
                ),

                // Edit/Cancel/Confirm buttons
                if (isEditing && selectedImage != null) ...[
                  // Cancel button - 左下角
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: TAdminColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: TAdminColors.getSurfaceColor(darkMode),
                          width: 2,
                        ),
                      ),
                      child: GestureDetector(
                        onTap: controller.cancelImageChange,
                        child: Icon(
                          Icons.cancel,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  // Confirm button - 右下角
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: TAdminColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: TAdminColors.getSurfaceColor(darkMode),
                          width: 2,
                        ),
                      ),
                      child: GestureDetector(
                        onTap: controller.confirmImageChange,
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ] else if (!isEditing)
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
                        onTap: controller.pickProfileImage,
                        child: Icon(
                          Iconsax.camera_bold,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),

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
                      : controller.currentAdmin.value.userType
                      .capitalizeFirst!,
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

          // Action Button
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
                Icons.email,
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
                onCopy: () {
                  Clipboard.setData(ClipboardData(
                      text: controller.currentAdmin.value.userId));
                  TLoaders.customToast(message: 'Copied to clipboard');
                },
              ),
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
                'Password',
                '••••••••',
                Iconsax.key_bold,
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

          // Delete Account Button (for managers only)
          Obx(() {
            final userType = controller.currentAdmin.value.userType;
            if (userType.toLowerCase().contains('manager')) {
              return Column(
                children: [
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showDeleteAccountDialog(context, controller);
                      },
                      icon: Icon(Iconsax.trash_bold, size: 18),
                      label: Text('Delete Account'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: isWeb ? 16 : 14),
                        side: BorderSide(color: TAdminColors.error),
                        foregroundColor: TAdminColors.error,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return SizedBox.shrink();
          }),
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
                'Account Statistics',
                style: TextStyle(
                  fontSize: isWeb ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: TAdminColors.getOnSurfaceColor(darkMode),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          Obx(() {
            final admin = controller.currentAdmin.value;
            final daysSinceJoined = DateTime.now()
                .difference(admin.joinDate)
                .inDays;

            return Column(
              children: [
                _buildStatItem(
                  'Member Since',
                  '${daysSinceJoined} days',
                  Iconsax.calendar_bold,
                  TAdminColors.primary,
                  darkMode,
                  isWeb,
                ),
                _buildStatItem(
                  'Account Type',
                  admin.userType.capitalizeFirst ?? 'Admin',
                  Iconsax.user_tag_bold,
                  TAdminColors.secondary,
                  darkMode,
                  isWeb,
                ),
                _buildStatItem(
                  'Login Attempts Remaining',
                  '${admin.loginAttempt}',
                  Iconsax.login_bold,
                  admin.loginAttempt > 2
                      ? TAdminColors.success
                      : TAdminColors.warning,
                  darkMode,
                  isWeb,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      String label,
      String value,
      IconData icon,
      bool darkMode,
      bool isWeb, {
        bool copyable = false,
        VoidCallback? onCopy,
      }) {
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
          if (copyable && onCopy != null)
            IconButton(
              onPressed: onCopy,
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

  Widget _buildStatItem(String title, String value, IconData icon,
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
                    fontWeight: FontWeight.w600,
                    color: TAdminColors.getOnSurfaceColor(darkMode),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePreview(BuildContext context, ImageProvider image) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Stack(
            children: [
              Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: 600,
                    maxHeight: 600,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image(
                      image: image,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(
      BuildContext context, AdminProfileController controller) {
    final darkMode = THelperFunctions.isDarkMode(context);
    final passwordController = TextEditingController();
    final hidePassword = true.obs;
    final passwordError = ''.obs;
    final isVerifying = false.obs;

    Get.dialog(
      Dialog(
        backgroundColor: TAdminColors.getSurfaceColor(darkMode),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Delete Account',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                  color: TAdminColors.getOnSurfaceColor(darkMode),
                ),
              ),
              const SizedBox(height: 12),

              // Warning Message
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TAdminColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: TAdminColors.error.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.warning_2_bold,
                      color: TAdminColors.error,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This action cannot be undone. All your data will be permanently deleted.',
                        style: TextStyle(
                          color: TAdminColors.error,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Password verification section
              Text(
                'Please enter your password to confirm',
                style: TextStyle(
                  color: TAdminColors.getOnSurfaceColor(darkMode),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),

              // Password Field
              Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: passwordController,
                    obscureText: hidePassword.value,
                    autofocus: true,
                    style: TextStyle(
                      color: TAdminColors.getOnSurfaceColor(darkMode),
                    ),
                    onChanged: (value) {
                      if (passwordError.value.isNotEmpty) {
                        passwordError.value = '';
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      hintStyle: TextStyle(
                        color: TAdminColors.getOnSurfaceVariantColor(
                            darkMode),
                      ),
                      prefixIcon: Icon(
                        Iconsax.password_check_bold,
                        color: TAdminColors.getOnSurfaceVariantColor(
                            darkMode),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          hidePassword.value
                              ? Iconsax.eye_slash_bold
                              : Iconsax.eye_bold,
                          color: TAdminColors.getOnSurfaceVariantColor(
                              darkMode),
                        ),
                        onPressed: () =>
                        hidePassword.value = !hidePassword.value,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: passwordError.value.isEmpty
                              ? TAdminColors.getBorderColor(darkMode)
                              : TAdminColors.error,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: passwordError.value.isEmpty
                              ? TAdminColors.primary
                              : TAdminColors.error,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        const BorderSide(color: TAdminColors.error),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        const BorderSide(color: TAdminColors.error),
                      ),
                    ),
                  ),
                  if (passwordError.value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 12),
                      child: Text(
                        passwordError.value,
                        style: const TextStyle(
                          color: TAdminColors.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              )),
              const SizedBox(height: 24),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        passwordController.dispose();
                        Get.back();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                            color: TAdminColors.getBorderColor(darkMode)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: TAdminColors.getOnSurfaceColor(darkMode),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Obx(() => ElevatedButton(
                      onPressed: isVerifying.value
                          ? null
                          : () async {
                        final password =
                        passwordController.text.trim();
                        if (password.isEmpty) {
                          passwordError.value =
                          'Please enter your password';
                          return;
                        }

                        isVerifying.value = true;
                        passwordError.value = '';

                        try {
                          await controller.deleteAccount(password);
                          passwordController.dispose();
                          Get.back();
                        } catch (e) {
                          isVerifying.value = false;
                          if (e.toString().contains('wrong-password') ||
                              e.toString()
                                  .contains('invalid-credential')) {
                            passwordError.value =
                            'Incorrect password. Please try again.';
                          } else {
                            passwordError.value =
                            'Failed to verify password. Please try again.';
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TAdminColors.error,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                        TAdminColors.error.withOpacity(0.5),
                        disabledForegroundColor:
                        Colors.white.withOpacity(0.7),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isVerifying.value
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white),
                        ),
                      )
                          : const Text(
                        'Delete Account',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }
}