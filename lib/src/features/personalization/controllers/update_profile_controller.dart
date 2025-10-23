import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/user/user_repository.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../utils/validators/user_profile_validator.dart';
import '../../health_data_entry/controllers/exercise_controller.dart';
import '../../personalization/models/user_profile_model.dart';
import 'user_controller.dart';

class UpdateProfileController extends GetxController {
  static UpdateProfileController get instance => Get.find();

  final userController = UserController.instance;
  final userRepository = UserRepository.instance;

  /// Form keys
  final basicProfileFormKey = GlobalKey<FormState>();
  final healthProfileFormKey = GlobalKey<FormState>();
  final passwordFormKey = GlobalKey<FormState>();
  final goalsFormKey = GlobalKey<FormState>();

  /// Basic Profile Controllers
  final username = TextEditingController();
  final email = TextEditingController();
  final phoneNumber = TextEditingController();

  /// Health Profile Controllers
  final weight = TextEditingController();
  final height = TextEditingController();
  final dietPreference = TextEditingController();
  final allergies = TextEditingController();
  final prescribedFrequency = TextEditingController();
  final sleepDuration = TextEditingController();
  final waterIntake = TextEditingController();

  /// Goals Controllers
  final dailyStepsGoal = TextEditingController();
  final weeklyExerciseTime = TextEditingController();

  /// Observable fields for health profile
  final selectedGender = ''.obs;
  final selectedDateOfBirth = Rx<DateTime?>(null);
  final isTakeMedication = false.obs;
  final selectedStressLevel = ''.obs;

  /// Password Controllers
  final oldPassword = TextEditingController();
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();
  final hideOldPassword = true.obs;
  final hideNewPassword = true.obs;
  final hideConfirmPassword = true.obs;

  /// Loading states
  final isBasicProfileLoading = false.obs;
  final isHealthProfileLoading = false.obs;
  final isPasswordLoading = false.obs;
  final isVerifyingPassword = false.obs;

  /// Password verification
  final isPasswordVerified = false.obs;
  final oldPasswordError = ''.obs;

  // Loading state for goals
  final isGoalsLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    initializeProfileData();
  }

  /// Initialize profile data
  void initializeProfileData() {
    final user = userController.user.value;
    final profile = user.profile;

    // Basic info
    username.text = user.username;
    email.text = user.email;
    phoneNumber.text = user.phoneNumber.isNotEmpty
        ? TUserProfileValidator.convertToDisplayFormat(user.phoneNumber)
        : '';

    // Health info
    selectedGender.value = profile.gender;
    selectedDateOfBirth.value = profile.dateOfBirth.year != 1970 ? profile.dateOfBirth : null;
    weight.text = profile.weight > 0 ? profile.weight.toString() : '';
    height.text = profile.height > 0 ? profile.height.toString() : '';
    dietPreference.text = profile.dietPreference;
    allergies.text = profile.allergies.join(', ');
    isTakeMedication.value = profile.isTakeMedication;
    prescribedFrequency.text = profile.prescribedFrequency > 0 ? profile.prescribedFrequency.toString() : '';
    sleepDuration.text = profile.sleepDuration > 0 ? profile.sleepDuration.toString() : '';
    selectedStressLevel.value = profile.stressLevel;
    waterIntake.text = profile.waterIntake > 0 ? profile.waterIntake.toString() : '';
    dailyStepsGoal.text = profile.dailyStepsGoal > 0 ? profile.dailyStepsGoal.toString() : '7500';
    weeklyExerciseTime.text = profile.weeklyExerciseTime > 0 ? profile.weeklyExerciseTime.toString() : '150';
  }

  /// Update basic profile
  Future<void> updateBasicProfile() async {
    try {
      // Check Internet
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        return;
      }

      // Form Validation
      if (!basicProfileFormKey.currentState!.validate()) {
        return;
      }

      // Start Loading
      isBasicProfileLoading.value = true;

      // Check if there are any changes
      final currentUser = userController.user.value;
      final newUsername = username.text.trim();
      final newPhoneNumber = phoneNumber.text.trim().isNotEmpty
          ? TUserProfileValidator.convertToStorageFormat(phoneNumber.text.trim())
          : '';

      final hasUsernameChanged = newUsername != currentUser.username;
      final hasPhoneNumberChanged = newPhoneNumber != currentUser.phoneNumber;

      if (!hasUsernameChanged && !hasPhoneNumberChanged) {
        isBasicProfileLoading.value = false;
        TLoaders.warningSnackBar(
          title: 'No Changes',
          message: 'No changes were made to your profile.',
        );
        return;
      }

      // Check for username duplication (only if username actually changed)
      if (hasUsernameChanged) {
        final isDuplicate = await userRepository.checkUsernameDuplicate(
          newUsername,
          currentUser.userId,
        );

        if (isDuplicate) {
          isBasicProfileLoading.value = false;
          TLoaders.errorSnackBar(
            title: 'Username Taken',
            message: 'This username is already in use. Please choose another.',
          );
          return;
        }
      }

      // Update user data
      Map<String, dynamic> updates = {};

      if (hasUsernameChanged) {
        updates['username'] = newUsername;
      }

      if (hasPhoneNumberChanged) {
        updates['phoneNumber'] = newPhoneNumber;
      }

      await userRepository.updateSingleField(updates);

      // Update local user model
      userController.user.value = currentUser.copyWith(
        username: newUsername,
        phoneNumber: newPhoneNumber,
      );

      userController.user.refresh();

      // Stop Loading
      isBasicProfileLoading.value = false;

      // Success Message
      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Your profile has been updated successfully.',
      );

      // Go back
      if (Get.context != null) {
        Navigator.of(Get.context!, rootNavigator: true).pop();
      }
    } catch (e) {
      isBasicProfileLoading.value = false;
      TLoaders.errorSnackBar(title: TTexts.error, message: e.toString());
    }
  }

  /// Update health profile
  Future<void> updateHealthProfile() async {
    try {
      // Check Internet
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        return;
      }

      // Form Validation
      if (!healthProfileFormKey.currentState!.validate()) {
        return;
      }

      // Start Loading
      isHealthProfileLoading.value = true;

      // Parse allergies
      List<String> allergyList = allergies.text.trim().isNotEmpty
          ? allergies.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
          : [];

      // Create updated profile
      final updatedProfile = UserProfileModel(
        gender: selectedGender.value,
        dateOfBirth: selectedDateOfBirth.value ?? DateTime.now(),
        weight: double.tryParse(weight.text.trim()) ?? 0,
        height: double.tryParse(height.text.trim()) ?? 0,
        dietPreference: dietPreference.text.trim(),
        allergies: allergyList,
        isTakeMedication: isTakeMedication.value,
        prescribedFrequency: int.tryParse(prescribedFrequency.text.trim()) ?? 0,
        sleepDuration: double.tryParse(sleepDuration.text.trim()) ?? 0,
        stressLevel: selectedStressLevel.value,
        waterIntake: int.tryParse(waterIntake.text.trim()) ?? 0,
        updatedAt: DateTime.now(),
      );

      // Check if there are any changes
      final currentProfile = userController.user.value.profile;

      if (_areProfilesEqual(currentProfile, updatedProfile)) {
        isHealthProfileLoading.value = false;
        TLoaders.warningSnackBar(
          title: 'No Changes',
          message: 'No changes were made to your health profile.',
        );
        return;
      }

      // Update profile in Firebase
      await userRepository.updateUserProfile(
        userController.user.value.userId,
        updatedProfile,
      );

      // Update local user model
      userController.user.value.profile = updatedProfile;
      userController.user.refresh();

      // Stop Loading
      isHealthProfileLoading.value = false;

      // Success Message
      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Your health profile has been updated successfully.',
      );

      // Go back
      if (Get.context != null) {
        Navigator.of(Get.context!, rootNavigator: true).pop();
      }
    } catch (e) {
      isHealthProfileLoading.value = false;
      TLoaders.errorSnackBar(title: TTexts.error, message: e.toString());
    }
  }

  /// Helper method to compare profiles
  bool _areProfilesEqual(UserProfileModel profile1, UserProfileModel profile2) {
    return profile1.gender == profile2.gender &&
        profile1.dateOfBirth.year == profile2.dateOfBirth.year &&
        profile1.dateOfBirth.month == profile2.dateOfBirth.month &&
        profile1.dateOfBirth.day == profile2.dateOfBirth.day &&
        profile1.weight == profile2.weight &&
        profile1.height == profile2.height &&
        profile1.dietPreference == profile2.dietPreference &&
        _areListsEqual(profile1.allergies, profile2.allergies) &&
        profile1.isTakeMedication == profile2.isTakeMedication &&
        profile1.prescribedFrequency == profile2.prescribedFrequency &&
        profile1.sleepDuration == profile2.sleepDuration &&
        profile1.stressLevel == profile2.stressLevel &&
        profile1.waterIntake == profile2.waterIntake;
  }

  /// Helper method to compare lists
  bool _areListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

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

      // Success Message
      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Your password has been changed successfully.',
      );

      // Go back
      Get.back();
    } catch (e) {
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

  Future<void> updateGoals() async {
    try {
      // Check Internet
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        return;
      }

      // Form Validation
      if (!goalsFormKey.currentState!.validate()) {
        return;
      }

      // Start Loading
      isGoalsLoading.value = true;

      // Parse values
      final newDailySteps = int.tryParse(dailyStepsGoal.text.trim()) ?? 7500;
      final newWeeklyExercise = int.tryParse(weeklyExerciseTime.text.trim()) ?? 150;

      // Check if there are any changes
      final currentProfile = userController.user.value.profile;

      if (currentProfile.dailyStepsGoal == newDailySteps &&
          currentProfile.weeklyExerciseTime == newWeeklyExercise) {
        isGoalsLoading.value = false;
        TLoaders.warningSnackBar(
          title: 'No Changes',
          message: 'No changes were made to your goals.',
        );
        return;
      }

      // Update profile fields
      final updatedProfile = currentProfile.copyWith(
        dailyStepsGoal: newDailySteps,
        weeklyExerciseTime: newWeeklyExercise,
        updatedAt: DateTime.now(),
      );

      // Update in Firebase
      await userRepository.updateUserProfile(
        userController.user.value.userId,
        updatedProfile,
      );

      // Update local user model
      userController.user.value.profile = updatedProfile;
      userController.user.refresh();

      // Update ExerciseController if it exists
      try {
        final exerciseController = Get.find<ExerciseController>();
        exerciseController.updateDailyStepsGoal(newDailySteps);
        exerciseController.updateWeeklyExerciseGoal(newWeeklyExercise);
      } catch (e) {
        // ExerciseController not found, skip
      }

      // Stop Loading
      isGoalsLoading.value = false;

      // Success Message
      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Your goals have been updated successfully.',
      );

      // Go back
      Get.back();
    } catch (e) {
      isGoalsLoading.value = false;
      TLoaders.errorSnackBar(title: TTexts.error, message: e.toString());
    }
  }

  @override
  void onClose() {
    username.dispose();
    email.dispose();
    phoneNumber.dispose();
    weight.dispose();
    height.dispose();
    dietPreference.dispose();
    allergies.dispose();
    prescribedFrequency.dispose();
    sleepDuration.dispose();
    waterIntake.dispose();
    oldPassword.dispose();
    newPassword.dispose();
    confirmPassword.dispose();
    dailyStepsGoal.dispose();
    weeklyExerciseTime.dispose();
    super.onClose();
  }
}