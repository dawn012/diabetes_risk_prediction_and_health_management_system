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
  final int dailyStepsGoal;
  final int weeklyExerciseTime;
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
    this.dailyStepsGoal = 7500,
    this.weeklyExerciseTime = 150,
    required this.updatedAt,
  });

  /// Empty factory with default values
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
      dailyStepsGoal: 7500,
      weeklyExerciseTime: 150,
      updatedAt: DateTime.now(),
    );
  }

  /// CopyWith method
  UserProfileModel copyWith({
    String? gender,
    DateTime? dateOfBirth,
    double? weight,
    double? height,
    String? dietPreference,
    List<String>? allergies,
    bool? isTakeMedication,
    int? prescribedFrequency,
    double? sleepDuration,
    String? stressLevel,
    int? waterIntake,
    int? dailyStepsGoal,
    int? weeklyExerciseTime,
    DateTime? updatedAt,
  }) {
    return UserProfileModel(
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      dietPreference: dietPreference ?? this.dietPreference,
      allergies: allergies ?? this.allergies,
      isTakeMedication: isTakeMedication ?? this.isTakeMedication,
      prescribedFrequency: prescribedFrequency ?? this.prescribedFrequency,
      sleepDuration: sleepDuration ?? this.sleepDuration,
      stressLevel: stressLevel ?? this.stressLevel,
      waterIntake: waterIntake ?? this.waterIntake,
      dailyStepsGoal: dailyStepsGoal ?? this.dailyStepsGoal,
      weeklyExerciseTime: weeklyExerciseTime ?? this.weeklyExerciseTime,
      updatedAt: updatedAt ?? this.updatedAt,
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
      FirebaseFieldNames.dailyStepsGoal: dailyStepsGoal,
      FirebaseFieldNames.weeklyExerciseTime: weeklyExerciseTime,
      FirebaseFieldNames.updatedAt: updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Factory method from Map data (for contained objects)
  factory UserProfileModel.fromMap(Map<String, dynamic> data) {
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
      dailyStepsGoal: data[FirebaseFieldNames.dailyStepsGoal] ?? 7500,
      weeklyExerciseTime: data[FirebaseFieldNames.weeklyExerciseTime] ?? 150,
      updatedAt: data[FirebaseFieldNames.updatedAt] != null
          ? DateTime.fromMillisecondsSinceEpoch(data[FirebaseFieldNames.updatedAt])
          : DateTime.now(),
    );
  }
}