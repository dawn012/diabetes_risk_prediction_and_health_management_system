import 'dart:async';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../navigation_menu.dart';
import '../../../common/loaders/loaders.dart';
import '../../../common/widgets/dialogs/account_status_dialog.dart';
import '../../../features/admin/views/admin_dashboard/admin_dashboard_screen.dart';
import '../../../features/authentication/controllers/login_controller.dart';
import '../../../features/authentication/views/login/admin_login_screen.dart';
import '../../../features/authentication/views/login/login_screen.dart';
import '../../../features/authentication/views/onboarding/onboarding.dart';
import '../../../features/authentication/views/signup/verify_email.dart';
import '../../../features/personalization/views/profile/complete_profile_screen.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/exceptions/firebase_auth_exceptions.dart';
import '../../../utils/exceptions/firebase_exceptions.dart';
import '../../../utils/exceptions/format_exceptions.dart';
import '../../../utils/exceptions/platform_exceptions.dart';
import '../user/user_repository.dart';

class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  /// Variables
  final deviceStorage = GetStorage();
  final _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Get Authenticated User Data
  User? get authUser => _auth.currentUser;

  final userRole = Rx<String>('user');
  bool get isAdminUser => userRole.value == 'admin';
  bool get isRegularUser => userRole.value == 'user';

  // 用于存储 Firebase 发送的验证码会话 ID
  var verificationId = ''.obs;

  // Stream subscription for account status
  StreamSubscription<bool>? _accountStatusSubscription;
  StreamSubscription<bool>? _deleteStatusSubscription;

  @override
  void onReady() {
    FlutterNativeSplash.remove();
    screenRedirect();

    if (authUser != null) {
      getUserRole();
      // Note: Account status listener will be started after successful screenRedirect
    }
  }

  @override
  void onClose() {
    _accountStatusSubscription?.cancel();
    _deleteStatusSubscription?.cancel();
    super.onClose();
  }

  /// Listen to account status changes (ban detection)
  void _startAccountStatusListener() {
    final userId = authUser?.uid;
    if (userId == null) return;

    _accountStatusSubscription = UserRepository.instance
        .streamUserDetailsById(userId)
        .map((user) => user.accountAvailable)
        .distinct() // Only emit when value changes
        .listen((isAccountAvailable) {
      if (!isAccountAvailable) {
        // Account has been banned
        _handleAccountBanned();
      }
    });

    // Listen to delete status (for managers only)
    _deleteStatusSubscription = UserRepository.instance
        .streamUserDetailsById(userId)
        .map((user) => user.isDeleted)
        .distinct()
        .listen((isDeleted) {
      if (isDeleted) {
        _handleAccountDeleted();
      }
    });
  }

  /// Handle account banned scenario
  void _handleAccountBanned() {
    // Cancel the subscription to prevent multiple triggers
    _accountStatusSubscription?.cancel();

    // Show banned dialog and logout
    AccountStatusDialog.showBanned(
      onConfirm: () async {
        await logout(showSuccessMessage: false);
      },
    );
  }

  /// Handle account deleted scenario (for managers)
  void _handleAccountDeleted() {
    _accountStatusSubscription?.cancel();
    _deleteStatusSubscription?.cancel();

    AccountStatusDialog.showDeleted(
      onConfirm: () async {
        await logout(showSuccessMessage: false);
      },
    );
  }

  Future<void> screenRedirect() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Check if account is banned before proceeding
      final isAccountAvailable = await _checkAccountAvailability(user.uid);
      if (!isAccountAvailable) {
        // Account is banned, logout immediately
        await logout();
        return;
      }

      // Check if account is deleted (for managers)
      final isDeleted = await _checkDeleteStatus(user.uid);
      if (isDeleted) {
        await logout();
        return;
      }

      final role = await getUserRole();

      print("Is verified: ${user.emailVerified}");
      print("Role: $role");

      // If the user is logged in
      if (user.emailVerified) {
        // 只有普通用户需要检查健康档案
        if (role == 'user') {
          // Check if user has completed basic profile information
          final hasCompletedProfile = await checkProfileCompletion();

          if (!hasCompletedProfile) {
            // Redirect to complete profile screen
            Get.offAll(() => const CompleteProfileScreen());
            return;
          }
        }

        // 更新用户最后活跃时间
        await UserRepository.instance.updateLastActive(user.uid);

        // If the user's email is verified and (如果是用户则档案已完成)，navigate based on role
        if (role == 'admin' || role.contains('manager')) {
          Get.offAll(() => AdminDashboardScreen());
        } else {
          Get.offAll(() => NavigationMenu());
        }

        // Start monitoring after successful redirect
        _startAccountStatusListener();
      } else {
        // 对于所有用户，如果邮箱未验证，都显示错误或去验证页面
        // 对于 Web (Admin/Manager)，保持在登录页显示错误
        if (kIsWeb) {
          // 保持在 AdminLoginScreen，错误消息已经在 controller 中显示
          // 不需要额外跳转
        } else {
          // If the user's email is not verified, navigate to the MainVerification
          Get.offAll(() => VerifyEmailScreen());
        }
      }
    } else {
      // Local Storage
      deviceStorage.writeIfNull('IsFirstTime', true);

      // Check if it's the first time launching the app
      if (kIsWeb) {
        // 🌐 Web 平台：直接去登录页（Admin Login Screen）
        Get.offAll(() => const AdminLoginScreen());
      } else {
        // 📱 移动端：检查是否是第一次启动
        deviceStorage.read('IsFirstTime') != true
            ? Get.offAll(() => const LoginScreen())
            : Get.offAll(() => const OnBoardingScreen());
      }
    }
  }

  /// Check if account is available (not banned)
  Future<bool> _checkAccountAvailability(String userId) async {
    try {
      final user = await UserRepository.instance.fetchUserDetailsById(userId);
      return user.accountAvailable;
    } catch (e) {
      print('Error checking account availability: $e');
      return true; // Default to true if error occurs
    }
  }

  /// Check if account is deleted
  Future<bool> _checkDeleteStatus(String userId) async {
    try {
      final user = await UserRepository.instance.fetchUserDetailsById(userId);
      return user.isDeleted;
    } catch (e) {
      print('Error checking delete status: $e');
      return false;
    }
  }

  // Add this new method to check if user has completed basic profile
  Future<bool> checkProfileCompletion() async {
    try {
      final user = authUser;
      if (user == null) return false;

      // Fetch user data from Firestore
      final userDoc = await UserRepository.instance.fetchUserDetails();

      // Check if gender, dateOfBirth, and height are set
      final profile = userDoc.profile;

      // Check if gender is set (not empty)
      final hasGender = profile.gender.isNotEmpty;

      // Check if date of birth is set (not the default 0 timestamp)
      final hasDateOfBirth = profile.dateOfBirth.millisecondsSinceEpoch != 0;

      // Check if height is set (greater than 0)
      final hasHeight = profile.height > 0;

      print("Has Gender: $hasGender, Has DOB: $hasDateOfBirth, Has Height: $hasHeight");

      // Return true only if all three are set
      return hasGender && hasDateOfBirth && hasHeight;
    } catch (e) {
      print('Error checking profile completion: $e');
      return false;
    }
  }

  /* -- Email's Password Sign-In -- */
  // Register
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  // Login
  Future<UserCredential> loginWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  // Verification
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  // Set password for manager
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Re-Authenticate User
  Future<void> reAuthenticateWithEmailAndPassword(String email, String password) async {
    try {
      // Create a credential
      AuthCredential credential = EmailAuthProvider.credential(email: email, password: password);

      // ReAuthenticate
      await _auth.currentUser!.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /* -- Federated Identity & Social Sign-In -- */
  // Google Authentication
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      // Allow the user to select the gmail they want to sign in
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Once signed in, return the userCredential
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      return null;
    }
  }

  // Facebook Authentication
  Future<UserCredential?> signInWithFacebook() async {
    try {
      // 检查是否已有登录的 Facebook 账号
      final AccessToken? accessToken = await FacebookAuth.instance.accessToken;

      if (accessToken != null) {
        // 直接用 accessToken 登录 Firebase
        final OAuthCredential credential = FacebookAuthProvider.credential(accessToken.tokenString);
        return await FirebaseAuth.instance.signInWithCredential(credential);
      }

      // 如果没有登录，触发 Facebook 登录
      final LoginResult loginResult = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (loginResult.status == LoginStatus.success) {
        final OAuthCredential facebookAuthCredential =
        FacebookAuthProvider.credential(loginResult.accessToken!.tokenString);
        return await FirebaseAuth.instance.signInWithCredential(facebookAuthCredential);
      } else if (loginResult.status == LoginStatus.cancelled) {
        print('User cancelled the login process');
        return null;
      } else {
        throw Exception('Facebook login failed: ${loginResult.message}');
      }
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      return null;
    }
  }

  /* -- Forget Password -- */
  // Reset Password Via Email
  Future<void> sendPasswordResetLink(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  Future<void> phoneAuthentication(String phoneNo) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNo,
      // 当 Firebase 自动检测到短信验证码（如某些设备支持自动读取短信验证码）时，直接完成验证并返回一个 PhoneAuthCredential
      verificationCompleted: (credential) async {
        await _auth.signInWithCredential(credential);
      },
      // verificationId: Firebase 为验证码生成的唯一会话 ID，用于后续验证用户输入的验证码。
      // resendToken: 用于请求重新发送验证码（在本例中未使用）。
      codeSent: (verificationId, resendToken) {
        this.verificationId.value = verificationId;
        print("Verification ID: $verificationId");
      },
      codeAutoRetrievalTimeout: (verificationId) {
        this.verificationId.value = verificationId;
      },
      verificationFailed: (e) {
        print(e.code);
      },
    );
  }

  Future<bool> verifyOTP(String otp) async {
    var credentials = await _auth.signInWithCredential(
        PhoneAuthProvider.credential(
            verificationId: verificationId.value, smsCode: otp));
    // credentials.user:
    // 如果验证成功，会包含已登录用户的详细信息（FirebaseUser）。
    // 如果验证失败，credentials.user 会为 null。
    return credentials.user != null ? true : false;
  }

  /// Update user password
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    try {
      final user = authUser;
      if (user == null) throw 'No user is currently signed in';

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Create manager account with email (sends verification email)
  /// Returns the created user ID
  Future<Map<String, dynamic>> createManagerWithCloudFunction(String email, String role, String username) async {
    try {
      final function = FirebaseFunctions.instance
          .httpsCallable('createManager');

      final result = await function.call({
        'email': email,
        'role': role,
        'username': username,
      });

      return result.data;
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Generate a temporary random password
  String _generateTempPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = Random.secure();
    return List.generate(16, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// 调用 Cloud Function 设置用户角色
  Future<void> setUserRole(String uid, String role) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('setCustomRole');
      final result = await callable.call({
        'uid': uid,
        'role': role,
      });

      print('Role set successfully: ${result.data}');
    } on FirebaseFunctionsException catch (e) {
      print('Firebase Functions error: ${e.code} - ${e.message}');
      throw 'Failed to set user role: ${e.message}';
    } catch (e) {
      print('Error setting user role: $e');
      throw 'Failed to set user role: $e';
    }
  }

  /// Send role change email to a manager
  Future<bool> sendManagerChangeRoleEmail({
    required String userId,
    required String oldRole,
    required String newRole,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendManagerRoleChangedEmail');
      final response = await callable.call({
        'userId': userId,
        'oldRole': oldRole,
        'newRole': newRole,
      });

      return response.data['success'] == true;
    } catch (e) {
      print('Error calling sendManagerRoleChangedEmail: $e');
      return false;
    }
  }

  /// Resend verification email to manager
  Future<void> resendManagerVerificationEmail(String email) async {
    try {
      // Send password reset email (which also allows them to set their password)
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  Future<void> logout({
    String? title,
    String? message,
    bool showSuccessMessage = true,
  }) async {
    try {
      // Cancel account status listener
      _accountStatusSubscription?.cancel();
      _deleteStatusSubscription?.cancel();

      // Firebase sign out
      await FirebaseAuth.instance.signOut();
      print('Firebase signOut successful');

      // 移动端第三方登出
      if (!kIsWeb) {
        try {
          await GoogleSignIn().signOut();
          print('Google signOut successful');
        } catch (e) {
          print('Google signOut error: $e');
        }

        try {
          await FacebookAuth.instance.logOut();
          print('Facebook logOut successful');
        } catch (e) {
          print('Facebook logOut error: $e');
        }
      }

      if (showSuccessMessage) {
        TLoaders.successSnackBar(
          title: title ?? 'See you soon!',
          message: message ?? 'You have been successfully logged out.',
        );
      }

      if (Get.isRegistered<LoginController>()) {
        Get.delete<LoginController>(force: true);
      }

      // 跳转登录页
      if (kIsWeb) {
        Get.offAll(() => const AdminLoginScreen());
      } else {
        Get.offAll(() => const LoginScreen());
      }

    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Get User Role from Custom Claims
  Future<String> getUserRole() async {
    try {
      if (authUser == null) {
        userRole.value = 'user';
        return 'user';
      }

      // 强制刷新token以确保获取最新的claims
      final idTokenResult = await authUser!.getIdTokenResult(true);
      final claims = idTokenResult.claims;

      if (claims != null && claims.containsKey('role')) {
        userRole.value = claims['role'] as String;
        return userRole.value;
      } else {
        userRole.value = 'user'; // 默认角色
        return 'user';
      }
    } catch (e) {
      print('Error getting user role: $e');
      userRole.value = 'user';
      return 'user';
    }
  }

  /// Check if the user is admin
  Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role == 'admin';
  }

  // 监听用户角色变化
  void startRoleListener() {
    // 当用户状态变化时重新获取角色
    _auth.userChanges().listen((User? user) async {
      if (user != null) {
        await getUserRole();
      } else {
        userRole.value = 'user';
        // Cancel listener when user logs out
        _accountStatusSubscription?.cancel();
      }
    });
  }
}