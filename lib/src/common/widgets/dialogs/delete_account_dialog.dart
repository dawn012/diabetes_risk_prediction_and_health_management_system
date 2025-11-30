import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/helpers/helper_functions.dart';

class DeleteAccountDialog {
  DeleteAccountDialog._();

  /// Show delete account dialog with password verification
  static Future<bool?> show({
    required VoidCallback onConfirm,
  }) async {
    final context = Get.context!;
    final isDark = THelperFunctions.isDarkMode(context);

    final passwordController = TextEditingController();
    final hidePassword = true.obs;
    final passwordError = ''.obs;
    final isVerifying = false.obs;

    return await Get.dialog<bool>(
      Dialog(
        backgroundColor: isDark ? TColors.dark : TColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          // 让内容在键盘弹出时可以滚动
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 400,
            ),
            child: Padding(
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
                      color: isDark ? TColors.white : TColors.black,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Message
                  Text(
                    'Are you sure you want to delete your account permanently? This action is not reversible and all of your data will be removed permanently.',
                    style: TextStyle(
                      color:
                      isDark ? TColors.darkGrey : TColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 20),

                  // Password verification section
                  Text(
                    'Please enter your password to confirm',
                    style: TextStyle(
                      color: isDark ? TColors.white : TColors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Password Field
                  Obx(
                        () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: passwordController,
                          obscureText: hidePassword.value,
                          autofocus: true,
                          style: TextStyle(
                            color: isDark ? TColors.white : TColors.black,
                          ),
                          onChanged: (value) {
                            // Clear error when typing
                            if (passwordError.value.isNotEmpty) {
                              passwordError.value = '';
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            hintStyle: TextStyle(
                              color:
                              isDark ? TColors.darkGrey : Colors.grey,
                            ),
                            prefixIcon: Icon(
                              Iconsax.password_check_bold,
                              color:
                              isDark ? TColors.darkGrey : Colors.grey,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                hidePassword.value
                                    ? Iconsax.eye_slash_bold
                                    : Iconsax.eye_bold,
                                color: isDark
                                    ? TColors.darkGrey
                                    : Colors.grey,
                              ),
                              onPressed: () => hidePassword.value =
                              !hidePassword.value,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: passwordError.value.isEmpty
                                    ? (isDark
                                    ? TColors.darkGrey
                                    : Colors.grey[300]!)
                                    : TColors.error,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: passwordError.value.isEmpty
                                    ? TColors.primary
                                    : TColors.error,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: TColors.error),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: TColors.error),
                            ),
                            filled: true,
                            fillColor: isDark
                                ? TColors.darkGrey.withOpacity(0.3)
                                : Colors.grey[100],
                          ),
                        ),
                        if (passwordError.value.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 8, left: 12),
                            child: Text(
                              passwordError.value,
                              style: const TextStyle(
                                color: TColors.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      // Cancel button
                      Expanded(
                        child: TextButton(
                          onPressed: () =>
                              Get.back(result: false),
                          style: TextButton.styleFrom(
                            foregroundColor: isDark
                                ? TColors.white
                                : TColors.black,
                            backgroundColor: isDark
                                ? TColors.darkGrey
                                .withOpacity(0.5)
                                : Colors.grey[200],
                            padding:
                            const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                              color: isDark
                                  ? TColors.white
                                  : TColors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Delete button
                      Expanded(
                        child: Obx(
                              () => ElevatedButton(
                            onPressed: isVerifying.value
                                ? null
                                : () async {
                              // Validate password
                              final password =
                              passwordController.text
                                  .trim();
                              if (password.isEmpty) {
                                passwordError.value =
                                'Please enter your password';
                                return;
                              }

                              // Verify password
                              isVerifying.value = true;
                              passwordError.value = '';

                              try {
                                final user = FirebaseAuth
                                    .instance.currentUser;
                                if (user == null) {
                                  passwordError.value =
                                  'User not found. Please login again.';
                                  isVerifying.value =
                                  false;
                                  return;
                                }

                                final credential =
                                EmailAuthProvider
                                    .credential(
                                  email: user.email!,
                                  password: password,
                                );

                                await user
                                    .reauthenticateWithCredential(
                                    credential);

                                // Password is correct
                                isVerifying.value =
                                false;
                                Get.back(result: true);
                                onConfirm();
                              } on FirebaseAuthException catch (e) {
                                isVerifying.value =
                                false;
                                if (e.code ==
                                    'wrong-password' ||
                                    e.code ==
                                        'invalid-credential') {
                                  passwordError.value =
                                  'Incorrect password. Please try again.';
                                } else {
                                  passwordError.value =
                                  'Failed to verify password. Please try again.';
                                }
                              } catch (e) {
                                isVerifying.value =
                                false;
                                passwordError.value =
                                'An error occurred. Please try again.';
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TColors.error,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                              TColors.error
                                  .withOpacity(0.5),
                              disabledForegroundColor:
                              Colors.white
                                  .withOpacity(0.7),
                              padding:
                              const EdgeInsets.symmetric(
                                  vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(20),
                              ),
                              side: BorderSide.none,
                            ),
                            child: isVerifying.value
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                              CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                AlwaysStoppedAnimation<
                                    Color>(
                                    Colors.white),
                              ),
                            )
                                : const Text(
                              'Delete',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }
}
