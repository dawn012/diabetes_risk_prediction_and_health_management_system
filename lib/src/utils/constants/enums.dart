// List of Enums
// They cannot be created inside a class

import 'dart:ui';

import 'colors.dart';

enum TextSizes { small, medium, large }

enum PaymentMethods { paypal, visa, masterCard, creditCard }

enum ChartType { line, bar }

enum ReportPeriod { monthly, yearly }

enum ExportFormat { pdf, csv }

enum ReportStatus { loading, success, error, empty }

enum NotificationType { reminder, system, }

enum BatchActionType {
  disable,
  enable,
  ban,
  restore,
  delete,
}

enum PostType {
  general('General Discussion'),
  tips('Tips & Tricks'),
  recipe('Meal or Recipe'),
  story('Success Story');

  final String displayName;

  const PostType(this.displayName);

  static PostType fromDisplayName(String displayName) {
    return values.firstWhere(
          (type) => type.displayName == displayName,
      orElse: () => PostType.general,
    );
  }

  // 颜色方法
  Color get color {
    switch (this) {
      case PostType.tips:
        return TColors.warning;
      case PostType.recipe:
        return TColors.success;
      case PostType.story:
        return TColors.info;
      default:
        return TColors.primary;
    }
  }

  // 短标签方法
  String get shortLabel {
    switch (this) {
      case PostType.general:
        return 'General';
      case PostType.tips:
        return 'Tips';
      case PostType.recipe:
        return 'Recipe';
      case PostType.story:
        return 'Story';
      default:
        return name.toUpperCase();
    }
  }
}

/// Enums for Reminder System
enum RepeatType {
  once('once'),
  customDays('custom days'),
  fixedInterval('fixed interval');

  final String value;
  const RepeatType(this.value);

  static RepeatType fromString(String value) {
    return RepeatType.values.firstWhere(
          (e) => e.value == value.toLowerCase(),
      orElse: () => RepeatType.once,
    );
  }

  String get displayName {
    switch (this) {
      case RepeatType.once:
        return 'Once';
      case RepeatType.customDays:
        return 'Custom';
      case RepeatType.fixedInterval:
        return 'Fixed Interval';
    }
  }
}

enum ScheduleStatus {
  pending('pending'),
  triggered('triggered'),
  snoozed('snoozed'),
  dismissed('dismissed');

  final String value;
  const ScheduleStatus(this.value);

  static ScheduleStatus fromString(String value) {
    return ScheduleStatus.values.firstWhere(
          (e) => e.value == value.toLowerCase(),
      orElse: () => ScheduleStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case ScheduleStatus.pending:
        return 'Pending';
      case ScheduleStatus.triggered:
        return 'Triggered';
      case ScheduleStatus.snoozed:
        return 'Snoozed';
      case ScheduleStatus.dismissed:
        return 'Dismissed';
    }
  }
}

/// Physiological time period enum
enum PhysiologicalTimePeriod {
  wakeUp('wake-up', 'Wake-up'),
  beforeBreakfast('before breakfast', 'Before Breakfast'),
  afterBreakfast('after breakfast', 'After Breakfast'),
  beforeLunch('before lunch', 'Before Lunch'),
  afterLunch('after lunch', 'After Lunch'),
  beforeDinner('before dinner', 'Before Dinner'),
  afterDinner('after dinner', 'After Dinner'),
  beforeSnack('before snack', 'Before Snack'),
  afterSnack('after snack', 'After Snack'),
  beforeExercise('before exercise', 'Before Exercise'),
  afterExercise('after exercise', 'After Exercise'),
  bedtime('bedtime', 'Bedtime'),
  others('others', 'Others');

  final String value;
  final String displayName;

  const PhysiologicalTimePeriod(this.value, this.displayName);

  static PhysiologicalTimePeriod fromString(String value) {
    return PhysiologicalTimePeriod.values.firstWhere(
          (e) => e.value == value.toLowerCase(),
      orElse: () => PhysiologicalTimePeriod.beforeBreakfast,
    );
  }

  // 添加静态方法获取所有显示名称（包含 "All"）
  static List<String> getAllDisplayNames() {
    return [
      'All',
      ...values.map((e) => e.displayName).toList(),
    ];
  }

  // 添加静态方法获取不包含 "All" 的显示名称
  static List<String> getDisplayNames() {
    return values.map((e) => e.displayName).toList();
  }
}

/// Physical activity intensity level enum
enum IntensityLevel {
  low('low', 'Low'),
  moderate('moderate', 'Moderate'),
  high('high', 'High');

  final String value;
  final String displayName;

  const IntensityLevel(this.value, this.displayName);

  static IntensityLevel fromString(String value) {
    return IntensityLevel.values.firstWhere(
          (e) => e.value == value.toLowerCase(),
      orElse: () => IntensityLevel.moderate,
    );
  }
}