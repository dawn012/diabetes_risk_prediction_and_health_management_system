import 'package:diabetes_risk_prediction_and_health_management_system/src/features/authentication/views/login/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class SplashScreenController extends GetxController{
  // Getter
  static SplashScreenController get find => Get.find();

  // RxBool 是 GetX 提供的可观察（reactive）布尔变量
  // .obs：将普通变量变成 Rx 对象，使其可以被监听
  RxBool animate = false.obs;

  Future startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 500));
    animate.value = true;
    await Future.delayed(const Duration(milliseconds: 5000));
    Get.to(const LoginScreen());
  }
}