import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../utils/popups/full_screen_loader.dart';
import '../../personalization/controllers/user_controller.dart';

class LoginController extends GetxController {
  static LoginController get instance => Get.find();

  // TextField Controllers to get data from TextFields
  final _rememberMe = false.obs;
  final _hidePassword = true.obs;
  final email = TextEditingController();
  final password = TextEditingController();
  final localStorage = GetStorage();
  GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
  final userController = Get.put(UserController());

  // Getter
  bool get hidePassword => _hidePassword.value;
  bool get rememberMe => _rememberMe.value;

  @override
  void onInit() {
    super.onInit();
    try {
      email.text = localStorage.read('REMEMBER_ME_EMAIL') ?? '';
      password.text = localStorage.read('REMEMBER_ME_PASSWORD') ?? '';
    } catch (e) {
      print('GetStorage error on web: $e');
      // Set default values if storage fails
      email.text = '';
      password.text = '';
    }
  }

  // Email and Password Login
  Future<void> emailAndPasswordSignIn() async {
    try {
      // Start Loading
      // TFullScreenLoader.openLoadingDialog('Logging you in...', TImages.loadingAnimation);

      // Check Internet Connectivity
      // final isConnected = await NetworkManager.instance.isConnected();
      // if (!isConnected) {
      //   // Remove loader
      //   TFullScreenLoader.stopLoading();
      //   return;
      // }

      // Form Validation
      if (!loginFormKey.currentState!.validate()) {
        // Remove loader
        // TFullScreenLoader.stopLoading();
        return;
      }

      // Save data if Remember Me is selected
      // if (_rememberMe.value) {
      //   localStorage.write('REMEMBER_ME_EMAIL', email.text.trim());
      //   localStorage.write('REMEMBER_ME_PASSWORD', password.text.trim());
      // }

      // Login user using Email & Password Authentication
      final userCredentials = await AuthenticationRepository.instance.loginWithEmailAndPassword(email.text.trim(), password.text.trim());

      // Remove Loader
      // TFullScreenLoader.stopLoading();

      // Redirect
      AuthenticationRepository.instance.screenRedirect();
    } catch (e) {
      print('Error: $e');
      // Remove loader
      TFullScreenLoader.stopLoading();

      // Show some generic error to the user
      TLoaders.errorSnackBar(title: TTexts.error, message: e.toString());
    }
  }

  // Google Sign In Authentication
  Future<void> googleSignIn() async {
    try {
      // Start Loading
      TFullScreenLoader.openLoadingDialog('Logging you in...', TImages.loadingAnimation);

      // Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        // Remove loader
        TFullScreenLoader.stopLoading();
        return;
      }

      // Google Authentication
      final userCredentials = await AuthenticationRepository.instance.signInWithGoogle();

      // Save user record
      await userController.saveUserRecord(userCredentials);

      // Remove Loader
      TFullScreenLoader.stopLoading();

      // Redirect
      AuthenticationRepository.instance.screenRedirect();
    } catch (e) {
      // Remove Loader
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: TTexts.error, message: e.toString(),);
    }
  }

  // Facebook Sign In Authentication
  Future<void> facebookSignIn() async {
    try {
      // Start Loading
      TFullScreenLoader.openLoadingDialog('Logging you in...', TImages.loadingAnimation);

      // Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        // Remove loader
        TFullScreenLoader.stopLoading();
        return;
      }

      // Facebook Authentication
      final userCredentials = await AuthenticationRepository.instance.signInWithFacebook();

      // Save user record
      await userController.saveUserRecord(userCredentials);

      // Remove Loader
      TFullScreenLoader.stopLoading();

      // Redirect
      AuthenticationRepository.instance.screenRedirect();
      // Get.offAll(() => Homepage());
    } catch (e) {
      // Remove Loader
      TFullScreenLoader.stopLoading();

      TLoaders.errorSnackBar(title: TTexts.error, message: e.toString(),);
    }

    // try {
    //   // isFacebookLoading.value = true;
    //   final auth = AuthenticationRepository.instance;
    //   await auth.signInWithFacebook();
    //   // isFacebookLoading.value = false;
    //   // auth.setInitialScreen(auth.firebaseUser);
    //   // 直接登录，不用验证邮箱
    //   Get.offAll(() => Homepage());
    // } catch (e) {
    //   // isFacebookLoading.value = false;
    //
    //   // 处理其他类型的错误
    //   TLoaders.errorSnackBar(
    //     title: TTexts.error,
    //     message: e.toString(),
    //   );
    // }
  }

  void togglePasswordVisibility() {
    _hidePassword.value = !_hidePassword.value;
  }

  void toggleRememberMe() {
    _rememberMe.value = !_rememberMe.value;
  }
}