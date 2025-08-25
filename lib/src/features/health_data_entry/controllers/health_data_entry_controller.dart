import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HealthDataEntryController extends GetxController {
  // Observable states
  final selectedDate = DateTime.now().toLocal().obs;
  final selectedTime = TimeOfDay.now().obs;
  final selectedPeriod = 'Before Breakfast'.obs;
  final activeSections = <String>{'Blood Glucose'}.obs;

  // Text Controllers
  final glucoseController = TextEditingController();
  final systolicController = TextEditingController();
  final diastolicController = TextEditingController();
  final weightController = TextEditingController();
  final bodyFatController = TextEditingController();
  final exerciseNameController = TextEditingController();
  final durationController = TextEditingController();
  final intensityController = TextEditingController();
  final noteController = TextEditingController();

  // Available periods
  final List<String> periods = [
    'Wake-up',
    'Before Breakfast',
    'After Breakfast',
    'Before Lunch',
    'After Lunch',
    'Before Dinner',
    'After Dinner',
    'Bedtime',
  ];

  // Methods
  void updateDateTime(DateTime date, TimeOfDay time) {
    selectedDate.value = date;
    selectedTime.value = time;
  }

  void updatePeriod(String period) {
    selectedPeriod.value = period;
  }

  void addSection(String section) {
    activeSections.add(section);
  }

  void removeSection(String section) {
    activeSections.remove(section);
  }

  List<String> getAvailableSections() {
    const allSections = [
      'Blood Pressure & Pulse',
      'Weight & Body Fat',
      'Exercise',
      'Note',
    ];

    return allSections.where((section) => !activeSections.contains(section)).toList();
  }

  void saveHealthData() {
    // TODO: Implement save functionality
    print('Saving health data...');
    Get.back();
  }

  @override
  void onClose() {
    // Dispose controllers
    glucoseController.dispose();
    systolicController.dispose();
    diastolicController.dispose();
    weightController.dispose();
    bodyFatController.dispose();
    exerciseNameController.dispose();
    durationController.dispose();
    intensityController.dispose();
    noteController.dispose();
    super.onClose();
  }
}
