import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'src/data/repositories/authentication/authentication_repository.dart';

void main() async {
  /// Widgets Binding
  final WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  /// -- GetX Local Storage
  await GetStorage.init();

  /// -- Await Splash until other items load
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  /// -- Initialize Firebase & Authentication Repository
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyAalYUvHbJBAaL7YyjdYhHwtt63FYOtqjI",
            authDomain: "diabetes-health-system.firebaseapp.com",
            projectId: "diabetes-health-system",
            storageBucket: "diabetes-health-system.firebasestorage.app",
            messagingSenderId: "797068714189",
            appId: "1:797068714189:web:f8b91ba81aa8c07ee44984",
            measurementId: "G-BR1JQP883Z"
        )).then((FirebaseApp value) => Get.put(AuthenticationRepository()));
  } else {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
        .then((FirebaseApp value) => Get.put(AuthenticationRepository())); // Get.put() 会将 AuthenticationRepository 放入 GetX 的依赖注入系统中，确保可以在应用的任何地方访问到 AuthenticationRepository 实例
  }

  // FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
  // await FirebaseAppCheck.instance.activate(
  //   androidProvider: AndroidProvider.debug,
  // );

  /// -- 启动角色监听
  final authRepo = Get.find<AuthenticationRepository>();
  authRepo.startRoleListener();

  runApp(const App());
}