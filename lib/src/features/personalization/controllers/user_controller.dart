import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diabetes_risk_prediction_and_health_management_system/src/data/repositories/authentication/authentication_repository.dart';
import 'package:diabetes_risk_prediction_and_health_management_system/src/features/authentication/views/login/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../common/loaders/loaders.dart';
import '../../../common/widgets/dialogs/dialog.dart';
import '../../../data/repositories/user/user_repository.dart';
import '../../../utils/constants/firebase_collection_names.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/image_helper.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../utils/popups/full_screen_loader.dart';
import '../../authentication/models/user_model.dart';

class UserController extends GetxController {
  static UserController get instance => Get.find();

  final profileLoading = false.obs;

  // final isChecked = false.obs;
  // Rx<UserModel> user = UserModel.empty().obs;
  Rx<UserModel> user = UserModel.empty().obs;
  final userRepository = Get.put(UserRepository());

  final userCache = <String, UserModel>{}.obs;

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

  /// Upload user profile picture with proper validation and compression
  Future<void> uploadUserProfilePicture() async {
    try {
      final imageFile = await ImageHelper.pickImage();
      if (imageFile == null) {
        // User cancelled image selection
        return;
      }

      // Check Internet connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TLoaders.errorSnackBar(
          title: 'No Internet Connection',
          message: 'Please check your internet connection and try again.',
        );
        return;
      }

      // Validate file type
      if (!ImageHelper.isImageFile(imageFile.path)) {
        TLoaders.errorSnackBar(
          title: 'Invalid File Type',
          message: 'Please select a valid image file (JPG, JPEG, PNG, GIF, BMP, or WEBP).',
        );
        return;
      }

      // Check original file size
      final originalSizeFormatted = ImageHelper.formatFileSize(imageFile.lengthSync());

      if (!ImageHelper.isImageSizeValid(imageFile)) {
        TLoaders.errorSnackBar(
          title: 'File Too Large',
          message: 'Image size ($originalSizeFormatted) exceeds 5MB limit. Please choose a smaller image.',
        );
        return;
      }

      // Compress image to WebP format for better performance
      final compressedImage = await ImageHelper.compressImageToWebP(imageFile);
      if (compressedImage == null) {
        TLoaders.errorSnackBar(
          title: 'Image Processing Failed',
          message: 'Failed to compress image. Please try with a different image.',
        );
        return;
      }

      // Check compressed file size
      final compressedSizeFormatted = ImageHelper.formatFileSize(compressedImage.lengthSync());

      if (!ImageHelper.isImageSizeValid(compressedImage)) {
        TLoaders.errorSnackBar(
          title: 'Image Still Too Large',
          message: 'Compressed image ($compressedSizeFormatted) is still too large. Please choose a smaller image.',
        );
        return;
      }

      // Upload compressed image to Firebase Storage
      final imageUrl = await userRepository.uploadImage(
        'profile/images',
        XFile(compressedImage.path),
      );

      if (imageUrl.isEmpty) {
        TLoaders.errorSnackBar(
          title: 'Upload Failed',
          message: 'Failed to upload image to server. Please try again.',
        );
        return;
      }

      // Update user image record in database
      Map<String, dynamic> json = {'profileImg': imageUrl};
      await userRepository.updateSingleField(json);

      // Update local user model
      user.value.profileImg = imageUrl;
      user.refresh();

      // Show success message
      TLoaders.successSnackBar(
        title: 'Profile Updated!',
        message: 'Your profile picture has been updated successfully.',
      );

    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Upload Failed',
        message: 'An unexpected error occurred: ${e.toString()}',
      );
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
