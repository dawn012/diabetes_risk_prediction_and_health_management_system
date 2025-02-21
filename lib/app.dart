import 'package:diabetes_risk_prediction_and_health_management_system/src/bindings/general_bindings.dart';
import 'package:diabetes_risk_prediction_and_health_management_system/src/features/authentication/views/onboarding/onboarding.dart';
import 'package:diabetes_risk_prediction_and_health_management_system/src/features/authentication/views/splash_screen/splash_screen.dart';
import 'package:diabetes_risk_prediction_and_health_management_system/src/utils/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: TAppTheme.lightTheme,
      darkTheme: TAppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialBinding: GeneralBindings(),
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.leftToRightWithFade,
      transitionDuration: const Duration(milliseconds: 500),
      home: OnBoardingScreen(),
    );
  }
}
