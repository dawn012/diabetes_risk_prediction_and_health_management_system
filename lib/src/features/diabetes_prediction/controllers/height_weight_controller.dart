import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/user/user_repository.dart';
import '../../personalization/models/user_profile_model.dart';
import '../views/diabetes_input/blood_glucose_input_screen.dart';

class HeightWeightController extends GetxController {
  static HeightWeightController get instance => Get.find();

  // Observable variables
  final Rx<double> height = 170.0.obs;
  final Rx<double> weight = 70.0.obs;
  final RxBool isLoading = false.obs;

  // User repository for data operations
  final UserRepository _userRepository = Get.put(UserRepository());

  @override
  void onInit() {
    super.onInit();
    _loadExistingData();
  }

  /// Check if user can proceed (both values should be reasonable)
  RxBool get canProceed => (height.value >= 100 &&
      height.value <= 250 &&
      weight.value >= 30 &&
      weight.value <= 150).obs;

  /// Load existing user data if available
  void _loadExistingData() async {
    try {
      isLoading.value = true;

      // Get current user data
      final userData = await _userRepository.fetchUserDetails();

      if (userData.profile.height > 0) {
        height.value = userData.profile.height;
      }

      if (userData.profile.weight > 0) {
        weight.value = userData.profile.weight;
      }

    } catch (e) {
      // Handle error - maybe show a snackbar
      print('Error loading existing data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Update height value
  void updateHeight(double newHeight) {
    height.value = newHeight;
    update(); // Trigger UI update
  }

  /// Update weight value
  void updateWeight(double newWeight) {
    weight.value = double.parse(newWeight.toStringAsFixed(1)); // Round to 1 decimal
    update();
  }

  /// Increase weight by 0.5kg
  void increaseWeight() {
    if (weight.value < 150) {
      weight.value = double.parse((weight.value + 0.5).toStringAsFixed(1));
      update();
    }
  }

  /// Decrease weight by 0.5kg
  void decreaseWeight() {
    if (weight.value > 30) {
      weight.value = double.parse((weight.value - 0.5).toStringAsFixed(1));
      update();
    }
  }

  /// Calculate BMI
  double get bmi {
    final heightInMeters = height.value / 100;
    return weight.value / (heightInMeters * heightInMeters);
  }

  /// Get BMI category
  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Overweight';
    return 'Obese';
  }

  /// Save data and continue to next screen
  void saveAndContinue() async {
    if (!canProceed.value) return;

    try {
      isLoading.value = true;

      // Get current user data
      final currentUser = await _userRepository.fetchUserDetails();

      // Update the profile with new height and weight
      final updatedProfile = UserProfileModel(
        gender: currentUser.profile.gender,
        dateOfBirth: currentUser.profile.dateOfBirth,
        weight: weight.value,
        height: height.value,
        dietPreference: currentUser.profile.dietPreference,
        allergies: currentUser.profile.allergies,
        isTakeMedication: currentUser.profile.isTakeMedication,
        prescribedFrequency: currentUser.profile.prescribedFrequency,
        sleepDuration: currentUser.profile.sleepDuration,
        stressLevel: currentUser.profile.stressLevel,
        waterIntake: currentUser.profile.waterIntake,
        updatedAt: DateTime.now(),
      );

      // Save to repository
      // await _userRepository.updateUserProfile(updatedProfile);

      // Show success message
      // Get.snackbar(
      //   'Success',
      //   'Height and weight saved successfully!',
      //   snackPosition: SnackPosition.BOTTOM,
      //   backgroundColor: Get.theme.primaryColor,
      //   colorText: TColors.white,
      // );

      Get.to(() => BloodGlucoseInputScreen());

    } catch (e) {
      // Handle error
      TLoaders.errorSnackBar(title: 'Error', message: 'Failed to save data. Please try again.');
      print('Error saving height/weight: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Reset values to default
  void reset() {
    height.value = 170.0;
    weight.value = 70.0;
    update();
  }

  /// Validate input ranges
  bool validateInputs() {
    if (height.value < 100 || height.value > 250) {
      Get.snackbar(
        'Invalid Height',
        'Height must be between 100cm and 250cm',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (weight.value < 30 || weight.value > 150) {
      Get.snackbar(
        'Invalid Weight',
        'Weight must be between 30kg and 150kg',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    return true;
  }

  @override
  void onClose() {
    // Clean up resources if needed
    super.onClose();
  }
}