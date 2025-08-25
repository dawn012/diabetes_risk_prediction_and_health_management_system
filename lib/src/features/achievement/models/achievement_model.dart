import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/constants/firebase_field_names.dart';
import 'achievement_level_model.dart';

class AchievementModel {
  final String achievementId;
  final String achievementTitle;
  final String description;
  final String achievementType;
  final String imagePath;
  final List<AchievementLevelModel> levels;
  final bool isActive;
  final DateTime createdAt;

  AchievementModel({
    required this.achievementId,
    required this.achievementTitle,
    required this.description,
    required this.achievementType,
    required this.imagePath,
    required this.levels,
    required this.isActive,
    required this.createdAt
  });

  /// Static function to create an empty achievement model
  static AchievementModel empty() {
    return AchievementModel(
      achievementId: '',
      achievementTitle: '',
      description: '',
      achievementType: '',
      imagePath: '',
      levels: [],
      isActive: false,
      createdAt: DateTime(0),
    );
  }

  /// Convert model to JSON structure for storing data in Firebase
  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.achievementId: achievementId,
      FirebaseFieldNames.achievementTitle: achievementTitle,
      FirebaseFieldNames.description: description,
      FirebaseFieldNames.achievementType: achievementType,
      FirebaseFieldNames.imagePath: imagePath,
      FirebaseFieldNames.levels: levels.map((e) => e.toJson()).toList(),
      FirebaseFieldNames.isActive: isActive,
      FirebaseFieldNames.createdAt: Timestamp.fromDate(createdAt),
    };
  }

  /// Factory method to create an AchievementModel from a Firebase document snapshot
  factory AchievementModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    if (document.data() != null) {
      final data = document.data()!;
      return AchievementModel(
        achievementId: data[FirebaseFieldNames.achievementId] ?? '',
        achievementTitle: data[FirebaseFieldNames.achievementTitle] ?? '',
        description: data[FirebaseFieldNames.description] ?? '',
        achievementType: data[FirebaseFieldNames.achievementType] ?? '',
        imagePath: data[FirebaseFieldNames.imagePath] ?? '',
        levels: (data[FirebaseFieldNames.levels] as List<dynamic>?)
            ?.map((e) => AchievementLevelModel.fromMap(e as Map<String, dynamic>))
            .toList() ?? [],
        isActive: data[FirebaseFieldNames.isActive] ?? false,
        createdAt: (data[FirebaseFieldNames.createdAt] as Timestamp).toDate(),
      );
    } else {
      return AchievementModel.empty();
    }
  }
}
