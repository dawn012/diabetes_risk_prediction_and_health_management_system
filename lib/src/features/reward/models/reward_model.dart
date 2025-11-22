import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/constants/enums.dart';
import '../../../utils/constants/firebase_field_names.dart';

class RewardModel {
  final String rewardId;
  final RewardType rewardType;
  final String title;
  final String description;
  final String icon;
  final int costPoints;
  final int? availableQuantity;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  RewardModel({
    required this.rewardId,
    required this.rewardType,
    required this.title,
    required this.description,
    required this.icon,
    required this.costPoints,
    this.availableQuantity,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Empty
  static RewardModel empty() {
    return RewardModel(
      rewardId: '',
      rewardType: RewardType.avatarFrame,
      title: '',
      description: '',
      icon: '',
      costPoints: 0,
      availableQuantity: 0,
      isActive: false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.rewardId: rewardId,
      FirebaseFieldNames.rewardType: rewardType.name,
      FirebaseFieldNames.title: title,
      FirebaseFieldNames.description: description,
      FirebaseFieldNames.icon: icon,
      FirebaseFieldNames.costPoints: costPoints,
      FirebaseFieldNames.availableQuantity: availableQuantity,
      FirebaseFieldNames.isActive: isActive,
      FirebaseFieldNames.createdAt: createdAt.millisecondsSinceEpoch,
      FirebaseFieldNames.updatedAt: updatedAt.millisecondsSinceEpoch,
    };
  }

  /// From Snapshot
  factory RewardModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    if (data == null) return RewardModel.empty();

    return RewardModel(
      rewardId: data[FirebaseFieldNames.rewardId] ?? '',
      rewardType: RewardType.values.firstWhere(
            (e) => e.name == (data[FirebaseFieldNames.rewardType] ?? 'avatarFrame'),
        orElse: () => RewardType.avatarFrame,
      ),
      title: data[FirebaseFieldNames.title] ?? '',
      description: data[FirebaseFieldNames.description] ?? '',
      icon: data[FirebaseFieldNames.icon] ?? '',
      costPoints: (data[FirebaseFieldNames.costPoints] ?? 0).toInt(),
      availableQuantity: data[FirebaseFieldNames.availableQuantity]?.toInt(),
      isActive: data[FirebaseFieldNames.isActive] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          data[FirebaseFieldNames.createdAt] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
          data[FirebaseFieldNames.updatedAt] ?? 0),
    );
  }

  /// From Map (useful for nested docs)
  factory RewardModel.fromMap(Map<String, dynamic> data) {
    return RewardModel(
      rewardId: data[FirebaseFieldNames.rewardId] ?? '',
      rewardType: RewardType.values.firstWhere(
            (e) => e.name == (data[FirebaseFieldNames.rewardType] ?? 'avatarFrame'),
        orElse: () => RewardType.avatarFrame,
      ),
      title: data[FirebaseFieldNames.title] ?? '',
      description: data[FirebaseFieldNames.description] ?? '',
      icon: data[FirebaseFieldNames.icon] ?? '',
      costPoints: (data[FirebaseFieldNames.costPoints] ?? 0).toInt(),
      availableQuantity: data[FirebaseFieldNames.availableQuantity]?.toInt(),
      isActive: data[FirebaseFieldNames.isActive] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          data[FirebaseFieldNames.createdAt] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
          data[FirebaseFieldNames.updatedAt] ?? 0),
    );
  }

  /// Copy with
  RewardModel copyWith({
    String? rewardId,
    RewardType? rewardType,
    String? title,
    String? description,
    String? icon,
    int? costPoints,
    int? availableQuantity,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RewardModel(
      rewardId: rewardId ?? this.rewardId,
      rewardType: rewardType ?? this.rewardType,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      costPoints: costPoints ?? this.costPoints,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
