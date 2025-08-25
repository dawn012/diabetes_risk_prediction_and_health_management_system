import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/constants/firebase_field_names.dart';

class ReminderScheduleModel {
  final String scheduleId;
  final DateTime triggerTime;
  final DateTime originalTime;
  final int snoozeCount;
  final String status;

  ReminderScheduleModel({
    required this.scheduleId,
    required this.triggerTime,
    required this.originalTime,
    required this.snoozeCount,
    required this.status
  });

  /// Static function to create an empty reminder schedule model
  static ReminderScheduleModel empty() {
    return ReminderScheduleModel(
      scheduleId: '',
      triggerTime: DateTime(0),
      originalTime: DateTime(0),
      snoozeCount: 0,
      status: '',
    );
  }

  /// Convert model to JSON structure for storing in Firebase
  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.scheduleId: scheduleId,
      FirebaseFieldNames.triggerTime: Timestamp.fromDate(triggerTime),
      FirebaseFieldNames.originalTime: Timestamp.fromDate(originalTime),
      FirebaseFieldNames.snoozeCount: snoozeCount,
      FirebaseFieldNames.status: status,
    };
  }

  /// Create model instance from Firestore DocumentSnapshot
  factory ReminderScheduleModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    if (document.data() != null) {
      final data = document.data()!;
      return ReminderScheduleModel(
        scheduleId: data[FirebaseFieldNames.scheduleId] ?? '',
        triggerTime: (data[FirebaseFieldNames.triggerTime] as Timestamp).toDate(),
        originalTime: (data[FirebaseFieldNames.originalTime] as Timestamp).toDate(),
        snoozeCount: data[FirebaseFieldNames.snoozeCount] ?? 0,
        status: data[FirebaseFieldNames.status] ?? '',
      );
    } else {
      return ReminderScheduleModel.empty();
    }
  }
}
