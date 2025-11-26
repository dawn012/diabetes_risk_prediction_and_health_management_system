import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:image_picker/image_picker.dart';

import '../../../common/loaders/loaders.dart';
import '../../../common/widgets/dialogs/account_status_dialog.dart';
import '../../../common/widgets/dialogs/delete_account_dialog.dart';
import '../../../common/widgets/dialogs/dialog.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/repositories/notification/notification_repository.dart';
import '../../../data/repositories/user/delete_account_request_repository.dart';
import '../../../data/repositories/user/user_repository.dart';
import '../../../utils/constants/admin_colors.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../../../utils/helpers/web_image_helper.dart';
import '../../../utils/validators/user_profile_validator.dart';
import '../../authentication/models/admin_model.dart';
import '../../notification/models/notification_model.dart';
import '../../personalization/controllers/user_controller.dart';
import '../models/delete_account_request_model.dart';

class AdminProfileController extends GetxController {
  final _authRepo = AuthenticationRepository.instance;
  final _userRepo = UserRepository.instance;
  final _notificationRepo = NotificationRepository.instance;
  final _deleteRequestRepo = Get.put(DeleteAccountRequestRepository());

  // Observable admin data
  final Rx<AdminModel> currentAdmin = AdminModel.empty().obs;
  final RxBool isLoading = false.obs;
  final hasPendingDeleteRequest = false.obs;
  final isCheckingDeleteRequest = false.obs;

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

  // Add stream subscription for delete request status
  StreamSubscription<List<DeleteAccountRequestModel>>? _deleteRequestSubscription;

  @override
  void onInit() {
    super.onInit();
    loadAdminData();
    _checkPendingDeleteRequest();
    _startDeleteRequestListener();
  }

  @override
  void onClose() {
    editUsernameController.dispose();
    editPhoneController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    _deleteRequestSubscription?.cancel();
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

      // 在数据加载完成后立即检查 pending 状态
      await _checkPendingDeleteRequest();

      // 然后启动监听器
      _startDeleteRequestListener();

    } catch (e) {
      TLoaders.errorSnackBar(
          title: 'Error',
          message: 'Failed to load profile data: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// Check if there's a pending delete request
  Future<void> _checkPendingDeleteRequest() async {
    try {
      isCheckingDeleteRequest.value = true;
      final userId = currentAdmin.value.userId;

      if (userId.isEmpty) return;

      final hasPending = await _deleteRequestRepo.hasPendingRequest(userId);

      hasPendingDeleteRequest.value = hasPending;
    } catch (e) {
      print('Error checking pending delete request: $e');
    } finally {
      isCheckingDeleteRequest.value = false;
    }
  }

  /// Start listening to delete request responses
  void _startDeleteRequestListener() {
    final userId = currentAdmin.value.userId;
    if (userId.isEmpty) return;

    _deleteRequestSubscription = _deleteRequestRepo
        .streamManagerRequests(userId)
        .listen((requests) {
      // Check for pending requests (non-expired)
      final pendingRequests = requests.where((request) =>
      request.status == RequestStatus.pending && !request.isExpired
      );

      hasPendingDeleteRequest.value = pendingRequests.isNotEmpty;

      // Check for approved request
      final approvedRequest = requests.firstWhereOrNull((request) =>
      request.status == RequestStatus.approved &&
          request.respondedAt != null &&
          // Check if this is a recent approval (within last 5 minutes)
          request.respondedAt!.isAfter(DateTime.now().subtract(Duration(minutes: 5)))
      );

      if (approvedRequest != null) {
        _handleDeleteRequestApproved(approvedRequest);
      }
    });
  }

  /// Handle approved delete request
  void _handleDeleteRequestApproved(DeleteAccountRequestModel request) {
    // Cancel subscription to prevent multiple triggers
    _deleteRequestSubscription?.cancel();

    // Show deleted dialog and logout
    AccountStatusDialog.showDeleted(
      onConfirm: () async {
        await AuthenticationRepository.instance.logout(showSuccessMessage: false);
      },
      customMessage: request.responseMessage?.isNotEmpty == true
          ? 'Your account deletion request has been approved.\n\n'
          'Admin message: ${request.responseMessage}'
          : null,
    );
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
      await AuthenticationRepository.instance.logout(
          title: 'Password Changed',
          message: 'Your password has been changed successfully. For your security, you have been logged out. Please log in again using your new password.'
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to update password: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Send delete account request
  Future<void> sendDeleteAccountRequest() async {
    try {
      isLoading.value = true;

      final admin = currentAdmin.value;

      // Create delete account request using the new repository
      final requestId = await _deleteRequestRepo.createRequest(
        managerId: admin.userId,
        managerUsername: admin.username,
        managerEmail: admin.email,
      );

      hasPendingDeleteRequest.value = true;

      TLoaders.successSnackBar(
        title: 'Request Sent',
        message: 'Your account deletion request has been sent to administrators. '
            'You will be notified once they review your request.',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to send delete request: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete account (for managers only)
  Future<void> deleteAccount() async {
    try {
      // Check if already has pending request
      if (hasPendingDeleteRequest.value) {
        TLoaders.warningSnackBar(
          title: 'Pending Request',
          message: 'You already have a pending delete account request. '
              'Please wait for administrator response.',
        );
        return;
      }

      final confirmed = await DeleteAccountDialog.show(
        onConfirm: () async {
          sendDeleteAccountRequest();
        },
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to delete account: ${e.toString()}',
      );
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

  /// Build change password dialog - Implementation remains the same as your original
  Widget _buildChangePasswordDialog() {
    // Keep your existing implementation
    return Container(); // Placeholder - use your existing code
  }
}