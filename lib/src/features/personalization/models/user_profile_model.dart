import '../../../utils/constants/firebase_field_names.dart';
import '../../../utils/helpers/bmi_calculator.dart';

class UserProfileModel {
  final String gender;
  final DateTime dateOfBirth;
  final double weight;
  final double height;
  final String dietPreference;
  final List<String> allergies;
  final int dailyStepsGoal;
  final int weeklyExerciseTime;
  final DateTime updatedAt;

  // Track if critical fields have been changed
  final bool hasChangedGender;
  final bool hasChangedDateOfBirth;

  /// Constructor
  UserProfileModel({
    required this.gender,
    required this.dateOfBirth,
    required this.weight,
    required this.height,
    required this.dietPreference,
    required this.allergies,
    this.dailyStepsGoal = 7500,
    this.weeklyExerciseTime = 150,
    required this.updatedAt,
    this.hasChangedGender = false,
    this.hasChangedDateOfBirth = false,
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

  /// Calculate age in months
  int? get ageInMonths {
    if (isDateUnset(dateOfBirth)) return null;

    final now = DateTime.now();
    int months = (now.year - dateOfBirth.year) * 12;
    months += now.month - dateOfBirth.month;

    // Adjust if birthday hasn't occurred yet this month
    if (now.day < dateOfBirth.day) {
      months--;
    }

    return months > 0 ? months : null;
  }

  /// Calculate BMI using BMICalculator
  double? get bmi {
    if (weight <= 0 || height <= 0) return null;
    return BMICalculator.calculateBMI(weight, height);
  }

  /// Get BMI category using BMICalculator
  BMICategory? get bmiCategory {
    if (weight <= 0 || height <= 0) return null;

    return BMICalculator.getBMICategory(
      weight: weight,
      height: height,
      ageInMonths: ageInMonths,
      gender: hasGender ? gender : null,
    );
  }

  /// Get formatted BMI string
  String get formattedBMI {
    final bmiValue = bmi;
    if (bmiValue == null) return '-';
    return bmiValue.toStringAsFixed(1);
  }

  bool isDateUnset(DateTime dateOfBirth) => dateOfBirth.millisecondsSinceEpoch == 0;

  /// Check if gender is set
  bool get hasGender => gender.isNotEmpty;

  /// Check if date of birth is set
  bool get hasDateOfBirth => !isDateUnset(dateOfBirth);

  /// Check if weight is set
  bool get hasWeight => weight > 0;

  /// Check if height is set
  bool get hasHeight => height > 0;

  /// Empty factory with default values
  static UserProfileModel empty() {
    return UserProfileModel(
      gender: '',
      dateOfBirth: DateTime.fromMillisecondsSinceEpoch(0),
      weight: 0,
      height: 0,
      dietPreference: '',
      allergies: [],
      dailyStepsGoal: 7500,
      weeklyExerciseTime: 150,
      updatedAt: DateTime.now(),
      hasChangedGender: false,
      hasChangedDateOfBirth: false,
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
      dietPreference: dietPreference ?? this.dietPreference,
      allergies: allergies ?? this.allergies,
      dailyStepsGoal: dailyStepsGoal ?? this.dailyStepsGoal,
      weeklyExerciseTime: weeklyExerciseTime ?? this.weeklyExerciseTime,
      updatedAt: updatedAt ?? this.updatedAt,
      hasChangedGender: hasChangedGender ?? this.hasChangedGender,
      hasChangedDateOfBirth: hasChangedDateOfBirth ?? this.hasChangedDateOfBirth,
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
      FirebaseFieldNames.dailyStepsGoal: dailyStepsGoal,
      FirebaseFieldNames.weeklyExerciseTime: weeklyExerciseTime,
      FirebaseFieldNames.updatedAt: updatedAt.millisecondsSinceEpoch,
      FirebaseFieldNames.hasChangedGender: hasChangedGender,
      FirebaseFieldNames.hasChangedDateOfBirth: hasChangedDateOfBirth,
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