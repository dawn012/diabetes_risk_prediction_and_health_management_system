import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../utils/constants/admin_colors.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../../utils/validators/user_profile_validator.dart';
import '../../controllers/manager_management_controller.dart';

class AddManagerDialog extends StatelessWidget {
  const AddManagerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ManagerManagementController>();
    final darkMode = THelperFunctions.isDarkMode(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 500,
        constraints: BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: TAdminColors.getSurfaceColor(darkMode),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
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
                    Iconsax.user_add_bold,
                    size: 24,
                    color: TAdminColors.primary,
                  ),
                  SizedBox(width: 16),
                  Text(
                    'Add New Manager',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: TAdminColors.getOnSurfaceColor(darkMode),
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: controller.closeAddDialog,
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
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Form(
                  key: controller.addManagerFormKey, // 使用控制器中的 formKey
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Image Section (Optional)
                      Center(
                        child: Column(
                          children: [
                            Obx(() {
                              final selectedImage = controller.selectedImageBytes.value;

                              return Stack(
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: TAdminColors.getBorderColor(darkMode),
                                        width: 3,
                                      ),
                                    ),
                                    child: selectedImage != null
                                        ? ClipOval(
                                      child: Image.memory(
                                        selectedImage,
                                        width: 114,
                                        height: 114,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                        : CircleAvatar(
                                      radius: 58,
                                      child: Icon(
                                        Iconsax.user_bold,
                                        size: 48,
                                        color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: InkWell(
                                      onTap: controller.pickImage,
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
                                        child: Icon(
                                          Iconsax.camera_bold,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                            SizedBox(height: 8),
                            Text(
                              'Profile photo (optional)',
                              style: TextStyle(
                                fontSize: 12,
                                color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 32),

                      // Username Field (Required)
                      Text(
                        'Username *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: TAdminColors.getOnSurfaceColor(darkMode),
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: controller.addUsernameController,
                        maxLength: 30,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_ ]')),
                        ],
                        decoration: InputDecoration(
                          hintText: 'Enter username',
                          hintStyle: TextStyle(
                            color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                          ),
                          prefixIcon: Icon(
                            Iconsax.user_bold,
                            color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                            size: 20,
                          ),
                          filled: true,
                          fillColor: TAdminColors.getSurfaceVariantColor(darkMode),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: TAdminColors.primary,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: TAdminColors.error,
                              width: 2,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: TAdminColors.error,
                              width: 2,
                            ),
                          ),
                          counterText: '',
                        ),
                        style: TextStyle(
                          color: TAdminColors.getOnSurfaceColor(darkMode),
                        ),
                        validator: (value) {
                          // 基础验证
                          final baseValidation = TUserProfileValidator.validateUsername(value);
                          if (baseValidation != null) {
                            return baseValidation;
                          }

                          // 检查重复用户名错误
                          if (controller.usernameDuplicateError.value.isNotEmpty) {
                            return controller.usernameDuplicateError.value;
                          }

                          return null;
                        },
                        onChanged: (value) {
                          // 清除重复用户名错误
                          if (controller.usernameDuplicateError.value.isNotEmpty) {
                            controller.usernameDuplicateError.value = '';
                          }
                        },
                      ),

                      SizedBox(height: 24),

                      // Email Field (Required)
                      Text(
                        'Email *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: TAdminColors.getOnSurfaceColor(darkMode),
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: controller.addEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Enter email address',
                          hintStyle: TextStyle(
                            color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                          ),
                          prefixIcon: Icon(
                            Icons.email,
                            color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                            size: 20,
                          ),
                          filled: true,
                          fillColor: TAdminColors.getSurfaceVariantColor(darkMode),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: TAdminColors.primary,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: TAdminColors.error,
                              width: 2,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: TAdminColors.error,
                              width: 2,
                            ),
                          ),
                        ),
                        style: TextStyle(
                          color: TAdminColors.getOnSurfaceColor(darkMode),
                        ),
                        validator: (value) {
                          // 基础验证
                          final baseValidation = TUserProfileValidator.validateEmail(value);
                          if (baseValidation != null) {
                            return baseValidation;
                          }

                          // 检查重复邮箱错误
                          if (controller.emailDuplicateError.value.isNotEmpty) {
                            return controller.emailDuplicateError.value;
                          }

                          return null;
                        },
                        onChanged: (value) {
                          // 清除重复邮箱错误
                          if (controller.emailDuplicateError.value.isNotEmpty) {
                            controller.emailDuplicateError.value = '';
                          }
                        },
                      ),

                      SizedBox(height: 24),

                      // Role Selection (Required)
                      Text(
                        'Role *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: TAdminColors.getOnSurfaceColor(darkMode),
                        ),
                      ),
                      SizedBox(height: 8),
                      Obx(() => Container(
                        decoration: BoxDecoration(
                          color: TAdminColors.getSurfaceVariantColor(darkMode),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: controller.selectedRole.value,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Iconsax.shield_tick_bold,
                              color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: TAdminColors.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          dropdownColor: TAdminColors.getSurfaceColor(darkMode),
                          style: TextStyle(
                            color: TAdminColors.getOnSurfaceColor(darkMode),
                            fontSize: 14,
                          ),
                          items: controller.managerRoles.map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(
                                role.split(' ').map((word) =>
                                word[0].toUpperCase() + word.substring(1)
                                ).join(' '),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              controller.selectedRole.value = value;
                            }
                          },
                        ),
                      )),

                      SizedBox(height: 24),

                      // Info note
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: TAdminColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: TAdminColors.info.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Iconsax.info_circle_bold,
                              size: 20,
                              color: TAdminColors.info,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'A verification email will be sent to the manager. They will need to verify their email and set their password before accessing the system.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: TAdminColors.getOnSurfaceColor(darkMode),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: TAdminColors.getSurfaceVariantColor(darkMode),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: controller.closeAddDialog,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Cancel'),
                  ),
                  SizedBox(width: 16),
                  Obx(() => ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () {
                      if (controller.addManagerFormKey.currentState!.validate()) {
                        controller.addManager();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TAdminColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Text('Add Manager'),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}