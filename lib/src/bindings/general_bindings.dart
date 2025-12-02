import 'package:get/get.dart';

import '../features/personalization/controllers/avatar_frame_controller.dart';
import '../features/personalization/controllers/user_controller.dart';
import '../services/tutorial_flow_manager.dart';
import '../services/deep_link_service.dart';
import '../services/diabetes_hive_storage_manager.dart';
import '../services/diabetes_prediction_service.dart';
import '../services/meal_hive_storage_manager.dart';
import '../services/step_tracking_service.dart';
import '../utils/helpers/network_manager.dart';

class GeneralBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(NetworkManager());
    Get.put(UserController());
    Get.put(StepTrackingService());
    Get.put(DeepLinkService());
    Get.put(DiabetesHiveStorageManager());
    Get.put(MealHiveStorageManager());
    Get.put(DiabetesPredictionService());
    Get.put(TutorialFlowManager());
    Get.put(AvatarFrameController());
  }
}