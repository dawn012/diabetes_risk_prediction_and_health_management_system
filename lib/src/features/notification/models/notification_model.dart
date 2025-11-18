import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/constants/enums.dart';
import '../../../utils/constants/firebase_field_names.dart';

class NotificationModel {
  final String notificationId;
  final NotificationType notificationType;
  final String notificationTitle;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.notificationId,
    required this.notificationType,
    required this.notificationTitle,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  /// Empty notification (placeholder)
  static NotificationModel empty() {
    return NotificationModel(
      notificationId: '',
      notificationType: NotificationType.system,
      notificationTitle: '',
      message: '',
      isRead: false,
      createdAt: DateTime(0),
    );
  }

  /// Creates a copy of the current NotificationModel with the given fields replaced
  NotificationModel copyWith({
    String? notificationId,
    NotificationType? notificationType,
    String? notificationTitle,
    String? message,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      notificationId: notificationId ?? this.notificationId,
      notificationType: notificationType ?? this.notificationType,
      notificationTitle: notificationTitle ?? this.notificationTitle,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert model to JSON structure for storing data in Firebase
  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.notificationId: notificationId,
      FirebaseFieldNames.notificationType: notificationType.name,
      FirebaseFieldNames.notificationTitle: notificationTitle,
      FirebaseFieldNames.message: message,
      FirebaseFieldNames.isRead: isRead,
      FirebaseFieldNames.createdAt: createdAt.millisecondsSinceEpoch,
    };
  }

  /// Factory method to create a NotificationModel from a Firebase document snapshot
  factory NotificationModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    if (document.data() != null) {
      final data = document.data()!;

      return NotificationModel(
        notificationId: data[FirebaseFieldNames.notificationId] ?? '',
        notificationType: _parseNotificationType(data[FirebaseFieldNames.notificationType]),
        notificationTitle: data[FirebaseFieldNames.notificationTitle] ?? '',
        message: data[FirebaseFieldNames.message] ?? '',
        isRead: data[FirebaseFieldNames.isRead] ?? false,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            data[FirebaseFieldNames.createdAt] ?? 0),
      );
    } else {
      return NotificationModel.empty();
    }
  }

// 辅助方法：将字符串转换为 NotificationType
  static NotificationType _parseNotificationType(String? typeString) {
    if (typeString == null) return NotificationType.system;

    try {
      return NotificationType.values.firstWhere(
            (type) => type.name == typeString,
        orElse: () => NotificationType.system,
      );
    } catch (e) {
      return NotificationType.system;
    }
  }
}
