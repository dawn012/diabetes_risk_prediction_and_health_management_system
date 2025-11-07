import '../../../utils/constants/enums.dart';
import '../../../utils/constants/firebase_field_names.dart';

class AchievementLevelModel {
  final AchievementLevel level;
  final int criteria;
  final String criteriaUnit;
  final int points;

  AchievementLevelModel({
    required this.level,
    required this.criteria,
    required this.criteriaUnit,
    required this.points,
  });

  /// Static function to create an empty achievement level model
  static AchievementLevelModel empty() {
    return AchievementLevelModel(
      level: AchievementLevel.bronze,
      criteria: 0,
      criteriaUnit: '',
      points: 0,
    );
  }

  /// Create a copy with updated fields
  AchievementLevelModel copyWith({
    AchievementLevel? level,
    int? criteria,
    String? criteriaUnit,
    int? points,
  }) {
    return AchievementLevelModel(
      level: level ?? this.level,
      criteria: criteria ?? this.criteria,
      criteriaUnit: criteriaUnit ?? this.criteriaUnit,
      points: points ?? this.points,
    );
  }

  /// Convert model to JSON structure for storing data in Firebase
  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.level: level.value,
      FirebaseFieldNames.criteria: criteria,
      FirebaseFieldNames.criteriaUnit: criteriaUnit,
      FirebaseFieldNames.points: points,
    };
  }

  /// Factory method to create from map
  factory AchievementLevelModel.fromMap(Map<String, dynamic> data) {
    return AchievementLevelModel(
      level: AchievementLevel.fromString(data[FirebaseFieldNames.level] ?? 'bronze'),
      criteria: data[FirebaseFieldNames.criteria] ?? 0,
      criteriaUnit: data[FirebaseFieldNames.criteriaUnit] ?? '',
      points: data[FirebaseFieldNames.points] ?? 0,
    );
  }

  @override
  String toString() {
    return 'AchievementLevelModel{level: ${level.displayName}, criteria: $criteria, unit: $criteriaUnit, points: $points}';
  }
}