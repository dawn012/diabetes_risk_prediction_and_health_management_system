import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/constants/enums.dart';
import '../../../utils/constants/firebase_field_names.dart';
import 'reward_model.dart';

class UserRewardModel {
  final String userId;
  final RewardModel reward;
  final int pointsSpent;
  final DateTime redeemedAt;
  final UserRewardStatus status;
  final String? notes;

  UserRewardModel({
    required this.userId,
    required this.reward,
    required this.pointsSpent,
    required this.redeemedAt,
    required this.status,
    this.notes,
  });

  /// Empty
  static UserRewardModel empty() {
    return UserRewardModel(
      userId: '',
      reward: RewardModel.empty(),
      pointsSpent: 0,
      redeemedAt: DateTime.fromMillisecondsSinceEpoch(0),
      status: UserRewardStatus.pending,
      notes: null,
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.userId: userId,
      FirebaseFieldNames.rewardId: reward.rewardId,
      FirebaseFieldNames.pointsSpent: pointsSpent,
      FirebaseFieldNames.redeemedAt: redeemedAt.millisecondsSinceEpoch,
      FirebaseFieldNames.status: status.name,
      FirebaseFieldNames.notes: notes,
    };
  }

  /// From Snapshot
  factory UserRewardModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document,
      {RewardModel? rewardObj}) {
    final data = document.data();
    if (data == null) return UserRewardModel.empty();

    return UserRewardModel(
      userId: data[FirebaseFieldNames.userId] ?? '',
      reward: rewardObj ?? RewardModel.empty(),
      pointsSpent: (data[FirebaseFieldNames.pointsSpent] ?? 0).toInt(),
      redeemedAt: DateTime.fromMillisecondsSinceEpoch(
          data[FirebaseFieldNames.redeemedAt] ?? 0),
      status: UserRewardStatus.values.firstWhere(
              (e) => e.name == (data[FirebaseFieldNames.status] ?? 'pending'),
          orElse: () => UserRewardStatus.pending),
      notes: data[FirebaseFieldNames.notes],
    );
  }

  /// From Map (useful for nested docs)
  factory UserRewardModel.fromMap(Map<String, dynamic> data,
      {RewardModel? rewardObj}) {
    return UserRewardModel(
      userId: data[FirebaseFieldNames.userId] ?? '',
      reward: rewardObj ?? RewardModel.empty(),
      pointsSpent: (data[FirebaseFieldNames.pointsSpent] ?? 0).toInt(),
      redeemedAt: DateTime.fromMillisecondsSinceEpoch(
          data[FirebaseFieldNames.redeemedAt] ?? 0),
      status: UserRewardStatus.values.firstWhere(
              (e) => e.name == (data[FirebaseFieldNames.status] ?? 'pending'),
          orElse: () => UserRewardStatus.pending),
      notes: data[FirebaseFieldNames.notes],
    );
  }

  /// Copy with
  UserRewardModel copyWith({
    String? userId,
    RewardModel? reward,
    int? pointsSpent,
    DateTime? redeemedAt,
    UserRewardStatus? status,
    String? notes,
  }) {
    return UserRewardModel(
      userId: userId ?? this.userId,
      reward: reward ?? this.reward,
      pointsSpent: pointsSpent ?? this.pointsSpent,
      redeemedAt: redeemedAt ?? this.redeemedAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
