import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/constants/firebase_field_names.dart';

class UserProfileModel {
  final String gender;
  final DateTime dateOfBirth;
  final double weight;
  final double height;
  final String dietPreference;
  final List<String> allergies;
  final bool isTakeMedication;
  final int prescribedFrequency;
  final double sleepDuration;
  final String stressLevel;
  final int waterIntake;
  final DateTime updatedAt;

  /// Constructor
  UserProfileModel({
    required this.gender,
    required this.dateOfBirth,
    required this.weight,
    required this.height,
    required this.dietPreference,
    required this.allergies,
    required this.isTakeMedication,
    required this.prescribedFrequency,
    required this.sleepDuration,
    required this.stressLevel,
    required this.waterIntake,
    required this.updatedAt,
  });

  /// Empty factory
  static UserProfileModel empty() {
    return UserProfileModel(
      gender: '',
      dateOfBirth: DateTime.now(),
      weight: 0,
      height: 0,
      dietPreference: '',
      allergies: [],
      isTakeMedication: false,
      prescribedFrequency: 0,
      sleepDuration: 0,
      stressLevel: '',
      waterIntake: 0,
      updatedAt: DateTime.now(),
    );
  }

  /// Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.gender: gender,
      FirebaseFieldNames.dateOfBirth: dateOfBirth.millisecondsSinceEpoch,
      FirebaseFieldNames.weight: weight,
      FirebaseFieldNames.height: height,
      FirebaseFieldNames.dietPreference: dietPreference,
      FirebaseFieldNames.allergies: allergies,
      FirebaseFieldNames.isTakeMedication: isTakeMedication,
      FirebaseFieldNames.prescribedFrequency: prescribedFrequency,
      FirebaseFieldNames.sleepDuration: sleepDuration,
      FirebaseFieldNames.stressLevel: stressLevel,
      FirebaseFieldNames.waterIntake: waterIntake,
      FirebaseFieldNames.updatedAt: updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Factory method from Firebase snapshot
  factory UserProfileModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    if (data == null) return UserProfileModel.empty();

    return UserProfileModel(
      gender: data[FirebaseFieldNames.gender] ?? '',
      dateOfBirth: data[FirebaseFieldNames.dateOfBirth] != null
          ? DateTime.fromMillisecondsSinceEpoch(data[FirebaseFieldNames.dateOfBirth])
          : DateTime.now(),
      weight: (data[FirebaseFieldNames.weight] ?? 0).toDouble(),
      height: (data[FirebaseFieldNames.height] ?? 0).toDouble(),
      dietPreference: data[FirebaseFieldNames.dietPreference] ?? '',
      allergies: List<String>.from(data[FirebaseFieldNames.allergies] ?? []),
      isTakeMedication: data[FirebaseFieldNames.isTakeMedication] ?? false,
      prescribedFrequency: data[FirebaseFieldNames.prescribedFrequency] ?? 0,
      sleepDuration: (data[FirebaseFieldNames.sleepDuration] ?? 0).toDouble(),
      stressLevel: data[FirebaseFieldNames.stressLevel] ?? '',
      waterIntake: data[FirebaseFieldNames.waterIntake] ?? 0,
      updatedAt: data[FirebaseFieldNames.updatedAt] != null
          ? DateTime.fromMillisecondsSinceEpoch(data[FirebaseFieldNames.updatedAt])
          : DateTime.now(),
    );
  }
}