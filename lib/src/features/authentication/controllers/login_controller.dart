import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/repositories/user/user_repository.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../utils/popups/full_screen_loader.dart';
import '../../personalization/controllers/user_controller.dart';

class LoginController extends GetxController {
  static LoginController get instance => Get.find();

  // TextField Controllers
  final _hidePassword = true.obs;
  final email = TextEditingController();
  final password = TextEditingController();
  final localStorage = GetStorage();
  GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
  final userController = UserController.instance;
  final _userRepository = UserRepository.instance;

  // Getter
  bool get hidePassword => _hidePassword.value;

  @override
  void onInit() {
    super.onInit();
    try {
      email.text = localStorage.read('REMEMBER_ME_EMAIL') ?? '';
      password.text = localStorage.read('REMEMBER_ME_PASSWORD') ?? '';
    } catch (e) {
      print('GetStorage error: $e');
      email.text = '';
      password.text = '';
    }
  }

  // Email and Password Login (Mobile App - User Only)
  Future<void> emailAndPasswordSignIn() async {
    try {
      // Start Loading
      TFullScreenLoader.openLoadingDialog(
        'Logging you in...',
        TImages.loadingAnimation,
      );

      // Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Form Validation
      if (!loginFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      final emailAddress = email.text.trim();
      final userPassword = password.text.trim();

      // Check if user exists
      final userData = await _userRepository.getUserByEmail(emailAddress);

      if (userData == null) {
        TFullScreenLoader.stopLoading();
        TLoaders.errorSnackBar(
          title: TTexts.error,
          message: TTexts.incorrectEmailOrPassword,
        );
        return;
      }

      final userType = userData['userType'] ?? 'user';

      // Check if account is an admin account (cannot login from mobile app)
      if (userType != 'user') {
        TFullScreenLoader.stopLoading();
        TLoaders.errorSnackBar(
          title: TTexts.error,
          message: TTexts.adminCannotLoginFromMobile,
        );
        return;
      }

      // Try to authenticate with Firebase Auth
      UserCredential? userCredential;
      try {
        userCredential = await AuthenticationRepository.instance
            .loginWithEmailAndPassword(emailAddress, userPassword);
      } on FirebaseAuthException catch (e) {
        // Wrong password
        TFullScreenLoader.stopLoading();
        TLoaders.errorSnackBar(
          title: TTexts.error,
          message: TTexts.incorrectEmailOrPassword,
        );
        return;
      }

      // Check if account is available
      final accountAvailable = userData['accountAvailable'] ?? true;
      if (!accountAvailable) {
        TFullScreenLoader.stopLoading();
        TLoaders.errorSnackBar(
          title: TTexts.accountDisabled,
          message: TTexts.accountDisabledMessage,
        );
        return;
      }

      // Check if account is deleted
      final isDeleted = userData['isDeleted'] ?? false;
      if (isDeleted) {
        TFullScreenLoader.stopLoading();
        TLoaders.errorSnackBar(
          title: TTexts.accountDeleted,
          message: TTexts.accountDeletedMessage,
        );
        return;
      }

      // All checks passed - stop loading and redirect
      TFullScreenLoader.stopLoading();

      AuthenticationRepository.instance.screenRedirect();
    } catch (e) {
      print('Login Error: $e');
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(
        title: TTexts.error,
        message: TTexts.commonErrorMessage,
      );
    }
  }

  // Google Sign In Authentication
  Future<void> googleSignIn() async {
    try {
      // Start Loading
      TFullScreenLoader.openLoadingDialog(
        'Logging you in...',
        TImages.loadingAnimation,
      );

      // Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Google Authentication
      final userCredentials = await AuthenticationRepository.instance
          .signInWithGoogle();

      final user = userCredentials?.user;
      final email = user?.email;

      if (user == null || email == null) {
        TFullScreenLoader.stopLoading();
        TLoaders.errorSnackBar(
            title: TTexts.error,
            message: 'Failed to get user info from Google');
        return;
      }

      // --- Firestore user check ---
      final userData = await _userRepository.getUserByEmail(email);

      if (userData != null) {
        // Check account disabled
        if (userData['accountAvailable'] == false) {
          await AuthenticationRepository.instance.logout();
          TFullScreenLoader.stopLoading();
          TLoaders.errorSnackBar(
            title: TTexts.accountDisabled,
            message: TTexts.accountDisabledMessage,
          );
          return;
        }

        // Check account deleted
        if (userData['isDeleted'] == true) {
          await AuthenticationRepository.instance.logout();
          TFullScreenLoader.stopLoading();
          TLoaders.errorSnackBar(
            title: TTexts.accountDeleted,
            message: TTexts.accountDeletedMessage,
          );
          return;
        }
      }

      // Save user record (only if new user)
      await userController.saveUserRecord(userCredentials);

      // Remove Loader
      TFullScreenLoader.stopLoading();

      // Redirect
      AuthenticationRepository.instance.screenRedirect();
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(
        title: TTexts.error,
        message: e.toString(),
      );
    }
  }

  // Facebook Sign In Authentication
  Future<void> facebookSignIn() async {
    try {
      // Start Loading
      TFullScreenLoader.openLoadingDialog(
        'Logging you in...',
        TImages.loadingAnimation,
      );

      // Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Facebook Authentication
      final userCredentials = await AuthenticationRepository.instance
          .signInWithFacebook();

      final user = userCredentials?.user;
      final email = user?.email;

      if (user == null || email == null) {
        TFullScreenLoader.stopLoading();
        TLoaders.errorSnackBar(
            title: TTexts.error,
            message: 'Failed to get user info from Facebook');
        return;
      }

      // --- Firestore user check ---
      final userData = await _userRepository.getUserByEmail(email);

      if (userData != null) {
        // Check account disabled
        if (userData['accountAvailable'] == false) {
          await AuthenticationRepository.instance.logout();
          TFullScreenLoader.stopLoading();
          TLoaders.errorSnackBar(
            title: TTexts.accountDisabled,
            message: TTexts.accountDisabledMessage,
          );
          return;
        }

        // Check account deleted
        if (userData['isDeleted'] == true) {
          await AuthenticationRepository.instance.logout();
          TFullScreenLoader.stopLoading();
          TLoaders.errorSnackBar(
            title: TTexts.accountDeleted,
            message: TTexts.accountDeletedMessage,
          );
          return;
        }
      }

      // Save user record
      await userController.saveUserRecord(userCredentials);

      // Remove Loader
      TFullScreenLoader.stopLoading();

      // Redirect
      AuthenticationRepository.instance.screenRedirect();
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(
        title: TTexts.error,
        message: e.toString(),
      );
    }
  }

  void togglePasswordVisibility() {
    _hidePassword.value = !_hidePassword.value;
  }

  @override
  void onClose() {
    email.dispose();
    password.dispose();
    super.onClose();
  }
}