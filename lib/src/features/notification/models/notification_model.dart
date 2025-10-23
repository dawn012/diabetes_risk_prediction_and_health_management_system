import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/constants/firebase_field_names.dart';

class NotificationModel {
  final String notificationId;
  final String notificationType;
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
      notificationType: '',
      notificationTitle: '',
      message: '',
      isRead: false,
      createdAt: DateTime(0),
    );
  }

  /// Creates a copy of the current NotificationModel with the given fields replaced
  NotificationModel copyWith({
    String? notificationId,
    String? notificationType,
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
      FirebaseFieldNames.notificationType: notificationType,
      FirebaseFieldNames.notificationTitle: notificationTitle,
      FirebaseFieldNames.message: message,
      FirebaseFieldNames.isRead: isRead,
      FirebaseFieldNames.createdAt: Timestamp.fromDate(createdAt),
    };
  }

  /// Factory method to create a NotificationModel from a Firebase document snapshot
  factory NotificationModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    if (document.data() != null) {
      final data = document.data()!;
      return NotificationModel(
        notificationId: data[FirebaseFieldNames.notificationId] ?? '',
        notificationType: data[FirebaseFieldNames.notificationType] ?? '',
        notificationTitle: data[FirebaseFieldNames.notificationTitle] ?? '',
        message: data[FirebaseFieldNames.message] ?? '',
        isRead: data[FirebaseFieldNames.isRead] ?? false,
        createdAt: (data[FirebaseFieldNames.createdAt] as Timestamp).toDate(),
      );
    } else {
      return NotificationModel.empty();
    }
  }
}
