import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/constants/firebase_field_names.dart';
import 'reminder_schedule_model.dart';

class ReminderModel {
  final String reminderId;
  final String reminderTitle;
  final DateTime baseTime;
  final String repeatType;
  final List<String> customDays;
  int? intervalTime;
  final DateTime endDate;
  final DateTime nextTriggerTime;
  final int snoozeDuration;
  final List<ReminderScheduleModel> reminderSchedules;
  final bool isActive;

  ReminderModel({
    required this.reminderId,
    required this.reminderTitle,
    required this.baseTime,
    required this.repeatType,
    required this.customDays,
    this.intervalTime,
    required this.endDate,
    required this.nextTriggerTime,
    required this.snoozeDuration,
    required this.reminderSchedules,
    required this.isActive
  });

  ReminderModel copyWith({
    String? reminderId,
    String? reminderTitle,
    DateTime? baseTime,
    String? repeatType,
    List<String>? customDays,
    int? intervalTime,
    DateTime? endDate,
    DateTime? nextTriggerTime,
    int? snoozeDuration,
    List<ReminderScheduleModel>? reminderSchedules,
    bool? isActive,
  }) {
    return ReminderModel(
      reminderId: reminderId ?? this.reminderId,
      reminderTitle: reminderTitle ?? this.reminderTitle,
      baseTime: baseTime ?? this.baseTime,
      repeatType: repeatType ?? this.repeatType,
      customDays: customDays ?? this.customDays,
      intervalTime: intervalTime ?? this.intervalTime,
      endDate: endDate ?? this.endDate,
      nextTriggerTime: nextTriggerTime ?? this.nextTriggerTime,
      snoozeDuration: snoozeDuration ?? this.snoozeDuration,
      reminderSchedules: reminderSchedules ?? this.reminderSchedules,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Static function to create an empty reminder model
  static ReminderModel empty() {
    return ReminderModel(
      reminderId: '',
      reminderTitle: '',
      baseTime: DateTime(0),
      repeatType: '',
      customDays: [],
      intervalTime: 0,
      endDate: DateTime(0),
      nextTriggerTime: DateTime(0),
      snoozeDuration: 0,
      reminderSchedules: [],
      isActive: false,
    );
  }

  /// Convert model to JSON structure for storing data in Firebase
  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.reminderId: reminderId,
      FirebaseFieldNames.reminderTitle: reminderTitle,
      FirebaseFieldNames.baseTime: Timestamp.fromDate(baseTime),  // Convert to Timestamp to store in firebase
      FirebaseFieldNames.repeatType: repeatType,
      FirebaseFieldNames.customDays: customDays,
      FirebaseFieldNames.intervalTime: intervalTime,
      FirebaseFieldNames.endDate: Timestamp.fromDate(endDate),
      FirebaseFieldNames.nextTriggerTime: Timestamp.fromDate(nextTriggerTime),
      FirebaseFieldNames.snoozeDuration: snoozeDuration,
      FirebaseFieldNames.isActive: isActive,
    };
  }

  /// Factory method to create a ReminderModel from a Firebase document snapshot
  /// 工厂构造方法允许返回已经存在的实例或根据逻辑创建新的实例
  factory ReminderModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    if (document.data() != null) {
      final data = document.data()!;
      return ReminderModel(
        reminderId: data[FirebaseFieldNames.reminderId] ?? '',
        reminderTitle: data[FirebaseFieldNames.reminderTitle] ?? '',
        baseTime: (data[FirebaseFieldNames.baseTime] as Timestamp).toDate(),  // Convert to DateTime
        repeatType: data[FirebaseFieldNames.repeatType] ?? '',
        customDays: List<String>.from(data[FirebaseFieldNames.customDays] ?? []),
        intervalTime: data[FirebaseFieldNames.intervalTime] ?? 0,
        endDate: (data[FirebaseFieldNames.endDate] as Timestamp).toDate(),
        nextTriggerTime: (data[FirebaseFieldNames.nextTriggerTime] as Timestamp).toDate(),
        snoozeDuration: data[FirebaseFieldNames.snoozeDuration] ?? 0,
        reminderSchedules: [], // 如果你有子对象可以 map to ReminderScheduleModel
        isActive: data[FirebaseFieldNames.isActive] ?? false,
      );
    } else {
      return ReminderModel.empty();
    }
  }
}
