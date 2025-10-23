import 'package:get/get.dart';

import '../services/step_tracking_service.dart';
import '../utils/helpers/network_manager.dart';

class GeneralBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(NetworkManager());
    Get.put(StepTrackingService());
  }
}