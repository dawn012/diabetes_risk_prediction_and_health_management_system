import '../../../utils/constants/firebase_field_names.dart';

class UserProfileModel {
  final String gender;
  final DateTime dateOfBirth;
  final double weight;
  final double height;
  final String dietPreference;
  final List<String> allergies;
  final bool isTakeMedication;
  final int medicationAdherence;
  final double sleepDuration;
  final int stressLevel;
  final double waterIntake;
  final int dailyStepsGoal;
  final int weeklyExerciseTime;
  final double bloodGlucose;
  final int dailyPhysicalActivityDuration;
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
    required this.medicationAdherence,
    required this.sleepDuration,
    required this.stressLevel,
    required this.waterIntake,
    this.dailyStepsGoal = 7500,
    this.weeklyExerciseTime = 150,
    this.bloodGlucose = 0.0,
    this.dailyPhysicalActivityDuration = 0,
    required this.updatedAt,
  });

  /// Calculate current age from date of birth
  int? get age {
    if (isDateUnset(dateOfBirth)) return null;

    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;

    // Adjust if birthday hasn't occurred yet this year
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }

    return age;
  }

  bool isDateUnset(DateTime dateOfBirth) => dateOfBirth.millisecondsSinceEpoch == 0;

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
      medicationAdherence: 0,
      sleepDuration: 0,
      stressLevel: 0,
      waterIntake: 0,
      dailyStepsGoal: 7500,
      weeklyExerciseTime: 150,
      bloodGlucose: 0.0,
      dailyPhysicalActivityDuration: 0,
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
    int? medicationAdherence,
    double? sleepDuration,
    int? stressLevel,
    double? waterIntake,
    int? dailyStepsGoal,
    int? weeklyExerciseTime,
    double? bloodGlucose,
    int? dailyPhysicalActivityDuration,
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
      medicationAdherence: medicationAdherence ?? this.medicationAdherence,
      sleepDuration: sleepDuration ?? this.sleepDuration,
      stressLevel: stressLevel ?? this.stressLevel,
      waterIntake: waterIntake ?? this.waterIntake,
      dailyStepsGoal: dailyStepsGoal ?? this.dailyStepsGoal,
      weeklyExerciseTime: weeklyExerciseTime ?? this.weeklyExerciseTime,
      bloodGlucose: bloodGlucose ?? this.bloodGlucose,
      dailyPhysicalActivityDuration: dailyPhysicalActivityDuration ?? this.dailyPhysicalActivityDuration,
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
      FirebaseFieldNames.medicationAdherence: medicationAdherence,
      FirebaseFieldNames.sleepDuration: sleepDuration,
      FirebaseFieldNames.stressLevel: stressLevel,
      FirebaseFieldNames.waterIntake: waterIntake,
      FirebaseFieldNames.dailyStepsGoal: dailyStepsGoal,
      FirebaseFieldNames.weeklyExerciseTime: weeklyExerciseTime,
      'bloodGlucose': bloodGlucose,
      'dailyPhysicalActivityDuration': dailyPhysicalActivityDuration,
      FirebaseFieldNames.updatedAt: updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Factory method from Map data (for contained objects)
  factory UserProfileModel.fromMap(Map<String, dynamic> data) {
    return UserProfileModel(
      gender: data[FirebaseFieldNames.gender] ?? '',
      dateOfBirth: data[FirebaseFieldNames.dateOfBirth] != null
          ? DateTime.fromMillisecondsSinceEpoch(data[FirebaseFieldNames.dateOfBirth])
          : DateTime.fromMillisecondsSinceEpoch(0),
      weight: (data[FirebaseFieldNames.weight] ?? 0).toDouble(),
      height: (data[FirebaseFieldNames.height] ?? 0).toDouble(),
      dietPreference: data[FirebaseFieldNames.dietPreference] ?? '',
      allergies: List<String>.from(data[FirebaseFieldNames.allergies] ?? []),
      isTakeMedication: data[FirebaseFieldNames.isTakeMedication] ?? false,
      medicationAdherence: data[FirebaseFieldNames.medicationAdherence] ?? 0,
      sleepDuration: (data[FirebaseFieldNames.sleepDuration] ?? 0).toDouble(),
      stressLevel: data[FirebaseFieldNames.stressLevel] ?? 0,
      waterIntake: (data[FirebaseFieldNames.waterIntake] ?? 0).toDouble(),
      dailyStepsGoal: data[FirebaseFieldNames.dailyStepsGoal] ?? 7500,
      weeklyExerciseTime: data[FirebaseFieldNames.weeklyExerciseTime] ?? 150,
      bloodGlucose: (data[FirebaseFieldNames.bloodGlucose] ?? 0).toDouble(),
      dailyPhysicalActivityDuration: data['dailyPhysicalActivityDuration'] ?? 0,
      updatedAt: data[FirebaseFieldNames.updatedAt] != null
          ? DateTime.fromMillisecondsSinceEpoch(data[FirebaseFieldNames.updatedAt])
          : DateTime.now(),
    );
  }
}