import 'package:diabetes_risk_prediction_and_health_management_system/src/data/repositories/user/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../navigation_menu.dart';
import '../../../features/admin/views/admin_dashboard/admin_dashboard_screen.dart';
import '../../../features/authentication/views/login/login_screen.dart';
import '../../../features/authentication/views/onboarding/onboarding.dart';
import '../../../features/authentication/views/signup/verify_email.dart';
import '../../../features/personalization/views/profile/complete_profile_screen.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/exceptions/firebase_auth_exceptions.dart';
import '../../../utils/exceptions/firebase_exceptions.dart';
import '../../../utils/exceptions/format_exceptions.dart';
import '../../../utils/exceptions/platform_exceptions.dart';

class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  /// Variables
  final deviceStorage = GetStorage();
  final _auth = FirebaseAuth.instance;

  /// Get Authenticated User Data
  User? get authUser => _auth.currentUser;

  final userRole = Rx<String>('user');
  bool get isAdminUser => userRole.value == 'admin';
  bool get isRegularUser => userRole.value == 'user';

  // 用于存储 Firebase 发送的验证码会话 ID
  var verificationId = ''.obs;

  // Getters
  // User? get firebaseUser => _firebaseUser.value;
  // String get getUserId => firebaseUser?.uid ?? "";
  // String get getUserEmail => firebaseUser?.email ?? "";

  @override
  void onReady() {
    // _firebaseUser = Rx<User?>(_auth.currentUser);
    // _firebaseUser.bindStream(_auth.userChanges());
    FlutterNativeSplash.remove();
    screenRedirect();
    if (authUser != null) {
      getUserRole();
    }
  }

  screenRedirect() async {
    final user = _auth.currentUser;
    if (user != null) {
      final role = await getUserRole();

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

        // If the user's email is verified and (如果是用户则档案已完成)，navigate based on role
        if (role == 'admin' || role.contains('manager')) {
          Get.offAll(() => AdminDashboardScreen());
        } else {
          Get.offAll(() => NavigationMenu());
        }
      } else {
        // If the user's email is not verified, navigate to the MainVerification
        Get.offAll(() => VerifyEmailScreen());
      }
    } else {
      // Local Storage
      deviceStorage.writeIfNull('IsFirstTime', true);

      // Check if it's the first time launching the app
      deviceStorage.read('IsFirstTime') != true
          ? Get.off(() => const LoginScreen())
          : Get.off(() => const OnBoardingScreen());
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

      // // Trigger the authentication flow
      // // Allow the user to select the gmail they want to sign in
      // final LoginResult loginResult = await FacebookAuth.instance.login(permissions: ['email', 'public_profile'],);
      //
      // // Create a credential from the access token
      // final OAuthCredential facebookAuthCredential = FacebookAuthProvider.credential('${loginResult.accessToken?.tokenString}');
      //
      // // Once signed in, return the userCredential
      // return await FirebaseAuth.instance.signInWithCredential(facebookAuthCredential);
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
        // if (e.code == 'invalid-phone-number') {
        //   Get.snackbar('Error', 'The provided phone number is not valid.');
        // } else {
        //   Get.snackbar(
        //       'Error', 'Something went wrong. Please try again later.');
        // }
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

  Future<void> logout() async {
    try {
      await GoogleSignIn().signOut();
      await FacebookAuth.instance.logOut();
      await FirebaseAuth.instance.signOut();
      Get.offAll(() => const LoginScreen());
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

  /// Delete User - Remove User Auth and Firestore Account
  Future<void> deleteAccount() async {
    try {
      await UserRepository.instance.removeUserRecord(_auth.currentUser!.uid);
      await _auth.currentUser?.delete();
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
      }
    });
  }
}
