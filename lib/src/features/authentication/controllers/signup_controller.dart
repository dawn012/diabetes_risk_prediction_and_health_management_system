import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/repositories/user/user_repository.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../utils/popups/full_screen_loader.dart';
import '../models/user_model.dart';
import '../views/signup/verify_email.dart';

class SignUpController extends GetxController {
  static SignUpController get instance => Get.find();

  // TextField Controllers to get data from TextFields
  final username = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();

  final _hidePassword = true.obs;
  final _hideConfirmPassword = true.obs;
  final _privacyPolicy = false.obs;

  final userRepo = Get.put(UserRepository());
  GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();

  // Getter
  bool get hidePassword => _hidePassword.value;
  bool get hideConfirmPassword => _hideConfirmPassword.value;
  bool get privacyPolicy => _privacyPolicy.value;

  // Setter
  // set showAgreementMessage(bool value) => _showAgreementMessage.value = value;

  // As in the AuthenticationRepository we are calling _setScreen() method
  // so, whenever there is change in the user state(). screen will be updated.
  // Therefore, when new user is authenticated, AuthenticationRepository() detects
  // the change and call _setScreen() to switch screens

  // Register New User using Email and Password
  Future<void> createUser(UserModel user) async {
      // 否则继续创建账户
      // await userRepo.saveUserRecord(user);
      // AuthenticationRepository.instance
      //     .loginWithEmailAndPassword(user.email, user.password);
      // Get.offAll(Homepage());

    // try {
    //   isLoading.value = true;
    //   if (!signupFormKey.currentState!.validate()) {
    //     isLoading.value = false;
    //     return;
    //   }
    //
    //   // Get User and Pass it to Controller
    //   // final user = UserModel {
    //   //   email: email.text.trim(),
    //   //   password: password.text.trim(),
    //   //   fullName: fullname.text.trim(),
    //   // }
    //
    //   // Authenticate User First
    //   // final auth = AuthenticationRepository.instance;
    //   // await auth.createUserWithEmailAndPassword(user.email, user.password);
    //   // await UserRepository.instance.createUser(user);
    //   // auth.setInitialScreen(auth.firebaseUser);
    //
    // } catch (e) {
    //   isLoading.value = false;
    //   Get.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 5));
    // }
  }

  // Call this Function from Design & it will do the rest
  void signup() async {
    try {
      // Start Loading
      TFullScreenLoader.openLoadingDialog(
          'We are processing your information...', TImages.loadingAnimation);

      // Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        // Remove loader
        TFullScreenLoader.stopLoading();
        return;
      }

      // Form Validation
      if (!signupFormKey.currentState!.validate()) {
        // Remove loader
        TFullScreenLoader.stopLoading();
        return;
      }

      // Privacy Policy Check
      if (!_privacyPolicy.value) {
        TLoaders.warningSnackBar(
            title: 'Accept, Privacy Policy',
            message: 'In order to create account, you must have to read and accept the privacy policy & terms of use');

        // Remove loader
        TFullScreenLoader.stopLoading();
        return;
      }

      // Register user in the Firebase Authentication & Save user data in the Firebase
      final userCredential = await AuthenticationRepository.instance.createUserWithEmailAndPassword(email.text.trim(), password.text.trim());

      // Save authenticated user data in the Firebase Firestore
      final newUser = UserModel(
        id: userCredential.user!.uid,
        username: username.text.trim(),
        email: email.text.trim(),
        phoneNumber: '',
        profilePicture: '',
      );

      userRepo.saveUserRecord(newUser);

      // Remove loader
      TFullScreenLoader.stopLoading();

      // Show Success Message
      TLoaders.successSnackBar(title: TTexts.congratulations, message: TTexts.successfulCreateAccount);

      // Move to Verify Email Screen
      Get.to(() => VerifyEmailScreen(email: email.text.trim(),));

    } catch (e) {
      // Remove loader
      TFullScreenLoader.stopLoading();
      // Show some generic error to the user
      TLoaders.errorSnackBar(title: TTexts.error, message: e.toString());
    }
  }

  // Get phoneNo from user (Screen) and pass it to Auth Repository for Firebase Authentication
  void phoneAuthentication(String phoneNo) {
    AuthenticationRepository.instance.phoneAuthentication(phoneNo);
  }

  void togglePasswordVisibility() {
    _hidePassword.value = !_hidePassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    _hideConfirmPassword.value = !_hideConfirmPassword.value;
  }

  void toggleTermsAndConditionsAgreement() {
    _privacyPolicy.value = !_privacyPolicy.value;
  }
}
