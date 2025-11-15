import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/repositories/user/user_repository.dart';
import '../../../utils/constants/firebase_field_names.dart';
import '../../../utils/constants/text_strings.dart';

class AdminLoginController extends GetxController {
  static AdminLoginController get instance => Get.find();

  // Controllers
  final email = TextEditingController();
  final password = TextEditingController();
  final hidePassword = true.obs;
  final isLoading = false.obs;
  final errorMessage = RxString(''); // 添加错误消息状态
  GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  final _userRepository = UserRepository.instance;
  final _authRepository = AuthenticationRepository.instance;

  // Toggle password visibility
  void togglePasswordVisibility() {
    hidePassword.value = !hidePassword.value;
  }

  // Clear error message
  void clearError() {
    errorMessage.value = '';
  }

  // Admin Login Method
  Future<void> adminLogin() async {
    try {
      // Clear previous errors
      clearError();

      // Start Loading
      isLoading.value = true;

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
        errorMessage.value = TTexts.incorrectEmailOrPassword;
        return;
      }

      final userType = userData['userType'] ?? 'user';
      final userId = userData['userId'] ?? '';

      // Check if account is a user account (cannot login from admin website)
      if (userType == 'user') {
        isLoading.value = false;
        errorMessage.value = TTexts.userCannotLoginFromAdmin;
        return;
      }

      // 检查block状态
      final blockResult = await _checkBlockStatus(userData, emailAddress);
      if (blockResult.$1) {
        isLoading.value = false;
        errorMessage.value = blockResult.$2;
        return;
      }

      // Try to authenticate with Firebase Auth
      UserCredential? userCredential;
      try {
        userCredential = await _authRepository.loginWithEmailAndPassword(
          emailAddress,
          userPassword,
        );
      } catch (e) {
        print('Authentication error: $e');

        // 扣减尝试次数
        await _userRepository.decrementLoginAttempt(userId);

        // 检查扣减后是否被block
        final afterBlockResult = await _checkBlockStatus(null, emailAddress);

        isLoading.value = false;
        errorMessage.value = afterBlockResult.$1 ? afterBlockResult.$2 : e.toString();
        return;
      }

      // Password is correct - reset login attempts
      await _userRepository.resetLoginAttempts(userId);

      // Check if account is available (only for managers, not admin)
      if (userType != 'admin') {
        final accountAvailable = userData['accountAvailable'] ?? true;
        if (!accountAvailable) {
          isLoading.value = false;
          errorMessage.value = TTexts.accountDisabledMessage;
          return;
        }
      }

      // 登录成功后就更新 Firestore 的 isVerify 为 true
      // 因为 reset password 后 Authentication 的 emailVerified 已经是 true
      try {
        await _userRepository.updateSingleField({
          FirebaseFieldNames.isVerify: true,
        });
        print('Successfully updated isVerify to true in Firestore for user: $userId');
      } catch (e) {
        print('Warning: Failed to update isVerify in Firestore: $e');
        // 不阻止登录，只记录警告
      }

      // Check email verification
      // if (!userCredential.user!.emailVerified) {
      //   isLoading.value = false;
      //   errorMessage.value = TTexts.emailNotVerifiedMessage;
      //   return;
      // }

      // All checks passed - redirect
      isLoading.value = false;
      _authRepository.screenRedirect();

    } catch (e) {
      print('Admin Login Error: $e');
      isLoading.value = false;
      errorMessage.value = TTexts.commonErrorMessage;
    }
  }

  // 调用 selfVerifyEmail Cloud Function
  Future<void> _callSelfVerifyEmail() async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('selfVerifyEmail');
      await callable.call();
    } on FirebaseFunctionsException catch (e) {
      print('Firebase Functions error in selfVerifyEmail: ${e.code} - ${e.message}');
      // 不抛出异常，允许继续登录
    } catch (e) {
      print('Error calling selfVerifyEmail: $e');
      // 不抛出异常，允许继续登录
    }
  }

  // 辅助方法：检查block状态，返回 (isBlocked, errorMessage)
  Future<(bool, String)> _checkBlockStatus(
      Map<String, dynamic>? userData,
      String emailAddress
      ) async {
    const tenMinutesInMs = 10 * 60 * 1000;

    // 如果没有传入userData，重新获取
    final data = userData ?? await _userRepository.getUserByEmail(emailAddress);
    if (data == null) {
      return (false, '');
    }

    final loginAttempt = data['loginAttempt'] ?? 5;
    final lastAttemptTime = data['lastAttemptTime'] ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final timeDifference = currentTime - (lastAttemptTime as int);

    // 检查是否需要重置尝试次数
    if (timeDifference >= tenMinutesInMs && loginAttempt < 5) {
      await _userRepository.resetLoginAttempts(data['userId']);
      return (false, '');
    }

    // 检查是否被block
    if (loginAttempt <= 0) {
      final remainingTime = tenMinutesInMs - timeDifference;

      // 修复时间计算：使用总秒数来避免分钟和秒数的不一致
      final totalSeconds = (remainingTime / 1000).ceil();
      final remainingMinutes = (totalSeconds / 60).floor();
      final remainingSeconds = totalSeconds % 60;

      String errorMsg;
      if (remainingMinutes > 0) {
        // 显示格式：XX minutes YY seconds
        errorMsg = '${TTexts.tooManyFailedAttempts} $remainingMinutes ${TTexts.minutes} ${remainingSeconds.toString().padLeft(2, '0')} ${TTexts.seconds}';
      } else {
        // 显示格式：YY seconds
        errorMsg = '${TTexts.tooManyFailedAttempts} ${remainingSeconds.toString().padLeft(2, '0')} ${TTexts.seconds}';
      }

      return (true, errorMsg);
    }

    return (false, '');
  }

  @override
  void onClose() {
    email.dispose();
    password.dispose();
    super.onClose();
  }
}