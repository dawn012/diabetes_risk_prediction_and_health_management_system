import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/constants/firebase_field_names.dart';

class AchievementLevelModel {
  final String level;
  final int criteria;
  final String criteriaUnit;
  final int points;

  AchievementLevelModel({
    required this.level,
    required this.criteria,
    required this.criteriaUnit,
    required this.points
  });

  /// Static function to create an empty achievement level model
  static AchievementLevelModel empty() {
    return AchievementLevelModel(
      level: '',
      criteria: 0,
      criteriaUnit: '',
      points: 0,
    );
  }

  /// Convert model to JSON structure for storing data in Firebase
  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.level: level,
      FirebaseFieldNames.criteria: criteria,
      FirebaseFieldNames.criteriaUnit: criteriaUnit,
      FirebaseFieldNames.points: points,
    };
  }

  factory AchievementLevelModel.fromMap(Map<String, dynamic> data) {
    return AchievementLevelModel(
      level: data[FirebaseFieldNames.level] ?? '',
      criteria: data[FirebaseFieldNames.criteria] ?? 0,
      criteriaUnit: data[FirebaseFieldNames.criteriaUnit] ?? '',
      points: data[FirebaseFieldNames.points] ?? 0,
    );
  }
}
