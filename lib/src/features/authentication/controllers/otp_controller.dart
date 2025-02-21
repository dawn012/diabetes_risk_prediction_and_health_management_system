import 'package:get/get.dart';

import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../homepage.dart';


class OTPController extends GetxController {
  static OTPController get instance => Get.find();

  void verifyOTP(String otp) async {
    var isVerified = await AuthenticationRepository.instance.verifyOTP(otp);
    isVerified ? Get.offAll(const Homepage()) : Get.back();
  }
}