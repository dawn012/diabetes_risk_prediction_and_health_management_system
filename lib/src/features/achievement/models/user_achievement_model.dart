import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/constants/firebase_field_names.dart';
import 'achievement_model.dart';

class UserAchievementModel {
  final String userAchievementId;
  final AchievementModel achievement;
  final String currentLevel;
  final int currentCount;
  final String status;
  final DateTime startedAt;
  final DateTime? completedAt;

  UserAchievementModel({
    required this.userAchievementId,
    required this.achievement,
    required this.currentLevel,
    required this.currentCount,
    required this.status,
    required this.startedAt,
    this.completedAt
  });

  /// Static function to create an empty user achievement model
  static UserAchievementModel empty() {
    return UserAchievementModel(
      userAchievementId: '',
      achievement: AchievementModel.empty(),
      currentLevel: '',
      currentCount: 0,
      status: '',
      startedAt: DateTime(0),
      completedAt: DateTime(0),
    );
  }

  /// Convert model to JSON structure for storing data in Firebase
  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.userAchievementId: userAchievementId,
      FirebaseFieldNames.achievementId: achievement.achievementId,
      FirebaseFieldNames.currentLevel: currentLevel,
      FirebaseFieldNames.currentCount: currentCount,
      FirebaseFieldNames.status: status,
      FirebaseFieldNames.startedAt: Timestamp.fromDate(startedAt),
      FirebaseFieldNames.completedAt: Timestamp.fromDate(completedAt!),
    };
  }

  /// Factory method to create a UserAchievementModel from a Firebase document snapshot
  factory UserAchievementModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    if (document.data() != null) {
      final data = document.data()!;
      return UserAchievementModel(
        userAchievementId: data[FirebaseFieldNames.userAchievementId] ?? '',
        achievement: AchievementModel.empty(),
        currentLevel: data[FirebaseFieldNames.currentLevel] ?? '',
        currentCount: data[FirebaseFieldNames.currentCount] ?? 0,
        status: data[FirebaseFieldNames.status] ?? '',
        startedAt: (data[FirebaseFieldNames.startedAt] as Timestamp?)?.toDate() ?? DateTime(0),
        completedAt: (data[FirebaseFieldNames.completedAt] as Timestamp?)?.toDate() ?? DateTime(0),
      );
    } else {
      return UserAchievementModel.empty();
    }
  }
}
