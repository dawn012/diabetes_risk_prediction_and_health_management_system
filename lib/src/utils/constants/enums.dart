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

enum RankChange {
  up,
  down,
  same,
  new_entry,
}

/// 媒体选项类型
enum MediaOptionType {
  gallery,
  camera,
  video,
}

/// Health Data Type Enum
enum HealthDataType {
  bloodGlucose,
  bloodPressure,
  bodyComposition,
  physicalActivity,
  diabetesRisk,
}

/// Health Level Enum
enum HealthLevel {
  low,
  normal,
  elevated,
  high,
  invalid
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

/// Achievement type enum
enum AchievementType {
  periodic('periodic', 'Periodic'),
  permanent('permanent', 'Permanent');

  final String value;
  final String displayName;

  const AchievementType(this.value, this.displayName);

  static AchievementType fromString(String value) {
    return AchievementType.values.firstWhere(
          (e) => e.value == value.toLowerCase(),
      orElse: () => AchievementType.periodic,
    );
  }
}

/// Achievement level enum
enum AchievementLevel {
  bronze('bronze', 'Bronze'),
  silver('silver', 'Silver'),
  gold('gold', 'Gold');

  final String value;
  final String displayName;

  const AchievementLevel(this.value, this.displayName);

  static AchievementLevel fromString(String value) {
    return AchievementLevel.values.firstWhere(
          (e) => e.value == value.toLowerCase(),
      orElse: () => AchievementLevel.bronze,
    );
  }
}

/// User achievement current level (includes none)
enum UserAchievementLevel {
  none('none', 'None'),
  bronze('bronze', 'Bronze'),
  silver('silver', 'Silver'),
  gold('gold', 'Gold');

  final String value;
  final String displayName;

  const UserAchievementLevel(this.value, this.displayName);

  static UserAchievementLevel fromString(String value) {
    return UserAchievementLevel.values.firstWhere(
          (e) => e.value == value.toLowerCase(),
      orElse: () => UserAchievementLevel.none,
    );
  }
}

/// User achievement status enum
enum AchievementStatus {
  inProgress('in progress', 'In Progress'),
  completed('completed', 'Completed');

  final String value;
  final String displayName;

  const AchievementStatus(this.value, this.displayName);

  static AchievementStatus fromString(String value) {
    return AchievementStatus.values.firstWhere(
          (e) => e.value == value.toLowerCase(),
      orElse: () => AchievementStatus.inProgress,
    );
  }
}

/// Payment transaction status
enum PaymentStatus {
  succeeded('succeeded', 'Succeeded'),
  failed('failed', 'Failed'),
  pending('pending', 'Pending');

  final String value;
  final String displayName;

  const PaymentStatus(this.value, this.displayName);

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
          (e) => e.value == value.toLowerCase(),
      orElse: () => PaymentStatus.pending,
    );
  }
}

/// User subscription status
enum SubscriptionStatus {
  active('active', 'Active'),
  pending('pending', 'Pending'),
  failed('failed', 'Failed'),
  expired('expired', 'Expired'),
  cancelled('cancelled', 'Cancelled');

  final String value;
  final String displayName;

  const SubscriptionStatus(this.value, this.displayName);

  static SubscriptionStatus fromString(String value) {
    return SubscriptionStatus.values.firstWhere(
          (e) => e.value == value.toLowerCase(),
      orElse: () => SubscriptionStatus.active,
    );
  }

  Color get color {
    switch (this) {
      case SubscriptionStatus.active:
        return TColors.success;
      case SubscriptionStatus.pending:
        return TColors.info;
      case SubscriptionStatus.expired:
        return TColors.warning;
      case SubscriptionStatus.failed:
        return TColors.error;
      case SubscriptionStatus.cancelled:
        return TColors.darkGrey;
    }
  }
}