import '../../../utils/constants/firebase_field_names.dart';
import '../../../utils/helpers/bmi_calculator.dart';

class UserProfileModel {
  final String gender;
  final DateTime dateOfBirth;
  final double weight;
  final double height;
  final int dailyStepsGoal;
  final int weeklyExerciseTime;
  final DateTime updatedAt;

  final bool hasChangedGender;
  final bool hasChangedDateOfBirth;

  UserProfileModel({
    required this.gender,
    required this.dateOfBirth,
    required this.weight,
    required this.height,
    this.dailyStepsGoal = 7500,
    this.weeklyExerciseTime = 150,
    required this.updatedAt,
    this.hasChangedGender = false,
    this.hasChangedDateOfBirth = false,
  });

  int? get age {
    if (isDateUnset(dateOfBirth)) return null;

    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;

    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }

    return age;
  }

  int? get ageInMonths {
    if (isDateUnset(dateOfBirth)) return null;

    final now = DateTime.now();
    int months = (now.year - dateOfBirth.year) * 12;
    months += now.month - dateOfBirth.month;

    if (now.day < dateOfBirth.day) {
      months--;
    }

    return months > 0 ? months : null;
  }

  double? get bmi {
    if (weight <= 0 || height <= 0) return null;
    return BMICalculator.calculateBMI(weight, height);
  }

  BMICategory? get bmiCategory {
    if (weight <= 0 || height <= 0) return null;

    return BMICalculator.getBMICategory(
      weight: weight,
      height: height,
      ageInMonths: ageInMonths,
      gender: hasGender ? gender : null,
    );
  }

  String get formattedBMI {
    final bmiValue = bmi;
    if (bmiValue == null) return '-';
    return bmiValue.toStringAsFixed(1);
  }

  bool isDateUnset(DateTime dateOfBirth) => dateOfBirth.millisecondsSinceEpoch == 0;

  bool get hasGender => gender.isNotEmpty;

  bool get hasDateOfBirth => !isDateUnset(dateOfBirth);

  bool get hasWeight => weight > 0;

  bool get hasHeight => height > 0;

  static UserProfileModel empty() {
    return UserProfileModel(
      gender: '',
      dateOfBirth: DateTime.fromMillisecondsSinceEpoch(0),
      weight: 0,
      height: 0,
      dailyStepsGoal: 7500,
      weeklyExerciseTime: 150,
      updatedAt: DateTime.now(),
      hasChangedGender: false,
      hasChangedDateOfBirth: false,
    );
  }

  UserProfileModel copyWith({
    String? gender,
    DateTime? dateOfBirth,
    double? weight,
    double? height,
    int? dailyStepsGoal,
    int? weeklyExerciseTime,
    DateTime? updatedAt,
    bool? hasChangedGender,
    bool? hasChangedDateOfBirth,
  }) {
    return UserProfileModel(
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      dailyStepsGoal: dailyStepsGoal ?? this.dailyStepsGoal,
      weeklyExerciseTime: weeklyExerciseTime ?? this.weeklyExerciseTime,
      updatedAt: updatedAt ?? this.updatedAt,
      hasChangedGender: hasChangedGender ?? this.hasChangedGender,
      hasChangedDateOfBirth: hasChangedDateOfBirth ?? this.hasChangedDateOfBirth,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.gender: gender,
      FirebaseFieldNames.dateOfBirth: dateOfBirth.millisecondsSinceEpoch,
      FirebaseFieldNames.weight: weight,
      FirebaseFieldNames.height: height,
      FirebaseFieldNames.dailyStepsGoal: dailyStepsGoal,
      FirebaseFieldNames.weeklyExerciseTime: weeklyExerciseTime,
      FirebaseFieldNames.updatedAt: updatedAt.millisecondsSinceEpoch,
      FirebaseFieldNames.hasChangedGender: hasChangedGender,
      FirebaseFieldNames.hasChangedDateOfBirth: hasChangedDateOfBirth,
    };
  }

  factory UserProfileModel.fromMap(Map<String, dynamic> data) {
    return UserProfileModel(
      gender: data[FirebaseFieldNames.gender] ?? '',
      dateOfBirth: data[FirebaseFieldNames.dateOfBirth] != null
          ? DateTime.fromMillisecondsSinceEpoch(data[FirebaseFieldNames.dateOfBirth])
          : DateTime.fromMillisecondsSinceEpoch(0),
      weight: (data[FirebaseFieldNames.weight] ?? 0).toDouble(),
      height: (data[FirebaseFieldNames.height] ?? 0).toDouble(),
      dailyStepsGoal: data[FirebaseFieldNames.dailyStepsGoal] ?? 7500,
      weeklyExerciseTime: data[FirebaseFieldNames.weeklyExerciseTime] ?? 150,
      updatedAt: data[FirebaseFieldNames.updatedAt] != null
          ? DateTime.fromMillisecondsSinceEpoch(data[FirebaseFieldNames.updatedAt])
          : DateTime.now(),
      hasChangedGender: data[FirebaseFieldNames.hasChangedGender] ?? false,
      hasChangedDateOfBirth: data[FirebaseFieldNames.hasChangedDateOfBirth] ?? false,
    );
  }
}