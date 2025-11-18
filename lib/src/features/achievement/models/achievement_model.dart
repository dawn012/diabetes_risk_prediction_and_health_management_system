import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../utils/constants/enums.dart';
import '../../../utils/constants/firebase_field_names.dart';
import 'achievement_level_model.dart';

class AchievementModel {
  final String achievementId;
  final String achievementTitle;
  final String description;
  final AchievementType achievementType;
  final List<AchievementLevelModel> levels;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int iconCodePoint;

  const AchievementModel({
    required this.achievementId,
    required this.achievementTitle,
    required this.description,
    required this.achievementType,
    required this.levels,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.iconCodePoint = 0xf01a, // Icons.emoji_events.codePoint
  });

  /// 获取 IconData
  IconData get iconData => IconData(
      iconCodePoint,
      fontFamily: 'MaterialIcons',
      fontPackage: null
  );

  /// Static function to create an empty achievement model
  static AchievementModel empty() {
    return AchievementModel(
      achievementId: '',
      achievementTitle: '',
      description: '',
      achievementType: AchievementType.periodic,
      levels: [],
      isActive: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      iconCodePoint: Icons.emoji_events_outlined.codePoint,
    );
  }

  /// Create a copy with updated fields
  AchievementModel copyWith({
    String? achievementId,
    String? achievementTitle,
    String? description,
    AchievementType? achievementType,
    List<AchievementLevelModel>? levels,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? iconCodePoint,
  }) {
    return AchievementModel(
      achievementId: achievementId ?? this.achievementId,
      achievementTitle: achievementTitle ?? this.achievementTitle,
      description: description ?? this.description,
      achievementType: achievementType ?? this.achievementType,
      levels: levels ?? this.levels,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
    );
  }

  /// Convert model to JSON structure for storing data in Firebase
  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.achievementId: achievementId,
      FirebaseFieldNames.achievementTitle: achievementTitle,
      FirebaseFieldNames.description: description,
      FirebaseFieldNames.achievementType: achievementType.value,
      FirebaseFieldNames.levels: levels.map((e) => e.toJson()).toList(),
      FirebaseFieldNames.isActive: isActive,
      FirebaseFieldNames.createdAt: createdAt.millisecondsSinceEpoch,
      FirebaseFieldNames.updatedAt: updatedAt.millisecondsSinceEpoch,
      FirebaseFieldNames.iconCodePoint: iconCodePoint,
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
        achievementType: AchievementType.fromString(
            data[FirebaseFieldNames.achievementType] ?? 'periodic'),
        levels: (data[FirebaseFieldNames.levels] as List<dynamic>?)
            ?.map((e) => AchievementLevelModel.fromMap(e as Map<String, dynamic>))
            .toList() ??
            [],
        isActive: data[FirebaseFieldNames.isActive] ?? false,
        createdAt: data[FirebaseFieldNames.createdAt] != null
            ? DateTime.fromMillisecondsSinceEpoch(
            data[FirebaseFieldNames.createdAt])
            : DateTime.now(),
        updatedAt: data[FirebaseFieldNames.updatedAt] != null
            ? DateTime.fromMillisecondsSinceEpoch(
            data[FirebaseFieldNames.updatedAt])
            : DateTime.now(),
        iconCodePoint: data[FirebaseFieldNames.iconCodePoint] ?? Icons.emoji_events.codePoint,
      );
    } else {
      return AchievementModel.empty();
    }
  }

  @override
  String toString() {
    return 'AchievementModel{achievementId: $achievementId, title: $achievementTitle, type: ${achievementType.displayName}}';
  }
}