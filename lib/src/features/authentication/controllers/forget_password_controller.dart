import 'dart:async';

import 'package:diabetes_risk_prediction_and_health_management_system/src/features/authentication/views/forget_password/forget_password_mail/reset_password.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../utils/popups/full_screen_loader.dart';

class ForgetPasswordController extends GetxController {
  static ForgetPasswordController get instance => Get.find();

  // Record the time of the last request
  Rx<DateTime?> lastResendTime = Rx<DateTime?>(null);
  static const resendCooldown = Duration(seconds: 30);
  Rx<int> countdown = 0.obs;

  final email = TextEditingController();
  GlobalKey<FormState> forgetPasswordFormKey = GlobalKey<FormState>();

  /// Send Reset Password Email
  sendPasswordResetEmail() async {
    try {
      // Start Loading
      TFullScreenLoader.openLoadingDialog('Processing your request...', TImages.loadingAnimation);

      // Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Form Validation
      if (!forgetPasswordFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Send Email to Reset Password
      await AuthenticationRepository.instance.sendPasswordResetLink(email.text.trim());

      final currentTime = DateTime.now();

      // Update the last send time
      lastResendTime.value = currentTime;

      // Start the countdown
      startCountdown();

      // Remove Loader
      TFullScreenLoader.stopLoading();

      // Show Success Screen
      TLoaders.successSnackBar(title: 'EMail Sent'.tr, message: 'Email link sent to reset your password.'.tr);

      // Redirect
      Get.to(() => ResetPasswordScreen(email: email.text.trim(),));

    } catch (e) {
      // Remove Loader
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: TTexts.error, message: e.toString(),);
    }
  }

  resendPasswordResetEmail(String email) async {
    try {
      final currentTime = DateTime.now();

      // Check if the cooling time has been reached
      if (lastResendTime.value != null &&
          currentTime.difference(lastResendTime.value!) < resendCooldown) {
        final remainingTime = resendCooldown - currentTime.difference(lastResendTime.value!);
        countdown.value = remainingTime.inSeconds;
        return;
      }

      // Start Loading
      TFullScreenLoader.openLoadingDialog('Processing your request...', TImages.loadingAnimation);

      // Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Send Email to Reset Password
      await AuthenticationRepository.instance.sendPasswordResetLink(email.trim());

      // Update the last send time
      lastResendTime.value = currentTime;

      // Start the countdown
      startCountdown();

      // Remove Loader
      TFullScreenLoader.stopLoading();

      // Show Success Screen
      TLoaders.successSnackBar(title: 'Email Sent'.tr, message: 'Email link sent to reset your password.'.tr);

    } catch (e) {
      // Remove Loader
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: TTexts.error, message: e.toString(),);
    }
  }

  // Start the countdown
  startCountdown() {
    countdown.value = resendCooldown.inSeconds;

    // Countdown to every second update
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (countdown.value > 0) {
        countdown.value--;
      } else {
        timer.cancel(); // Stop the countdown
      }
    });
  }
}
