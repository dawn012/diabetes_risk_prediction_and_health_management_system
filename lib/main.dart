import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive_flutter/adapters.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'src/data/repositories/authentication/authentication_repository.dart';
import 'src/data/repositories/notification/notification_repository.dart';
import 'src/services/fcm_service.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📩 Background message received: ${message.messageId}');
  print('Data: ${message.data}');

  // 初始化 Firebase（只要一次，多次调用也会被 SDK 处理）
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 初始化并调用你的本地通知
  final fcmService = FCMService();
  await fcmService.initialize();
  await fcmService.showLocalNotification(message);
}

Future<void> main() async {
  // --- Initialize Flutter bindings ---
  final WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // --- Keep the splash screen until setup completes ---
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // --- Initialize local storage (GetStorage) ---
  await GetStorage.init();

  // --- Initialize Hive for local database ---
  await Hive.initFlutter();

  // --- Initialize Firebase ---
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAalYUvHbJBAaL7YyjdYhHwtt63FYOtqjI",
        authDomain: "diabetes-health-system.firebaseapp.com",
        projectId: "diabetes-health-system",
        storageBucket: "diabetes-health-system.firebasestorage.app",
        messagingSenderId: "797068714189",
        appId: "1:797068714189:web:f8b91ba81aa8c07ee44984",
        measurementId: "G-BR1JQP883Z",
      ),
    );

    // 保持登录状态，刷新页面不会自动登出
    // await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // --- Inject AuthenticationRepository into GetX dependency system ---
  Get.put(AuthenticationRepository());
  Get.put(NotificationRepository());

  // --- Initialize Firebase Cloud Messaging (safe for all platforms) ---
  final fcmService = FCMService();
  try {
    await fcmService.initialize();
  } catch (e) {
    if (kDebugMode) {
      print("⚠️ Failed to initialize FCM (expected on Web): $e");
    }
  }

  // FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
  // await FirebaseAppCheck.instance.activate(
  //   androidProvider: AndroidProvider.debug,
  // );

  // --- Initialize Stripe (only for mobile platforms) ---
  if (!kIsWeb) {
    try {
      Stripe.publishableKey =
      'pk_test_51RxrvGFLRUQjWHbT4A7B9QNPwDdjKCbYAOZgvVQqXKdZp1Wg4vWgjCQXfDAnSSZCqIwwsBrhBndCz6nPS9oER7gU00oHcguBrs';
      Stripe.urlScheme = 'com.diatrack.app'; // Used for payment redirects
      await Stripe.instance.applySettings();
    } catch (e) {
      if (kDebugMode) {
        print("⚠️ Stripe initialization failed (not supported on Web): $e");
      }
    }
  }

  // --- Start role listener from AuthenticationRepository ---
  final authRepo = Get.find<AuthenticationRepository>();
  authRepo.startRoleListener();

  // --- Run the main application ---
  runApp(const App());
}
