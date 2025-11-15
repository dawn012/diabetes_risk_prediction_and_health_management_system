import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'src/bindings/general_bindings.dart';
import 'src/features/authentication/views/login/admin_login_screen.dart';
import 'src/features/authentication/views/onboarding/onboarding.dart';
import 'src/services/step_tracking_service.dart';
import 'src/utils/theme/theme.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 添加调试信息
    if (kDebugMode) {
      print('🚀 App starting on: ${kIsWeb ? 'Web' : 'Mobile'}');
      print('🏠 Home page should be: ${kIsWeb ? 'AdminLoginScreen' : 'OnBoardingScreen'}');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // Save steps when app goes to background
      try {
        final stepService = Get.find<StepTrackingService>();
        stepService.saveCurrentSteps();
      } catch (e) {
        print('Step service not found: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeWidget = kIsWeb ? const AdminLoginScreen() : const OnBoardingScreen();

    if (kDebugMode) {
      print('🎯 Actually building: ${homeWidget.runtimeType}');
    }

    return GetMaterialApp(
      title: 'Diatrack',
      theme: TAppTheme.lightTheme,
      darkTheme: TAppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialBinding: GeneralBindings(),
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.rightToLeftWithFade,
      transitionDuration: const Duration(milliseconds: 500),
      home: homeWidget,
    );
  }
}