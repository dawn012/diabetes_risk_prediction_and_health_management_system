// import 'dart:convert';
// import 'package:get/get.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class DiabetesLocalStorageManager extends GetxController {
//   static DiabetesLocalStorageManager get instance => Get.find();
//
//   late SharedPreferences _prefs;
//
//   // Storage keys
//   static const String _keyFirstTime = 'diabetes_prediction_first_time';
//   static const String _keyProgress = 'diabetes_prediction_progress';
//   static const String _keyLastStep = 'diabetes_prediction_last_step';
//   static const String _keyIncomplete = 'diabetes_prediction_incomplete';
//
//   @override
//   void onInit() {
//     super.onInit();
//     _initializeStorage();
//   }
//
//   /// Initialize shared preferences
//   Future<void> _initializeStorage() async {
//     _prefs = await SharedPreferences.getInstance();
//   }
//
//   /// Check if this is user's first time doing prediction
//   Future<bool> isFirstTime() async {
//     return _prefs.getBool(_keyFirstTime) ?? true;
//   }
//
//   /// Mark that user has started prediction flow
//   Future<void> setFirstTimeComplete() async {
//     await _prefs.setBool(_keyFirstTime, false);
//   }
//
//   /// Save prediction progress
//   Future<void> savePredictionProgress(Map<String, dynamic> progress) async {
//     await _prefs.setString(_keyProgress, jsonEncode(progress));
//   }
//
//   /// Get prediction progress
//   Future<Map<String, dynamic>> getPredictionProgress() async {
//     final progressJson = _prefs.getString(_keyProgress);
//     if (progressJson != null) {
//       return jsonDecode(progressJson);
//     }
//     return {
//       'step1': false,
//       'step2': false,
//       'step3': false,
//       'step4': false,
//       'step5': false,
//       'step6': false,
//       'step7': false,
//       'step8': false,
//     };
//   }
//
//   /// Save last completed step
//   Future<void> saveLastStep(int stepNumber) async {
//     await _prefs.setInt(_keyLastStep, stepNumber);
//   }
//
//   /// Get last completed step
//   Future<int> getLastStep() async {
//     return _prefs.getInt(_keyLastStep) ?? 0;
//   }
//
//   /// Mark prediction as incomplete (user exited mid-flow)
//   Future<void> markIncomplete(bool incomplete) async {
//     await _prefs.setBool(_keyIncomplete, incomplete);
//   }
//
//   /// Check if there's incomplete prediction
//   Future<bool> hasIncompletePrediction() async {
//     return _prefs.getBool(_keyIncomplete) ?? false;
//   }
//
//   /// Update specific step completion
//   Future<void> updateStepCompletion(int stepNumber, bool completed) async {
//     final progress = await getPredictionProgress();
//     progress['step$stepNumber'] = completed;
//     await savePredictionProgress(progress);
//
//     if (completed) {
//       await saveLastStep(stepNumber);
//     }
//   }
//
//   /// Check if a specific step is completed
//   Future<bool> isStepCompleted(int stepNumber) async {
//     final progress = await getPredictionProgress();
//     return progress['step$stepNumber'] ?? false;
//   }
//
//   /// Get number of completed steps
//   Future<int> getCompletedStepsCount() async {
//     final progress = await getPredictionProgress();
//     int count = 0;
//     for (int i = 1; i <= 8; i++) {
//       if (progress['step$i'] == true) count++;
//     }
//     return count;
//   }
//
//   /// Check if user can navigate back to a step
//   Future<bool> canNavigateBackTo(int targetStep) async {
//     final lastStep = await getLastStep();
//     return targetStep <= lastStep;
//   }
//
//   /// Clear all prediction progress
//   Future<void> clearPredictionProgress() async {
//     await _prefs.remove(_keyProgress);
//     await _prefs.remove(_keyLastStep);
//     await _prefs.remove(_keyIncomplete);
//
//     // Clear all step data
//     for (int i = 1; i <= 8; i++) {
//       await clearStepData(i);
//     }
//   }
//
//   /// Reset to first time state
//   Future<void> resetToFirstTime() async {
//     await clearPredictionProgress();
//     await _prefs.setBool(_keyFirstTime, true);
//   }
//
//   /// Get progress percentage
//   Future<double> getProgressPercentage() async {
//     final completedCount = await getCompletedStepsCount();
//     return completedCount / 8.0;
//   }
//
//   /// Save temporary step data (for resuming)
//   Future<void> saveStepData(int stepNumber, Map<String, dynamic> data) async {
//     await _prefs.setString('step_${stepNumber}_data', jsonEncode(data));
//   }
//
//   /// Get temporary step data
//   Future<Map<String, dynamic>?> getStepData(int stepNumber) async {
//     final dataJson = _prefs.getString('step_${stepNumber}_data');
//     if (dataJson != null) {
//       return jsonDecode(dataJson);
//     }
//     return null;
//   }
//
//   /// Clear temporary step data
//   Future<void> clearStepData(int stepNumber) async {
//     await _prefs.remove('step_${stepNumber}_data');
//   }
//
//   /// Get all steps status summary
//   Future<Map<String, dynamic>> getProgressSummary() async {
//     final progress = await getPredictionProgress();
//     final lastStep = await getLastStep();
//     final completedCount = await getCompletedStepsCount();
//     final isIncomplete = await hasIncompletePrediction();
//     final isFirstTime = await this.isFirstTime();
//
//     return {
//       'progress': progress,
//       'lastStep': lastStep,
//       'completedCount': completedCount,
//       'isIncomplete': isIncomplete,
//       'isFirstTime': isFirstTime,
//       'progressPercentage': completedCount / 8.0,
//     };
//   }
//
//   /// Check if all steps are completed
//   Future<bool> isAllStepsCompleted() async {
//     final count = await getCompletedStepsCount();
//     return count == 8;
//   }
//
//   /// Get next incomplete step
//   Future<int> getNextIncompleteStep() async {
//     final progress = await getPredictionProgress();
//     for (int i = 1; i <= 8; i++) {
//       if (progress['step$i'] != true) {
//         return i;
//       }
//     }
//     return 1; // Default to first step if all completed
//   }
// }