import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/repositories/user/user_repository.dart';
import '../../../utils/helpers/image_helper.dart';
import '../../authentication/models/user_model.dart';

class AdminProfileController extends GetxController {
  final _authRepo = Get.put(AuthenticationRepository());
  final _userRepo = Get.put(UserRepository());

  // Observable user data
  final Rx<UserModel> currentUser = UserModel.empty().obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  /// Load current user data from Firestore
  Future<void> loadUserData() async {
    try {
      isLoading.value = true;

      // Fetch complete user data from Firestore
      final userData = await _userRepo.fetchUserDetails();

      if (userData.userId.isNotEmpty) {
        currentUser.value = userData;
      } else {
        // Fallback to auth user data if Firestore data not found
        final authUser = _authRepo.authUser;
        if (authUser != null) {
          currentUser.value = UserModel(
            userId: authUser.uid,
            username: authUser.displayName ?? 'Admin User',
            userType: 'administrator',
            email: authUser.email ?? '',
            phoneNumber: authUser.phoneNumber ?? '',
            profileImg: authUser.photoURL ?? '',
            joinDate: DateTime.now(),
            totalScore: 0,
            isVerify: authUser.emailVerified,
            loginAttempt: 0,
            lastAttemptTime: 0,
            accountAvailable: true,
          );
        }
      }
    } catch (e) {
      TLoaders.errorSnackBar(
          title: 'Error',
          message: 'Failed to load profile data: ${e.toString()}'
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Update profile image
  Future<void> updateProfileImage() async {
    try {
      // Import image helper
      final pickedImage = await ImageHelper.pickImage();

      if (pickedImage != null) {
        isLoading.value = true;

        // TODO: Upload image to Firebase Storage and get URL
        // For now, showing a placeholder message
        TLoaders.customToast(message: 'Image selected! Upload feature coming soon.');

        // Example of how you would update after getting the image URL:
        // await _userRepo.updateSingleField({
        //   FirebaseFieldNames.profileImg: imageUrl,
        // });
        //
        // currentUser.value = currentUser.value.copyWith(profileImg: imageUrl);
        // currentUser.refresh();
      }
    } catch (e) {
      TLoaders.errorSnackBar(
          title: 'Error',
          message: 'Failed to update profile image: ${e.toString()}'
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Edit profile - opens edit dialog
  void editProfile() {
    Get.dialog(
      _buildEditProfileDialog(),
      barrierDismissible: false,
    );
  }

  /// Update user profile
  Future<void> updateProfile({
    required String username,
    required String phoneNumber,
  }) async {
    try {
      isLoading.value = true;

      // Update user data
      final updatedUser = UserModel(
        userId: currentUser.value.userId,
        username: username,
        userType: currentUser.value.userType,
        email: currentUser.value.email,
        phoneNumber: phoneNumber,
        profileImg: currentUser.value.profileImg,
        joinDate: currentUser.value.joinDate,
        totalScore: currentUser.value.totalScore,
        isVerify: currentUser.value.isVerify,
        loginAttempt: currentUser.value.loginAttempt,
        lastAttemptTime: currentUser.value.lastAttemptTime,
        accountAvailable: currentUser.value.accountAvailable,
      );

      await _userRepo.updateUserDetails(updatedUser);

      currentUser.value = updatedUser;

      Get.back(); // Close dialog
      TLoaders.successSnackBar(
          title: 'Success',
          message: 'Profile updated successfully!'
      );
    } catch (e) {
      TLoaders.errorSnackBar(
          title: 'Error',
          message: 'Failed to update profile: ${e.toString()}'
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Change password
  void changePassword() {
    Get.dialog(
      _buildChangePasswordDialog(),
      barrierDismissible: false,
    );
  }

  /// Update password
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      isLoading.value = true;

      // Use Firebase Auth to update password
      await _authRepo.updatePassword(currentPassword, newPassword);

      Get.back(); // Close dialog
      TLoaders.successSnackBar(
          title: 'Success',
          message: 'Password updated successfully!'
      );
    } catch (e) {
      TLoaders.errorSnackBar(
          title: 'Error',
          message: 'Failed to update password: ${e.toString()}'
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Copy to clipboard
  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    TLoaders.customToast(message: 'Copied to clipboard');
  }

  /// Build edit profile dialog
  Widget _buildEditProfileDialog() {
    final usernameController = TextEditingController(text: currentUser.value.username);
    final phoneController = TextEditingController(text: currentUser.value.phoneNumber);
    final formKey = GlobalKey<FormState>();

    return AlertDialog(
      title: Text('Edit Profile'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Iconsax.user_bold),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Iconsax.call_bold),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('Cancel'),
        ),
        Obx(() => ElevatedButton(
          onPressed: isLoading.value ? null : () {
            if (formKey.currentState!.validate()) {
              updateProfile(
                username: usernameController.text.trim(),
                phoneNumber: phoneController.text.trim(),
              );
            }
          },
          child: isLoading.value
              ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : Text('Save'),
        )),
      ],
    );
  }

  /// Build change password dialog
  Widget _buildChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final RxBool showCurrentPassword = false.obs;
    final RxBool showNewPassword = false.obs;
    final RxBool showConfirmPassword = false.obs;

    return AlertDialog(
      title: Text('Change Password'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() => TextFormField(
                controller: currentPasswordController,
                obscureText: !showCurrentPassword.value,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: Icon(Iconsax.key_bold),
                  suffixIcon: IconButton(
                    onPressed: () => showCurrentPassword.toggle(),
                    icon: Icon(showCurrentPassword.value ? Iconsax.eye_slash_bold : Iconsax.eye_bold),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              )),
              SizedBox(height: 16),
              Obx(() => TextFormField(
                controller: newPasswordController,
                obscureText: !showNewPassword.value,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(Iconsax.key_bold),
                  suffixIcon: IconButton(
                    onPressed: () => showNewPassword.toggle(),
                    icon: Icon(showNewPassword.value ? Iconsax.eye_slash_bold : Iconsax.eye_bold),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              )),
              SizedBox(height: 16),
              Obx(() => TextFormField(
                controller: confirmPasswordController,
                obscureText: !showConfirmPassword.value,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: Icon(Iconsax.key_bold),
                  suffixIcon: IconButton(
                    onPressed: () => showConfirmPassword.toggle(),
                    icon: Icon(showConfirmPassword.value ? Iconsax.eye_slash_bold : Iconsax.eye_bold),
                  ),
                ),
                validator: (value) {
                  if (value != newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              )),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('Cancel'),
        ),
        Obx(() => ElevatedButton(
          onPressed: isLoading.value ? null : () {
            if (formKey.currentState!.validate()) {
              updatePassword(
                currentPassword: currentPasswordController.text,
                newPassword: newPasswordController.text,
              );
            }
          },
          child: isLoading.value
              ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : Text('Update', style: TextStyle(fontSize: 12),),
        )),
      ],
    );
  }
}