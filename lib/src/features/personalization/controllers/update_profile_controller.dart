import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/repositories/user/user_repository.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/network_manager.dart';
import 'user_controller.dart';

class UpdateProfileController extends GetxController {
  static UpdateProfileController get instance => Get.find();

  final userController = UserController.instance;
  final userRepository = UserRepository.instance;

  /// Observables for pending changes
  final hasPendingChanges = false.obs;
  final pendingProfileImage = Rx<File?>(null);

  /// Temporary storage for profile changes
  final pendingChanges = <String, dynamic>{}.obs;

  /// Password Controllers
  final oldPassword = TextEditingController();
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();
  final hideOldPassword = true.obs;
  final hideNewPassword = true.obs;
  final hideConfirmPassword = true.obs;

  /// Password Form Key
  final passwordFormKey = GlobalKey<FormState>();

  /// Loading states
  final isPasswordLoading = false.obs;
  final isVerifyingPassword = false.obs;

  /// Password verification
  final isPasswordVerified = false.obs;
  final oldPasswordError = ''.obs;

  /// Initialize profile data
  @override
  void onInit() {
    super.onInit();
    resetPendingChanges();
  }

  /// Reset all pending changes
  void resetPendingChanges() {
    pendingChanges.clear();
    pendingProfileImage.value = null;
    hasPendingChanges.value = false;
  }

  /// Update pending change for a field
  void updatePendingChange(String field, dynamic value) {
    // 对于 username 和 phoneNumber，不应该进入 pending changes
    if (field == 'username' || field == 'phoneNumber') {
      print('Warning: $field should not be added to pending changes');
      return;
    }

    final user = userController.user.value;
    final profile = user.profile;

    // 获取原始值
    dynamic originalValue;
    switch (field) {
      case 'gender':
        originalValue = profile.gender;
        break;
      case 'dateOfBirth':
        originalValue = profile.dateOfBirth;
        break;
      case 'height':
        originalValue = profile.height;
        break;
      // case 'dietPreference':
      //   originalValue = profile.dietPreference;
      //   break;
      // case 'allergies':
      //   originalValue = profile.allergies;
      //   break;
      default:
        originalValue = null;
    }

    // 检查新值是否与原始值相同
    bool isDifferent = false;

    if (value is List<String> && originalValue is List<String>) {
      isDifferent = !_areListsEqual(value, originalValue);
    } else if (value is DateTime && originalValue is DateTime) {
      isDifferent = value != originalValue;
    } else {
      isDifferent = value != originalValue;
    }

    if (isDifferent) {
      // 值不同，添加到 pending changes
      pendingChanges[field] = value;
    } else {
      // 值与原始值相同，从 pending changes 中移除
      pendingChanges.remove(field);
    }

    // Force update the observable
    pendingChanges.refresh();
    _updateHasPendingChanges();
  }

  /// Update pending profile image with validation and compression
  Future<void> updatePendingProfileImage(File? image) async {
    if (image == null) return;

    try {
      // Show loading while processing image
      TLoaders.customToast(message: 'Processing image...');

      // Use UserController to validate and compress image
      final compressedImage = await userController.validateAndCompressImage(image);

      if (compressedImage != null) {
        // Store the compressed image for preview
        pendingProfileImage.value = compressedImage;
        _updateHasPendingChanges();
        // 成功时不显示消息
      } else {
        // Validation/compression failed, clear the pending image
        pendingProfileImage.value = null;
        _updateHasPendingChanges();
        // 失败时显示错误消息（validateAndCompressImage 内部已经显示）
      }
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Image Processing Failed',
        message: 'Failed to process image: $e',
      );
      pendingProfileImage.value = null;
      _updateHasPendingChanges();
    }
  }

  /// Check if there are any pending changes
  void _updateHasPendingChanges() {
    hasPendingChanges.value = pendingChanges.isNotEmpty || pendingProfileImage.value != null;
  }

  /// Apply all pending changes
  Future<void> applyAllChanges() async {
    if (!hasPendingChanges.value) {
      TLoaders.warningSnackBar(
        title: 'No Changes',
        message: 'No changes were made to your profile.',
      );
      return;
    }

    try {
      // Check Internet
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) return;

      // Show loading
      TLoaders.customToast(message: 'Updating profile...');

      // Upload profile image if changed
      if (pendingProfileImage.value != null) {
        await _uploadProfileImage();
      }

      // 不再处理 username 和 phoneNumber，因为它们已经直接保存了
      // 只处理其他字段的 pending changes

      // Apply profile-level changes
      if (_hasProfileChanges()) {
        await _applyProfileChanges();
      }

      // Clear pending changes
      resetPendingChanges();

      // Refresh user data
      await userController.fetchUserRecord();

      // Success message
      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Your profile has been updated successfully.',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: TTexts.error,
        message: e.toString(),
      );
      print('applyAllChanges error: $e');
    }
  }

  /// 获取包含 pending changes 的当前值
  T getCurrentValueWithPending<T>(String field, T originalValue) {
    if (pendingChanges.containsKey(field)) {
      return pendingChanges[field] as T;
    }
    return originalValue;
  }

  /// Upload profile image (only when user confirms)
  Future<void> _uploadProfileImage() async {
    if (pendingProfileImage.value == null) return;

    try {
      // 使用 UserController 上传压缩后的图片，自动处理旧图片删除
      final imageUrl = await userController.uploadCompressedImage(compressedImage: pendingProfileImage.value!);

      if (imageUrl == null) {
        throw 'Failed to upload image';
      }

      // 这里不需要再更新数据库和本地状态，因为 uploadCompressedImage 已经处理了
    } catch (e) {
      throw 'Failed to upload profile image: $e';
    }
  }

  /// Upload profile image
  // Future<void> _uploadProfileImage() async {
  //   if (pendingProfileImage.value == null) return;
  //
  //   final imageUrl = await userRepository.uploadImage(
  //     'profile/images',
  //     XFile(pendingProfileImage.value!.path),
  //   );
  //
  //   if (imageUrl.isEmpty) {
  //     throw 'Failed to upload image';
  //   }
  //
  //   await userRepository.updateSingleField({'profileImg': imageUrl});
  // }

  /// Check if there are profile-level changes (排除 username 和 phoneNumber)
  bool _hasProfileChanges() {
    return pendingChanges.containsKey('gender') ||
        pendingChanges.containsKey('dateOfBirth') ||
        pendingChanges.containsKey('height') ||
        pendingChanges.containsKey('dietPreference') ||
        pendingChanges.containsKey('allergies');
  }

  /// Apply profile-level changes
  Future<void> _applyProfileChanges() async {
    final currentProfile = userController.user.value.profile;

    // Track if critical fields are being changed
    bool genderChanged = false;
    bool dobChanged = false;

    if (pendingChanges.containsKey('gender') && currentProfile.hasGender) {
      genderChanged = true;
    }

    if (pendingChanges.containsKey('dateOfBirth') && currentProfile.hasDateOfBirth) {
      dobChanged = true;
    }

    final updatedProfile = currentProfile.copyWith(
      gender: pendingChanges['gender'] as String? ?? currentProfile.gender,
      dateOfBirth: pendingChanges['dateOfBirth'] as DateTime? ?? currentProfile.dateOfBirth,
      height: pendingChanges['height'] as double? ?? currentProfile.height,
      // dietPreference: pendingChanges['dietPreference'] as String? ?? currentProfile.dietPreference,
      // allergies: pendingChanges['allergies'] as List<String>? ?? currentProfile.allergies,
      hasChangedGender: genderChanged || currentProfile.hasChangedGender,
      hasChangedDateOfBirth: dobChanged || currentProfile.hasChangedDateOfBirth,
      updatedAt: DateTime.now(),
    );

    await userRepository.updateUserProfile(
      userController.user.value.userId,
      updatedProfile,
    );
  }

  /// Helper method to compare lists
  bool _areListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  // ========== PASSWORD MANAGEMENT ==========

  /// Verify old password
  Future<void> verifyOldPassword() async {
    if (oldPassword.text.trim().isEmpty) {
      return;
    }

    try {
      isVerifyingPassword.value = true;
      oldPasswordError.value = '';

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        oldPasswordError.value = 'User not found. Please login again.';
        isVerifyingPassword.value = false;
        return;
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword.text.trim(),
      );

      await user.reauthenticateWithCredential(credential);

      isPasswordVerified.value = true;
      oldPasswordError.value = '';
    } on FirebaseAuthException catch (e) {
      isPasswordVerified.value = false;
      if (e.code == 'wrong-password') {
        oldPasswordError.value = 'Incorrect password. Please try again.';
      } else {
        oldPasswordError.value = 'Failed to verify password. Please try again.';
      }
    } catch (e) {
      isPasswordVerified.value = false;
      oldPasswordError.value = 'An error occurred. Please try again.';
    } finally {
      isVerifyingPassword.value = false;
    }
  }

  /// Change password
  Future<void> changePassword() async {
    try {
      // Check Internet
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        return;
      }

      // Form Validation
      if (!passwordFormKey.currentState!.validate()) {
        return;
      }

      // Check if password is verified
      if (!isPasswordVerified.value) {
        oldPasswordError.value = 'Please verify your current password first.';
        return;
      }

      // Check if new password is same as old password
      if (oldPassword.text.trim() == newPassword.text.trim()) {
        TLoaders.errorSnackBar(
          title: 'Invalid Password',
          message: 'New password cannot be the same as current password.',
        );
        return;
      }

      // Start Loading
      isPasswordLoading.value = true;

      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        isPasswordLoading.value = false;
        TLoaders.errorSnackBar(
          title: 'Error',
          message: 'User not found. Please login again.',
        );
        return;
      }

      // Update password
      await user.updatePassword(newPassword.text.trim());

      // Clear password fields and reset state
      oldPassword.clear();
      newPassword.clear();
      confirmPassword.clear();
      isPasswordVerified.value = false;
      oldPasswordError.value = '';
      hideOldPassword.value = true;
      hideNewPassword.value = true;
      hideConfirmPassword.value = true;

      // Stop Loading
      isPasswordLoading.value = false;

      // Logout user for security
      await AuthenticationRepository.instance.logout(title: 'Password Changed', message: 'Your password has been changed successfully. For your security, you have been logged out. Please log in again using your new password.');
    } catch (e) {
      // Stop Loading
      isPasswordLoading.value = false;
      TLoaders.errorSnackBar(title: TTexts.error, message: e.toString());
    }
  }

  /// Reset password change state (when user goes back)
  void resetPasswordChangeState() {
    isPasswordVerified.value = false;
    newPassword.clear();
    confirmPassword.clear();
    hideNewPassword.value = true;
    hideConfirmPassword.value = true;
  }

  // ========== GOALS MANAGEMENT ==========

  /// Update single goal (called from dialog)
  Future<void> updateSingleGoal(String goalType, int value) async {
    try {
      // Check Internet
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TLoaders.errorSnackBar(
          title: 'No Internet',
          message: 'Please check your internet connection and try again.',
        );
        return;
      }

      // Get current profile
      final currentProfile = userController.user.value.profile;

      // Check if there are changes
      if (goalType == 'dailyStepsGoal' && currentProfile.dailyStepsGoal == value) {
        TLoaders.warningSnackBar(
          title: 'No Changes',
          message: 'No changes were made to your daily steps goal.',
        );
        return;
      }

      if (goalType == 'weeklyExerciseTime' && currentProfile.weeklyExerciseTime == value) {
        TLoaders.warningSnackBar(
          title: 'No Changes',
          message: 'No changes were made to your weekly exercise goal.',
        );
        return;
      }

      // Update profile field
      final updatedProfile = goalType == 'dailyStepsGoal'
          ? currentProfile.copyWith(dailyStepsGoal: value, updatedAt: DateTime.now())
          : currentProfile.copyWith(weeklyExerciseTime: value, updatedAt: DateTime.now());

      // Update in Firebase
      await userRepository.updateUserProfile(
        userController.user.value.userId,
        updatedProfile,
      );

      // Update local user model
      final updatedUser = userController.user.value.copyWith(profile: updatedProfile);
      userController.user.value = updatedUser;

      // Success Message
      TLoaders.successSnackBar(
        title: 'Success',
        message: goalType == 'dailyStepsGoal'
            ? 'Daily steps goal updated to $value steps.'
            : 'Weekly exercise goal updated to $value minutes.',
      );
    } catch (e) {
      print('Error updating goal: $e');
      TLoaders.errorSnackBar(
          title: TTexts.error,
          message: 'Failed to update goal. Please try again.'
      );
    }
  }

  @override
  void onClose() {
    resetPendingChanges();
    oldPassword.dispose();
    newPassword.dispose();
    confirmPassword.dispose();
    super.onClose();
  }
}