import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/constants/enums.dart';
import '../../../utils/constants/firebase_field_names.dart';
import 'reminder_schedule_model.dart';

class ReminderModel {
  final String reminderId;
  final String reminderTitle;
  final DateTime baseTime;
  final RepeatType repeatType;
  final List<String> customDays;
  int? intervalTime;
  DateTime? endDate;
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
    this.endDate,
    required this.nextTriggerTime,
    required this.snoozeDuration,
    required this.reminderSchedules,
    required this.isActive
  });

  ReminderModel copyWith({
    String? reminderId,
    String? reminderTitle,
    DateTime? baseTime,
    RepeatType? repeatType,
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
      repeatType: RepeatType.once,
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
      FirebaseFieldNames.baseTime: Timestamp.fromDate(baseTime),
      // Convert to Timestamp to store in firebase
      FirebaseFieldNames.repeatType: repeatType.value,
      FirebaseFieldNames.customDays: customDays,
      FirebaseFieldNames.intervalTime: intervalTime,
      FirebaseFieldNames.endDate: endDate != null
          ? Timestamp.fromDate(endDate!)
          : null,
      FirebaseFieldNames.nextTriggerTime: Timestamp.fromDate(nextTriggerTime),
      FirebaseFieldNames.snoozeDuration: snoozeDuration,
      FirebaseFieldNames.isActive: isActive,
    };
  }

  /// Factory method to create a ReminderModel from a Firebase document snapshot
  /// 工厂构造方法允许返回已经存在的实例或根据逻辑创建新的实例
  factory ReminderModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    if (!document.exists || document.data() == null) {
      return ReminderModel.empty();
    }

    final data = document.data()!;

    // 统一处理 Timestamp 到 DateTime 的转换
    DateTime? _parseTimestamp(dynamic timestamp) {
      if (timestamp == null) return null;
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      }
      return null;
    }

    final baseTime = _parseTimestamp(data[FirebaseFieldNames.baseTime]) ??
        DateTime.fromMillisecondsSinceEpoch(0);

    final nextTriggerTime = _parseTimestamp(data[FirebaseFieldNames.nextTriggerTime]) ??
        DateTime.fromMillisecondsSinceEpoch(0);

    print("Base time: $baseTime");
    print("Next Trigger: $nextTriggerTime");

    // 🔧 修复 endDate 处理
    DateTime? endDate;
    final endDateTimestamp = data[FirebaseFieldNames.endDate];

    if (endDateTimestamp != null && endDateTimestamp is Timestamp) {
      endDate = endDateTimestamp.toDate();

      // 检查是否是占位符（2099年）
      if (endDate.year == 2099) {
        endDate = null;
      }
    }

    return ReminderModel(
      reminderId: data[FirebaseFieldNames.reminderId] ?? '',
      reminderTitle: data[FirebaseFieldNames.reminderTitle] ?? '',
      baseTime: baseTime,
      nextTriggerTime: nextTriggerTime,
      repeatType: RepeatType.fromString(data[FirebaseFieldNames.repeatType] ?? ''),
      customDays: List<String>.from(data[FirebaseFieldNames.customDays] ?? []),
      intervalTime: data[FirebaseFieldNames.intervalTime] ?? 0,
      endDate: endDate,
      snoozeDuration: data[FirebaseFieldNames.snoozeDuration] ?? 0,
      reminderSchedules: [],
      isActive: data[FirebaseFieldNames.isActive] ?? false,
    );
  }
}
