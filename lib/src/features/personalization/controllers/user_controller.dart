import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diabetes_risk_prediction_and_health_management_system/src/data/repositories/authentication/authentication_repository.dart';
import 'package:diabetes_risk_prediction_and_health_management_system/src/features/authentication/views/login/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../common/widgets/dialogs/dialog.dart';
import '../../../data/repositories/user/user_repository.dart';
import '../../../utils/constants/firebase_collection_names.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../utils/popups/full_screen_loader.dart';
import '../../authentication/models/user_model.dart';

class UserController extends GetxController {
  static UserController get instance => Get.find();

  final profileLoading = false.obs;

  // final isChecked = false.obs;  // ✅ 自动变成 RxBool
  // Rx<UserModel> user = UserModel.empty().obs;  // ✅ 需要指定类型
  Rx<UserModel> user = UserModel.empty().obs;
  final userRepository = Get.put(UserRepository());

  final userCache = <String, UserModel>{}.obs; // ✅ 缓存用户数据

  @override
  void onInit() {
    super.onInit();
    fetchUserRecord();
  }

  /// Fetch user record
  Future<void> fetchUserRecord() async {
    try {
      profileLoading.value = true;
      final user = await userRepository.fetchUserDetails();
      this.user(user);
    } catch (e) {
      user(UserModel.empty());
    } finally {
      profileLoading.value = false;
    }
  }

  /// Fetch user record by id
  Future<UserModel> fetchUserRecordById(String userId) async {
    try {
      if (userCache.containsKey(userId)) {
        return userCache[userId]!; // ✅ 直接返回缓存数据，避免重复请求
      }
      final user = await userRepository.fetchUserDetailsById(userId);
      userCache[userId] = user;
      return user;
    } catch (e) {
      // Get.snackbar('Error', 'Failed to fetch user data: $e');
      return UserModel.empty();
    }
  }

  /// Save user record from any registration provider
  Future<void> saveUserRecord(UserCredential? userCredentials) async {
    try {
      if (userCredentials != null) {
        final String userId = userCredentials.user!.uid;

        // 先检查 Firebase 里是否已经有该用户
        final DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection(FirebaseCollectionNames.users)
            .doc(userId)
            .get();

        if (userSnapshot.exists) {
          // 用户已存在，不覆盖数据
          print('User already exists in Firebase. Skipping save operation.');
          return;
        }

        // 如果用户不存在，才保存数据
        // Map Data
        final user = UserModel(
          userId: userCredentials.user!.uid,
          username: userCredentials.user!.displayName ?? '',
          userType: 'user',
          email: userCredentials.user!.email ?? '',
          phoneNumber: userCredentials.user!.phoneNumber ?? '',
          profileImg: userCredentials.user!.photoURL ?? '',
          joinDate: DateTime.now(),
          totalScore: 0,
          isVerify: true,
          loginAttempt: 5,
          lastAttemptTime: 0,
          accountAvailable: true,
        );

        // Save user data
        await userRepository.saveUserRecord(user);
      }
    } catch (e) {
      TLoaders.warningSnackBar(
          title: 'Data not saved',
          message:
              'Something went wrong while saving your information. You can re-save your data in your profile.');
    }
  }

  /// Delete Account Warning
  void deleteAccountWarningPopup() {
    TDialog.deleteDialog(
      title: 'Delete Account',
      message:
          'Are you sure you want to delete your account permanently? This action is not reversible and all of your data will be removed permanently.',
      onConfirm: () {
        deleteUserAccount();
      }
    );
  }

  /// Delete User Account
  void deleteUserAccount() async {
    try {
      TFullScreenLoader.openLoadingDialog(
          'Processing', TImages.loadingAnimation);

      /// First re-authenticate user
      final auth = AuthenticationRepository.instance;
      final provider =
          auth.authUser!.providerData.map((e) => e.providerId).first;
      if (provider.isNotEmpty) {
        // Re Verify Auth Email
        if (provider == 'google.com') {
          await auth.signInWithGoogle();
          await auth.deleteAccount();
          TFullScreenLoader.stopLoading();
        } else if (provider == 'password') {
          TFullScreenLoader.stopLoading();
          // Get.to(() => const ReAuthLoginForm);
        }
      }
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.warningSnackBar(title: TTexts.error, message: e.toString());
    }
  }

  /// Re-Authenticate Before Deleting
  Future<void> reAuthenticateEmailAndPasswordUser() async {
    try {
      TFullScreenLoader.openLoadingDialog(
          'Processing', TImages.loadingAnimation);

      // Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // if (!reAuthFormKey.currentState!.validate()) {
      //   TFullScreenLoader.stopLoading();
      //   return;
      // }

      // await AuthenticationRepository.instance.reAuthenticateWithEmailAndPassword(verifyEmail.text.trim(), verifyPassword.text.trim());
      // await AuthenticationRepository.instance.deleteAccount();
      TFullScreenLoader.stopLoading();
      Get.offAll(() => const LoginScreen());
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.warningSnackBar(title: TTexts.error, message: e.toString());
    }
  }
}
