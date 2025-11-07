import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../common/widgets/appbar/appbar.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/validators/user_profile_validator.dart';
import '../../../controllers/update_profile_controller.dart';

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UpdateProfileController());

    return Scaffold(
      appBar: const TAppBar(
        showBackArrow: true,
        title: Text('Change Password'),
      ),
      body: Obx(() {
        // Step 1: Verify current password
        if (!controller.isPasswordVerified.value) {
          return _buildVerifyPasswordStep(context, controller);
        }
        // Step 2: Enter new password
        else {
          return _buildNewPasswordStep(context, controller);
        }
      }),
    );
  }

  /// Step 1: Verify Current Password
  Widget _buildVerifyPasswordStep(BuildContext context, UpdateProfileController controller) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Title
            Text(
              'Verify Your Identity',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwItems / 2),

            /// Instructions
            Text(
              'Please enter your current password to continue',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwSections),

            /// Current Password Field
            Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: controller.oldPassword,
                  obscureText: controller.hideOldPassword.value,
                  autofocus: true,
                  onChanged: (value) {
                    // Clear error when typing
                    if (controller.oldPasswordError.value.isNotEmpty) {
                      controller.oldPasswordError.value = '';
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: const Icon(Iconsax.password_check_bold),
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.hideOldPassword.value
                            ? Iconsax.eye_slash_bold
                            : Iconsax.eye_bold,
                      ),
                      onPressed: () => controller.hideOldPassword.value =
                      !controller.hideOldPassword.value,
                    ),
                    errorText: controller.oldPasswordError.value.isEmpty
                        ? null
                        : controller.oldPasswordError.value,
                  ),
                ),
              ],
            )),
            const SizedBox(height: TSizes.spaceBtwSections),

            /// Verify Button
            Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isVerifyingPassword.value ? null : () {
                  // 检查密码是否为空
                  if (controller.oldPassword.text.trim().isEmpty) {
                    controller.oldPasswordError.value = 'Please enter your current password';
                    return;
                  }
                  controller.verifyOldPassword();
                },
                child: controller.isVerifyingPassword.value
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text('Continue'),
              ),
            )),
          ],
        ),
      ),
    );
  }

  /// Step 2: Enter New Password
  Widget _buildNewPasswordStep(BuildContext context, UpdateProfileController controller) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Form(
          key: controller.passwordFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Title
              Text(
                'Create New Password',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwItems / 2),

              /// Instructions
              Text(
                'Choose a strong password for your account',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// New Password
              Obx(() => TextFormField(
                controller: controller.newPassword,
                validator: TUserProfileValidator.validateNewPassword,
                obscureText: controller.hideNewPassword.value,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Iconsax.lock_bold),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.hideNewPassword.value
                          ? Iconsax.eye_slash_bold
                          : Iconsax.eye_bold,
                    ),
                    onPressed: () => controller.hideNewPassword.value =
                    !controller.hideNewPassword.value,
                  ),
                ),
              )),
              const SizedBox(height: TSizes.spaceBtwInputFields / 2),

              /// Password Requirements
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Password must contain:',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    _buildRequirement('At least 8 characters'),
                    _buildRequirement('One uppercase letter'),
                    _buildRequirement('One lowercase letter'),
                    _buildRequirement('One number'),
                    _buildRequirement('One special character'),
                  ],
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwInputFields),

              /// Confirm New Password
              Obx(() => TextFormField(
                controller: controller.confirmPassword,
                validator: (value) =>
                    TUserProfileValidator.validateConfirmNewPassword(
                      value,
                      controller.newPassword.text,
                    ),
                obscureText: controller.hideConfirmPassword.value,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: const Icon(Iconsax.lock_1_bold),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.hideConfirmPassword.value
                          ? Iconsax.eye_slash_bold
                          : Iconsax.eye_bold,
                    ),
                    onPressed: () =>
                    controller.hideConfirmPassword.value =
                    !controller.hideConfirmPassword.value,
                  ),
                ),
              )),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// Action Buttons
              Row(
                children: [
                  /// Back Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => controller.resetPasswordChangeState(),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwInputFields),

                  /// Change Password Button
                  Expanded(
                    flex: 2,
                    child: Obx(() => ElevatedButton(
                      onPressed: controller.isPasswordLoading.value
                          ? null
                          : () => controller.changePassword(),
                      child: controller.isPasswordLoading.value
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Text('Change Password'),
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

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 2),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}