import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../common/widgets/success_screen/success_screen.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/constants/text_strings.dart';

class VerifyEmailController extends GetxController {
  late Timer _timer;

  // Record the time of the last request
  Rx<DateTime?> lastResendTime = Rx<DateTime?>(null);
  static const resendCooldown = Duration(seconds: 30);
  Rx<int> countdown = 0.obs;

  @override
  void onInit() {
    super.onInit();
    sendVerificationEmail();
    setTimerForAutoRedirect();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // Send OR Resend Email Verificaiton
  Future<void> sendVerificationEmail() async {
    try {
      final currentTime = DateTime.now();

      // Check if the cooling time has been reached
      if (lastResendTime.value != null &&
          currentTime.difference(lastResendTime.value!) < resendCooldown) {
        final remainingTime = resendCooldown - currentTime.difference(lastResendTime.value!);
        countdown.value = remainingTime.inSeconds;
        return;
      }

      await AuthenticationRepository.instance.sendEmailVerification();

      // Update the last send time
      lastResendTime.value = currentTime; // start the countdown.

      // Start the countdown
      startCountdown();

      TLoaders.successSnackBar(title: 'Email Sent', message: 'Please check your inbox and verify your email.');
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.error, message: e.toString());
    }
  }

  // Set timer to check if verification completed then redirect
  void setTimerForAutoRedirect() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user?.emailVerified ?? false) {
        timer.cancel();
        Get.off(() =>
            SuccessScreen(
              image: TImages.verifiedSuccess,
              title: TTexts.yourAccountCreatedTitle,
              subTitle: TTexts.yourAccountCreatedSubTitle,
              onPressed: () => AuthenticationRepository.instance.screenRedirect(),
            ),
        );
      }
    });
  }

  // Manually check if verification completed then redirect
  Future<void> manuallyCheckEmailVerificationStatus() async {
    await FirebaseAuth.instance.currentUser?.reload();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.emailVerified) {
      Get.off(() =>
          SuccessScreen(
            image: TImages.verifiedSuccess,
            title: TTexts.yourAccountCreatedTitle,
            subTitle: TTexts.yourAccountCreatedSubTitle,
            onPressed: () => AuthenticationRepository.instance.screenRedirect(),
          ),
      );
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