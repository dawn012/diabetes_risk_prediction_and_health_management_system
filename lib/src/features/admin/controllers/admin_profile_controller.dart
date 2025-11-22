import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:image_picker/image_picker.dart';

import '../../../common/loaders/loaders.dart';
import '../../../common/widgets/dialogs/dialog.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/repositories/user/user_repository.dart';
import '../../../utils/constants/admin_colors.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../../../utils/helpers/web_image_helper.dart';
import '../../../utils/validators/user_profile_validator.dart';
import '../../authentication/models/admin_model.dart';
import '../../personalization/controllers/user_controller.dart';

class AdminProfileController extends GetxController {
  final _authRepo = AuthenticationRepository.instance;
  final _userRepo = UserRepository.instance;

  // Observable admin data
  final Rx<AdminModel> currentAdmin = AdminModel.empty().obs;
  final RxBool isLoading = false.obs;

  // Image editing
  final selectedImageBytes = Rx<Uint8List?>(null);
  final isEditingImage = false.obs;
  final hasUnsavedImage = false.obs;

  // Form controllers
  final editUsernameController = TextEditingController();
  final editPhoneController = TextEditingController();

  // Error messages
  final usernameError = Rx<String?>(null);
  final phoneError = Rx<String?>(null);

  // Password change
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final showCurrentPassword = false.obs;
  final showNewPassword = false.obs;
  final showConfirmPassword = false.obs;
  final isCurrentPasswordVerified = false.obs;
  final currentPasswordError = Rx<String?>(null);
  final newPasswordError = Rx<String?>(null);
  final confirmPasswordError = Rx<String?>(null);

  @override
  void onInit() {
    super.onInit();
    loadAdminData();
  }

  @override
  void onClose() {
    editUsernameController.dispose();
    editPhoneController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  /// Load current admin data from Firestore
  Future<void> loadAdminData() async {
    try {
      isLoading.value = true;

      final adminData = await _userRepo.fetchAdminDetails();

      if (adminData.userId.isNotEmpty) {
        currentAdmin.value = adminData;
      } else {
        final authUser = _authRepo.authUser;
        if (authUser != null) {
          currentAdmin.value = AdminModel(
            userId: authUser.uid,
            username: authUser.displayName ?? 'Admin User',
            userType: 'admin',
            email: authUser.email ?? '',
            phoneNumber: authUser.phoneNumber ?? '',
            profileImg: authUser.photoURL ?? '',
            joinDate: DateTime.now(),
            isVerify: authUser.emailVerified,
            loginAttempt: 5,
            lastAttemptTime: 0,
            accountAvailable: true,
          );
        }
      }
    } catch (e) {
      TLoaders.errorSnackBar(
          title: 'Error',
          message: 'Failed to load profile data: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// Pick and validate profile image
  Future<void> pickProfileImage() async {
    try {
      final imageBytes = await WebImageHelper.pickImage();

      if (imageBytes != null) {
        // Validate image
        if (!WebImageHelper.isImageBytes(imageBytes)) {
          TLoaders.errorSnackBar(
            title: 'Invalid Image',
            message: 'Please select a valid image file',
          );
          return;
        }

        if (!WebImageHelper.isImageSizeValid(imageBytes)) {
          TLoaders.errorSnackBar(
            title: 'Image Too Large',
            message: 'Image size must be less than 5MB',
          );
          return;
        }

        TLoaders.customToast(message: 'Processing image...');

        // Compress image
        final compressedImage =
            await WebImageHelper.compressImageToWebP(imageBytes);

        if (compressedImage != null) {
          selectedImageBytes.value = compressedImage;
          isEditingImage.value = true;
          hasUnsavedImage.value = true;
        } else {
          TLoaders.errorSnackBar(
            title: 'Compression Failed',
            message: 'Failed to process image',
          );
        }
      }
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to select image: ${e.toString()}',
      );
    }
  }

  /// Confirm image change
  Future<void> confirmImageChange() async {
    if (selectedImageBytes.value == null) return;

    try {
      isLoading.value = true;

      // Upload to Firebase Storage
      final imageUrl = await _uploadImageToStorage(
        selectedImageBytes.value!,
        currentAdmin.value.userId,
      );

      if (imageUrl != null) {
        // Delete old image if exists
        if (currentAdmin.value.profileImg.isNotEmpty) {
          await _userRepo.deleteImage(currentAdmin.value.profileImg);
        }

        // Update admin profile
        final updatedAdmin = currentAdmin.value.copyWith(profileImg: imageUrl);
        await _userRepo.updateAdminDetails(updatedAdmin);

        currentAdmin.value = updatedAdmin;
        selectedImageBytes.value = null;
        isEditingImage.value = false;
        hasUnsavedImage.value = false;

        await UserController.instance.fetchUserRecord();

        TLoaders.successSnackBar(
          title: 'Success',
          message: 'Profile image updated successfully',
        );
      }
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to update profile image: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Cancel image change
  void cancelImageChange() {
    selectedImageBytes.value = null;
    isEditingImage.value = false;
    hasUnsavedImage.value = false;
  }

  /// Upload compressed image to Firebase Storage
  Future<String?> _uploadImageToStorage(
      Uint8List imageBytes, String userId) async {
    try {
      final storageRef = 'profile/images';

      // Convert Uint8List to XFile for upload
      final tempFile = await _createTempFile(imageBytes);

      final imageUrl = await _userRepo.uploadImage(
        storageRef,
        tempFile,
        oldImageUrl: currentAdmin.value.profileImg,
      );

      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Create temporary XFile from Uint8List
  Future<XFile> _createTempFile(Uint8List bytes) async {
    return XFile.fromData(
      bytes,
      mimeType: 'image/webp',
      name: 'profile_${DateTime.now().millisecondsSinceEpoch}.webp',
    );
  }

  /// Edit profile dialog
  void editProfile() {
    editUsernameController.text = currentAdmin.value.username;
    editPhoneController.text = TUserProfileValidator.convertToDisplayFormat(
      currentAdmin.value.phoneNumber,
    );
    usernameError.value = null;
    phoneError.value = null;

    Get.dialog(
      _buildEditProfileDialog(),
      barrierDismissible: false,
    );
  }

  /// Update admin profile
  Future<void> updateProfile() async {
    try {
      isLoading.value = true;

      final newUsername = editUsernameController.text.trim();
      final newPhone = editPhoneController.text.trim();
      final currentUser = currentAdmin.value;

      bool hasChanges = false;
      bool hasErrors = false;

      // Validate username
      if (newUsername != currentUser.username) {
        final usernameValidation =
            TUserProfileValidator.validateUsername(newUsername);
        if (usernameValidation != null) {
          usernameError.value = usernameValidation;
          hasErrors = true;
        } else {
          final isDuplicate = await _userRepo.checkUsernameDuplicate(
            newUsername,
            currentUser.userId,
          );
          if (isDuplicate) {
            usernameError.value = 'Username is already taken.';
            hasErrors = true;
          } else {
            hasChanges = true;
          }
        }
      }

      // Validate phone number
      if (newPhone !=
          TUserProfileValidator.convertToDisplayFormat(
              currentUser.phoneNumber)) {
        if (newPhone.isNotEmpty) {
          final phoneValidation = TUserProfileValidator.validatePhone(newPhone);
          if (phoneValidation != null) {
            phoneError.value = phoneValidation;
            hasErrors = true;
          } else {
            final phoneForStorage =
                TUserProfileValidator.convertToStorageFormat(newPhone);
            final isDuplicate = await _userRepo.checkPhoneNumberDuplicate(
              phoneForStorage,
              currentUser.userId,
            );
            if (isDuplicate) {
              phoneError.value = 'Phone number is already taken.';
              hasErrors = true;
            } else {
              hasChanges = true;
            }
          }
        } else {
          hasChanges = true;
        }
      }

      if (hasErrors) {
        isLoading.value = false;
        return;
      }

      if (!hasChanges) {
        TLoaders.warningSnackBar(
          title: 'No Changes',
          message: 'No changes were made',
        );
        isLoading.value = false;
        return;
      }

      final updatedAdmin = currentUser.copyWith(
        username: newUsername,
        phoneNumber: newPhone.isEmpty
            ? ''
            : TUserProfileValidator.convertToStorageFormat(newPhone),
      );

      await _userRepo.updateAdminDetails(updatedAdmin);
      currentAdmin.value = updatedAdmin;

      await UserController.instance.fetchUserRecord();

      Get.back();
      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Profile updated successfully',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to update profile: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Change password dialog
  void changePassword() {
    currentPasswordController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
    showCurrentPassword.value = false;
    showNewPassword.value = false;
    showConfirmPassword.value = false;
    isCurrentPasswordVerified.value = false;
    currentPasswordError.value = null;
    newPasswordError.value = null;
    confirmPasswordError.value = null;

    Get.dialog(
      _buildChangePasswordDialog(),
      barrierDismissible: false,
    );
  }

  /// Verify current password
  Future<void> verifyCurrentPassword() async {
    final password = currentPasswordController.text.trim();

    if (password.isEmpty) {
      currentPasswordError.value = 'Please enter your current password.';
      return;
    }

    try {
      isLoading.value = true;
      currentPasswordError.value = null;

      await _authRepo.reAuthenticateWithEmailAndPassword(
        currentAdmin.value.email,
        password,
      );

      isCurrentPasswordVerified.value = true;
    } catch (e) {
      currentPasswordError.value = 'Incorrect password. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Update password
  Future<void> updatePassword() async {
    final currentPassword = currentPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // 重置错误信息
    newPasswordError.value = null;
    confirmPasswordError.value = null;

    // Validate new password
    final newPasswordValidation =
    TUserProfileValidator.validateNewPassword(newPassword);
    if (newPasswordValidation != null) {
      newPasswordError.value = newPasswordValidation;
      return;
    }

    // Check if new password matches current password
    if (newPassword == currentPassword) {
      newPasswordError.value = 'New password cannot be the same as current password.';
      return;
    }

    // Validate confirm password
    final confirmPasswordValidation =
    TUserProfileValidator.validateConfirmNewPassword(
      confirmPassword,
      newPassword,
    );
    if (confirmPasswordValidation != null) {
      confirmPasswordError.value = confirmPasswordValidation;
      return;
    }

    try {
      isLoading.value = true;

      await _authRepo.updatePassword(currentPassword, newPassword);

      // Logout user for security
      await AuthenticationRepository.instance.logout(title: 'Password Changed', message: 'Your password has been changed successfully. For your security, you have been logged out. Please log in again using your new password.');
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to update password: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete account (for managers only)
  Future<void> deleteAccount(String password) async {
    try {
      isLoading.value = true;

      // Verify password first
      await _authRepo.reAuthenticateWithEmailAndPassword(
        currentAdmin.value.email,
        password,
      );

      // Soft delete account
      await _userRepo.updateSingleField(
        {'isDeleted': true},
        userId: currentAdmin.value.userId,
      );

      // Logout
      await _authRepo.logout(
        title: 'Account Deleted',
        message: 'Your account has been deleted successfully',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to delete account: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Build edit profile dialog
  Widget _buildEditProfileDialog() {
    final darkMode = THelperFunctions.isDarkMode(Get.context!);
    final isWeb = THelperFunctions.screenWidth() > 600;

    return Dialog(
      backgroundColor: TAdminColors.getSurfaceColor(darkMode),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isWeb ? 500 : 400,
        ),
        padding: EdgeInsets.all(isWeb ? 32 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TAdminColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Iconsax.user_edit_bold,
                    color: TAdminColors.primary,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: isWeb ? 24 : 20,
                          fontWeight: FontWeight.bold,
                          color: TAdminColors.getOnSurfaceColor(darkMode),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Update your profile information',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              TAdminColors.getOnSurfaceVariantColor(darkMode),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 32),

            // Form fields
            SingleChildScrollView(
              child: Column(
                children: [
                  // Username field
                  Obx(() => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Username',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: TAdminColors.getOnSurfaceColor(darkMode),
                            ),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: editUsernameController,
                            style: TextStyle(
                              color: TAdminColors.getOnSurfaceColor(darkMode),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter username',
                              hintStyle: TextStyle(
                                color: TAdminColors.getOnSurfaceVariantColor(
                                    darkMode),
                              ),
                              prefixIcon: Icon(
                                Iconsax.user_bold,
                                color: TAdminColors.getOnSurfaceVariantColor(
                                    darkMode),
                              ),
                              filled: true,
                              fillColor:
                                  TAdminColors.getSurfaceVariantColor(darkMode),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: usernameError.value != null
                                      ? TAdminColors.error
                                      : TAdminColors.getBorderColor(darkMode),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: usernameError.value != null
                                      ? TAdminColors.error
                                      : TAdminColors.getBorderColor(darkMode),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: usernameError.value != null
                                      ? TAdminColors.error
                                      : TAdminColors.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: (value) => usernameError.value = null,
                          ),
                          if (usernameError.value != null)
                            Padding(
                              padding: EdgeInsets.only(top: 8, left: 12),
                              child: Text(
                                usernameError.value!,
                                style: TextStyle(
                                  color: TAdminColors.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      )),

                  SizedBox(height: 20),

                  // Phone field
                  Obx(() => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phone Number',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: TAdminColors.getOnSurfaceColor(darkMode),
                            ),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: editPhoneController,
                            style: TextStyle(
                              color: TAdminColors.getOnSurfaceColor(darkMode),
                            ),
                            decoration: InputDecoration(
                              hintText: '01XXXXXXXXX',
                              hintStyle: TextStyle(
                                color: TAdminColors.getOnSurfaceVariantColor(
                                    darkMode),
                              ),
                              prefixIcon: Icon(
                                Iconsax.call_bold,
                                color: TAdminColors.getOnSurfaceVariantColor(
                                    darkMode),
                              ),
                              filled: true,
                              fillColor:
                                  TAdminColors.getSurfaceVariantColor(darkMode),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: phoneError.value != null
                                      ? TAdminColors.error
                                      : TAdminColors.getBorderColor(darkMode),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: phoneError.value != null
                                      ? TAdminColors.error
                                      : TAdminColors.getBorderColor(darkMode),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: phoneError.value != null
                                      ? TAdminColors.error
                                      : TAdminColors.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                            onChanged: (value) => phoneError.value = null,
                          ),
                          if (phoneError.value != null)
                            Padding(
                              padding: EdgeInsets.only(top: 8, left: 12),
                              child: Text(
                                phoneError.value!,
                                style: TextStyle(
                                  color: TAdminColors.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      )),
                ],
              ),
            ),

            SizedBox(height: 32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      usernameError.value = null;
                      phoneError.value = null;
                      Get.back();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: isWeb ? 16 : 14),
                      side: BorderSide(
                        color: TAdminColors.getBorderColor(darkMode),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: TAdminColors.getOnSurfaceColor(darkMode),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Obx(() => ElevatedButton(
                        onPressed: isLoading.value ? null : updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TAdminColors.primary,
                          foregroundColor: Colors.white,
                          padding:
                              EdgeInsets.symmetric(vertical: isWeb ? 16 : 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading.value
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build change password dialog
  Widget _buildChangePasswordDialog() {
    final darkMode = THelperFunctions.isDarkMode(Get.context!);
    final isWeb = THelperFunctions.screenWidth() > 600;

    return Dialog(
      backgroundColor: TAdminColors.getSurfaceColor(darkMode),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isWeb ? 500 : 400,
        ),
        padding: EdgeInsets.all(isWeb ? 32 : 24),
        child: Obx(() => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TAdminColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Iconsax.key_bold,
                    color: TAdminColors.primary,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Change Password',
                        style: TextStyle(
                          fontSize: isWeb ? 24 : 20,
                          fontWeight: FontWeight.bold,
                          color: TAdminColors.getOnSurfaceColor(darkMode),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        isCurrentPasswordVerified.value
                            ? 'Enter your new password'
                            : 'Verify your current password',
                        style: TextStyle(
                          fontSize: 14,
                          color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 32),

            // Content
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current password verification
                  if (!isCurrentPasswordVerified.value) ...[
                    Text(
                      'Current Password',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: TAdminColors.getOnSurfaceColor(darkMode),
                      ),
                    ),
                    SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: currentPasswordController,
                          obscureText: !showCurrentPassword.value,
                          style: TextStyle(
                            color: TAdminColors.getOnSurfaceColor(darkMode),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter your current password',
                            hintStyle: TextStyle(
                              color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                            ),
                            prefixIcon: Icon(
                              Iconsax.key_bold,
                              color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                            ),
                            suffixIcon: IconButton(
                              onPressed: () => showCurrentPassword.toggle(),
                              icon: Icon(
                                showCurrentPassword.value
                                    ? Iconsax.eye_bold
                                    : Iconsax.eye_slash_bold,
                                color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                              ),
                            ),
                            filled: true,
                            fillColor: TAdminColors.getSurfaceVariantColor(darkMode),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: currentPasswordError.value != null
                                    ? TAdminColors.error
                                    : TAdminColors.getBorderColor(darkMode),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: currentPasswordError.value != null
                                    ? TAdminColors.error
                                    : TAdminColors.getBorderColor(darkMode),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: currentPasswordError.value != null
                                    ? TAdminColors.error
                                    : TAdminColors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (value) => currentPasswordError.value = null,
                        ),
                        if (currentPasswordError.value != null)
                          Padding(
                            padding: EdgeInsets.only(top: 8, left: 12),
                            child: Text(
                              currentPasswordError.value!,
                              style: TextStyle(
                                color: TAdminColors.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 24),

                    // 按钮改为各占一半空间
                    Row(
                      children: [
                        // 左边的 Cancel 按钮
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              usernameError.value = null;
                              phoneError.value = null;
                              Get.back();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: isWeb ? 16 : 14),
                              side: BorderSide(
                                color: TAdminColors.getBorderColor(darkMode),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: TAdminColors.getOnSurfaceColor(darkMode),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        // 右边的 Verify Password 按钮
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading.value ? null : verifyCurrentPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TAdminColors.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: isWeb ? 16 : 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading.value
                                ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                                : Text(
                              'Verify Password',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // New password field
                    Text(
                      'New Password',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: TAdminColors.getOnSurfaceColor(darkMode),
                      ),
                    ),
                    SizedBox(height: 8),
                    Obx(() => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: newPasswordController,
                          obscureText: !showNewPassword.value,
                          style: TextStyle(
                            color: TAdminColors.getOnSurfaceColor(darkMode),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter new password',
                            hintStyle: TextStyle(
                              color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                            ),
                            prefixIcon: Icon(
                              Iconsax.lock_bold,
                              color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                            ),
                            suffixIcon: IconButton(
                              onPressed: () => showNewPassword.toggle(),
                              icon: Icon(
                                showNewPassword.value
                                    ? Iconsax.eye_bold
                                    : Iconsax.eye_slash_bold,
                                color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                              ),
                            ),
                            filled: true,
                            fillColor: TAdminColors.getSurfaceVariantColor(darkMode),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: newPasswordError.value != null
                                    ? TAdminColors.error
                                    : TAdminColors.getBorderColor(darkMode),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: newPasswordError.value != null
                                    ? TAdminColors.error
                                    : TAdminColors.getBorderColor(darkMode),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: newPasswordError.value != null
                                    ? TAdminColors.error
                                    : TAdminColors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            // 实时验证新密码
                            if (value.isNotEmpty) {
                              newPasswordError.value = TUserProfileValidator.validateNewPassword(value);
                            } else {
                              newPasswordError.value = null;
                            }
                          },
                        ),
                        if (newPasswordError.value != null)
                          Padding(
                            padding: EdgeInsets.only(top: 8, left: 12),
                            child: Text(
                              newPasswordError.value!,
                              style: TextStyle(
                                color: TAdminColors.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    )),

                    SizedBox(height: 20),

// Confirm password field
                    Text(
                      'Confirm New Password',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: TAdminColors.getOnSurfaceColor(darkMode),
                      ),
                    ),
                    SizedBox(height: 8),
                    Obx(() => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: !showConfirmPassword.value,
                          style: TextStyle(
                            color: TAdminColors.getOnSurfaceColor(darkMode),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Confirm new password',
                            hintStyle: TextStyle(
                              color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                            ),
                            prefixIcon: Icon(
                              Iconsax.lock_1_bold,
                              color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                            ),
                            suffixIcon: IconButton(
                              onPressed: () => showConfirmPassword.toggle(),
                              icon: Icon(
                                showConfirmPassword.value
                                    ? Iconsax.eye_bold
                                    : Iconsax.eye_slash_bold,
                                color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                              ),
                            ),
                            filled: true,
                            fillColor: TAdminColors.getSurfaceVariantColor(darkMode),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: confirmPasswordError.value != null
                                    ? TAdminColors.error
                                    : TAdminColors.getBorderColor(darkMode),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: confirmPasswordError.value != null
                                    ? TAdminColors.error
                                    : TAdminColors.getBorderColor(darkMode),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: confirmPasswordError.value != null
                                    ? TAdminColors.error
                                    : TAdminColors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            // 实时验证确认密码
                            if (value.isNotEmpty) {
                              confirmPasswordError.value = TUserProfileValidator.validateConfirmNewPassword(
                                  value,
                                  newPasswordController.text.trim()
                              );
                            } else {
                              confirmPasswordError.value = null;
                            }
                          },
                        ),
                        if (confirmPasswordError.value != null)
                          Padding(
                            padding: EdgeInsets.only(top: 8, left: 12),
                            child: Text(
                              confirmPasswordError.value!,
                              style: TextStyle(
                                color: TAdminColors.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    )),

                    SizedBox(height: 16),

                    // Password requirements
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: TAdminColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: TAdminColors.info.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Iconsax.info_circle_bold,
                                size: 16,
                                color: TAdminColors.info,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Password Requirements:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: TAdminColors.info,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            '• At least 8 characters\n'
                                '• At least one uppercase letter\n'
                                '• At least one lowercase letter\n'
                                '• At least one number',
                            style: TextStyle(
                              fontSize: 11,
                              color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 设置新密码部分也使用左右布局
                    SizedBox(height: 24),
                    Row(
                      children: [
                        // 左边的 Cancel 按钮 - 添加确认逻辑
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              // 如果用户已经验证了当前密码（即进入了新密码设置阶段）
                              if (isCurrentPasswordVerified.value) {
                                // 提示用户是否要丢弃更改
                                final shouldDiscard = await TDialog.keepWriting(
                                  title: 'Discard Changes?',
                                  message: 'Are you sure you want to discard password change?',
                                );

                                if (shouldDiscard) {
                                  // 用户选择丢弃，关闭对话框
                                  usernameError.value = null;
                                  phoneError.value = null;
                                  Get.back();
                                }
                                // 如果用户选择继续编辑，不执行任何操作
                              } else {
                                // 还在验证当前密码阶段，直接关闭
                                usernameError.value = null;
                                phoneError.value = null;
                                Get.back();
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: isWeb ? 16 : 14),
                              side: BorderSide(
                                color: TAdminColors.getBorderColor(darkMode),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: TAdminColors.getOnSurfaceColor(darkMode),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        // 右边的 Save Changes 按钮
                        Expanded(
                          child: Obx(() => ElevatedButton(
                            onPressed: isLoading.value ? null : () {
                              // 在点击时进行最终验证
                              final newPassword = newPasswordController.text.trim();
                              final confirmPassword = confirmPasswordController.text.trim();

                              // 验证新密码
                              final newPasswordValidation = TUserProfileValidator.validateNewPassword(newPassword);
                              newPasswordError.value = newPasswordValidation;

                              // 验证确认密码
                              final confirmPasswordValidation = TUserProfileValidator.validateConfirmNewPassword(
                                  confirmPassword,
                                  newPassword
                              );
                              confirmPasswordError.value = confirmPasswordValidation;

                              // 只有当两个字段都没有错误时才执行更新
                              if (newPasswordError.value == null && confirmPasswordError.value == null) {
                                updatePassword();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TAdminColors.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: isWeb ? 16 : 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading.value
                                ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                                : Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        )),
      ),
    );
  }
}
