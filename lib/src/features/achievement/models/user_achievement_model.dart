import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/constants/enums.dart';
import '../../../utils/constants/firebase_field_names.dart';
import 'achievement_model.dart';

/// Makeup history entry
class MakeupHistoryEntry {
  final String dateKey;
  final String logId;
  final int timestamp;

  const MakeupHistoryEntry({
    required this.dateKey,
    required this.logId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'logId': logId,
      'timestamp': timestamp,
    };
  }

  factory MakeupHistoryEntry.fromJson(Map<String, dynamic> json) {
    return MakeupHistoryEntry(
      dateKey: json['dateKey'] ?? '',
      logId: json['logId'] ?? '',
      timestamp: json['timestamp'] ?? 0,
    );
  }

  @override
  String toString() => 'MakeupHistoryEntry(dateKey: $dateKey, logId: $logId)';
}

class UserAchievementModel {
  final String userAchievementId;
  final String userId;
  final AchievementModel achievement;
  final UserAchievementLevel currentLevel;
  final int currentCount;
  final AchievementStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<MakeupHistoryEntry> makeupHistory;
  final int makeupUsed;

  const UserAchievementModel({
    required this.userAchievementId,
    required this.userId,
    required this.achievement,
    required this.currentLevel,
    required this.currentCount,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.makeupHistory = const [],
    this.makeupUsed = 0,
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
      makeupHistory: const [],
      makeupUsed: 0,
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
    List<MakeupHistoryEntry>? makeupHistory,
    int? makeupUsed,
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
      makeupHistory: makeupHistory ?? this.makeupHistory,
      makeupUsed: makeupUsed ?? this.makeupUsed,
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
      if (makeupHistory.isNotEmpty)
        'makeupHistory': makeupHistory.map((e) => e.toJson()).toList(),
      'makeupUsed': makeupUsed,
    };
  }

  /// Factory method to create a UserAchievementModel from a Firebase document snapshot
  factory UserAchievementModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    if (data == null) return UserAchievementModel.empty();

    // Parse makeup history
    List<MakeupHistoryEntry> makeupHistory = [];
    if (data['makeupHistory'] != null) {
      final historyList = data['makeupHistory'] as List;
      makeupHistory = historyList
          .map((item) => MakeupHistoryEntry.fromJson(item as Map<String, dynamic>))
          .toList();
    }

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
      makeupHistory: makeupHistory,
      makeupUsed: data['makeupUsed'] ?? 0,
    );
  }

  /// Check if a specific log ID is a makeup
  bool isMakeupLog(String logId) {
    return makeupHistory.any((entry) => entry.logId == logId);
  }

  @override
  String toString() {
    return 'UserAchievementModel{userAchievementId: $userAchievementId, userId: $userId, achievement: ${achievement.achievementTitle}, currentLevel: ${currentLevel.displayName}, status: ${status.displayName}, makeupUsed: $makeupUsed}';
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