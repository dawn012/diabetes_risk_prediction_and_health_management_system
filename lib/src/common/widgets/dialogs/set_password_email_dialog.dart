import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../features/admin/controllers/manager_management_controller.dart';
import '../../../features/authentication/models/admin_model.dart';
import '../../../utils/constants/admin_colors.dart';
import '../../../utils/helpers/helper_functions.dart';

class SetPasswordEmailDialog extends StatelessWidget {
  final AdminModel manager;

  const SetPasswordEmailDialog({
    super.key,
    required this.manager,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ManagerManagementController>();
    final darkMode = THelperFunctions.isDarkMode(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 450,
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: TAdminColors.getSurfaceColor(darkMode),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TAdminColors.warning.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.email,
                  size: 32,
                  color: TAdminColors.warning,
                ),
              ),

              SizedBox(height: 16),

              // Title
              Text(
                'Resend Password Reset Email',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: TAdminColors.getOnSurfaceColor(darkMode),
                ),
              ),

              SizedBox(height: 8),

              // User info
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TAdminColors.getSurfaceVariantColor(darkMode),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Iconsax.user_bold,
                          size: 16,
                          color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                        ),
                        SizedBox(width: 8),
                        Text(
                          manager.username,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: TAdminColors.getOnSurfaceColor(darkMode),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Iconsax.sms_bold,
                          size: 16,
                          color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                        ),
                        SizedBox(width: 8),
                        Text(
                          manager.email,
                          style: TextStyle(
                            color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Message
              Text(
                'This will send a password reset email to the user\'s email address. The user will need to click the password reset link to reset their password.',
                style: TextStyle(
                  color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Obx(() => ElevatedButton.icon(
                      onPressed: controller.isLoading.value
                          ? null
                          : () async {
                        await controller.resendSetPasswordEmail(manager);
                        Get.back();
                      },
                      icon: controller.isLoading.value
                          ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Icon(Icons.email, size: 16),
                      label: Text(controller.isLoading.value ? 'Sending...' : 'Send Email'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TAdminColors.warning,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 18),
                        side: BorderSide(color: TAdminColors.warning),
                      ),
                    )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}