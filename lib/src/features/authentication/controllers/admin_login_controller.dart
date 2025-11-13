import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/repositories/user/user_repository.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/network_manager.dart';

class AdminLoginController extends GetxController {
  static AdminLoginController get instance => Get.find();

  // Controllers
  final email = TextEditingController();
  final password = TextEditingController();
  final hidePassword = true.obs;
  final isLoading = false.obs;
  GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  final _userRepository = UserRepository.instance;
  final _authRepository = AuthenticationRepository.instance;

  // Toggle password visibility
  void togglePasswordVisibility() {
    hidePassword.value = !hidePassword.value;
  }

  // Admin Login Method
  Future<void> adminLogin() async {
    try {
      // Start Loading
      isLoading.value = true;

      // Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        isLoading.value = false;
        return;
      }

      // Form Validation
      if (!loginFormKey.currentState!.validate()) {
        isLoading.value = false;
        return;
      }

      final emailAddress = email.text.trim();
      final userPassword = password.text.trim();

      // Check if user exists by email
      final userData = await _userRepository.getUserByEmail(emailAddress);

      if (userData == null) {
        isLoading.value = false;
        TLoaders.errorSnackBar(
          title: TTexts.error,
          message: TTexts.incorrectEmailOrPassword,
        );
        return;
      }

      final userType = userData['userType'] ?? 'user';
      final userId = userData['userId'] ?? '';

      // Check if account is a user account (cannot login from admin website)
      if (userType == 'user') {
        isLoading.value = false;
        TLoaders.errorSnackBar(
          title: TTexts.error,
          message: TTexts.userCannotLoginFromAdmin,
        );
        return;
      }

      // Get login attempts data
      final loginAttempt = userData['loginAttempt'] ?? 5;
      final lastAttemptTime = userData['lastAttemptTime'] ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final timeDifference = currentTime - lastAttemptTime;
      final tenMinutesInMs = 10 * 60 * 1000;

      // Check if 10 minutes have passed since last attempt and reset if needed
      if (timeDifference >= tenMinutesInMs && loginAttempt < 5) {
        await _userRepository.resetLoginAttempts(userId);
      }

      // Get updated login attempt count
      final updatedUserData = await _userRepository.getUserByEmail(emailAddress);
      final updatedLoginAttempt = updatedUserData?['loginAttempt'] ?? 5;

      // Check if account is blocked
      if (updatedLoginAttempt <= 0) {
        final remainingTime = tenMinutesInMs - timeDifference;
        final remainingMinutes = (remainingTime / 60000).ceil();

        isLoading.value = false;
        TLoaders.errorSnackBar(
          title: TTexts.accountBlocked,
          message: '${TTexts.tooManyFailedAttempts} $remainingMinutes ${TTexts.minutes}',
        );
        return;
      }

      // Try to authenticate with Firebase Auth
      UserCredential? userCredential;
      try {
        userCredential = await _authRepository.loginWithEmailAndPassword(
          emailAddress,
          userPassword,
        );
      } on FirebaseAuthException catch (e) {
        // Wrong password - deduct login attempt
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          await _userRepository.decrementLoginAttempt(userId);

          isLoading.value = false;
          TLoaders.errorSnackBar(
            title: TTexts.error,
            message: TTexts.incorrectEmailOrPassword,
          );
          return;
        }

        // Other authentication errors
        isLoading.value = false;
        TLoaders.errorSnackBar(
          title: TTexts.error,
          message: e.message ?? TTexts.commonErrorMessage,
        );
        return;
      }

      // Password is correct - reset login attempts
      await _userRepository.resetLoginAttempts(userId);

      // Check if account is available (only for managers, not admin)
      if (userType != 'admin') {
        final accountAvailable = userData['accountAvailable'] ?? true;
        if (!accountAvailable) {
          isLoading.value = false;
          TLoaders.errorSnackBar(
            title: TTexts.accountDisabled,
            message: TTexts.accountDisabledMessage,
          );
          return;
        }
      }

      // Check email verification
      if (!userCredential.user!.emailVerified) {
        isLoading.value = false;
        TLoaders.errorSnackBar(
          title: TTexts.emailNotVerified,
          message: TTexts.emailNotVerifiedMessage,
        );
        return;
      }

      // All checks passed - redirect
      isLoading.value = false;
      _authRepository.screenRedirect();

    } catch (e) {
      print('Admin Login Error: $e');
      isLoading.value = false;
      TLoaders.errorSnackBar(
        title: TTexts.error,
        message: TTexts.commonErrorMessage,
      );
    }
  }

  @override
  void onClose() {
    email.dispose();
    password.dispose();
    super.onClose();
  }
}