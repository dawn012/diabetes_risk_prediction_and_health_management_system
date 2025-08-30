import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../utils/constants/admin_colors.dart';
import '../../../utils/helpers/helper_functions.dart';

class CommonConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmButtonText;
  final String? cancelButtonText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final IconData? customIcon;
  final Color? iconColor;
  final Color? confirmButtonColor;
  final Widget? customContent;
  final bool showCancel;
  final double? maxWidth;

  const CommonConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmButtonText,
    this.cancelButtonText,
    this.onConfirm,
    this.onCancel,
    this.customIcon,
    this.iconColor,
    this.confirmButtonColor,
    this.customContent,
    this.showCancel = true,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);
    final isWeb = THelperFunctions.screenWidth() > 600;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? (isWeb ? 400 : 320),
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Container(
          padding: EdgeInsets.all(isWeb ? 24 : 20),
          decoration: BoxDecoration(
            color: TAdminColors.getSurfaceColor(darkMode),
            borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon (only show if provided)
              if (customIcon != null) ...[
                Icon(
                  customIcon!,
                  size: isWeb ? 48 : 40,
                  color: iconColor ?? TAdminColors.primary,
                ),
                SizedBox(height: isWeb ? 16 : 12),
              ],

              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: isWeb ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: TAdminColors.getOnSurfaceColor(darkMode),
                ),
              ),
              SizedBox(height: isWeb ? 8 : 6),

              // Message
              Text(
                message,
                style: TextStyle(
                  fontSize: isWeb ? 16 : 14,
                  color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                ),
                textAlign: TextAlign.center,
              ),

              // Custom content
              if (customContent != null) ...[
                SizedBox(height: isWeb ? 16 : 12),
                customContent!,
              ],

              SizedBox(height: isWeb ? 24 : 20),

              // Buttons
              _buildButtons(context, isWeb),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButtons(BuildContext context, bool isWeb) {
    if (isWeb) {
      // Web: horizontal layout
      return Row(
        children: [
          if (showCancel) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _handleCancel,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 18),
                ),
                child: Text(cancelButtonText ?? 'Cancel'),
              ),
            ),
            SizedBox(width: 16),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: _handleConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmButtonColor ?? TAdminColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 18),
                side: BorderSide(color: confirmButtonColor ?? TAdminColors.primary),
              ),
              child: Text(confirmButtonText),
            ),
          ),
        ],
      );
    } else {
      // Mobile: vertical layout, primary action on top
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmButtonColor ?? TAdminColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(confirmButtonText),
            ),
          ),
          if (showCancel) ...[
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _handleCancel,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(cancelButtonText ?? 'Cancel'),
              ),
            ),
          ],
        ],
      );
    }
  }

  void _handleConfirm() {
    Get.back();
    if (onConfirm != null) {
      onConfirm!();
    }
  }

  void _handleCancel() {
    Get.back();
    if (onCancel != null) {
      onCancel!();
    }
  }
}

// Convenience methods
class ConfirmationDialog {
  static void show({
    required String title,
    required String message,
    required String confirmButtonText,
    String? cancelButtonText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    IconData? customIcon,
    Color? iconColor,
    Color? confirmButtonColor,
    Widget? customContent,
    bool showCancel = true,
    double? maxWidth,
  }) {
    Get.dialog(
      CommonConfirmationDialog(
        title: title,
        message: message,
        confirmButtonText: confirmButtonText,
        cancelButtonText: cancelButtonText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        customIcon: customIcon,
        iconColor: iconColor,
        confirmButtonColor: confirmButtonColor,
        customContent: customContent,
        showCancel: showCancel,
        maxWidth: maxWidth,
      ),
    );
  }

  static void showBanUser(String username, VoidCallback onConfirm) {
    show(
      title: 'Ban User',
      message: 'Are you sure you want to ban $username? This action will disable their account.',
      confirmButtonText: 'Ban User',
      customIcon: Iconsax.user_remove_bold,
      iconColor: TAdminColors.error,
      confirmButtonColor: TAdminColors.error,
      onConfirm: onConfirm,
    );
  }

  static void showRestoreUser(String username, VoidCallback onConfirm) {
    show(
      title: 'Restore User',
      message: 'Are you sure you want to restore $username? This will reactivate their account.',
      confirmButtonText: 'Restore User',
      customIcon: Iconsax.refresh_bold,
      iconColor: TAdminColors.success,
      confirmButtonColor: TAdminColors.success,
      onConfirm: onConfirm,
    );
  }

  static void showLogout({VoidCallback? onConfirm}) {
    show(
      title: 'Logout Confirmation',
      message: 'Are you sure you want to logout?',
      confirmButtonText: 'Logout',
      customIcon: Iconsax.logout_bold,
      iconColor: TAdminColors.warning,
      confirmButtonColor: TAdminColors.error,
      onConfirm: onConfirm,
    );
  }
}