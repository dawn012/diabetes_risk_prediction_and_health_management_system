import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/constants/enums.dart';
import '../../../utils/constants/firebase_field_names.dart';
import 'achievement_model.dart';

class UserAchievementModel {
  final String userAchievementId;
  final String userId;
  final AchievementModel achievement;
  final UserAchievementLevel currentLevel;
  final int currentCount;
  final AchievementStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;

  const UserAchievementModel({
    required this.userAchievementId,
    required this.userId,
    required this.achievement,
    required this.currentLevel,
    required this.currentCount,
    required this.status,
    required this.startedAt,
    this.completedAt,
  });

  /// Static function to create an empty user achievement model
  static UserAchievementModel empty() {
    return UserAchievementModel(
      userAchievementId: '',
      userId: '',
      achievement: AchievementModel.empty(),
      currentLevel: UserAchievementLevel.none,
      currentCount: 0,
      status: AchievementStatus.inProgress,
      startedAt: DateTime.now(),
      completedAt: null,
    );
  }

  /// Create a copy with updated fields
  UserAchievementModel copyWith({
    String? userAchievementId,
    String? userId,
    AchievementModel? achievement,
    UserAchievementLevel? currentLevel,
    int? currentCount,
    AchievementStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return UserAchievementModel(
      userAchievementId: userAchievementId ?? this.userAchievementId,
      userId: userId ?? this.userId,
      achievement: achievement ?? this.achievement,
      currentLevel: currentLevel ?? this.currentLevel,
      currentCount: currentCount ?? this.currentCount,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Convert model to JSON structure for storing data in Firebase
  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.userAchievementId: userAchievementId,
      FirebaseFieldNames.userId: userId,
      FirebaseFieldNames.achievementId: achievement.achievementId,
      FirebaseFieldNames.currentLevel: currentLevel.value,
      FirebaseFieldNames.currentCount: currentCount,
      FirebaseFieldNames.status: status.value,
      FirebaseFieldNames.startedAt: startedAt.millisecondsSinceEpoch,
      if (completedAt != null)
        FirebaseFieldNames.completedAt: completedAt!.millisecondsSinceEpoch,
    };
  }

  /// Factory method to create a UserAchievementModel from a Firebase document snapshot
  factory UserAchievementModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    if (data == null) return UserAchievementModel.empty();

    // 注意：这里需要从其他地方获取完整的 AchievementModel
    // 在实际使用中，你可能需要在 Repository 层处理这个逻辑
    return UserAchievementModel(
      userAchievementId: data[FirebaseFieldNames.userAchievementId] ?? document.id,
      userId: data[FirebaseFieldNames.userId] ?? '',
      achievement: AchievementModel.empty(), // 需要后续填充
      currentLevel: UserAchievementLevel.fromString(
        data[FirebaseFieldNames.currentLevel] ?? 'none',
      ),
      currentCount: data[FirebaseFieldNames.currentCount] ?? 0,
      status: AchievementStatus.fromString(
        data[FirebaseFieldNames.status] ?? 'in progress',
      ),
      startedAt: data[FirebaseFieldNames.startedAt] != null
          ? DateTime.fromMillisecondsSinceEpoch(
          data[FirebaseFieldNames.startedAt])
          : DateTime.now(),
      completedAt: data[FirebaseFieldNames.completedAt] != null
          ? DateTime.fromMillisecondsSinceEpoch(
          data[FirebaseFieldNames.completedAt])
          : null,
    );
  }

  @override
  String toString() {
    return 'UserAchievementModel{userAchievementId: $userAchievementId, userId: $userId, achievement: ${achievement.achievementTitle}, currentLevel: ${currentLevel.displayName}, status: ${status.displayName}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserAchievementModel &&
        other.userAchievementId == userAchievementId;
  }

  @override
  int get hashCode => userAchievementId.hashCode;
}