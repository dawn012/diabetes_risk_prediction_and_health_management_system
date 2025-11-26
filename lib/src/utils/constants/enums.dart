// List of Enums
// They cannot be created inside a class

import 'dart:ui';

import 'package:hive/hive.dart';

import 'colors.dart';

part 'enums.g.dart';

enum TextSizes { small, medium, large }

enum PaymentMethods { paypal, visa, masterCard, creditCard }

enum ChartType { line, bar }

enum ReportPeriod { monthly, yearly }

enum ExportFormat { pdf, csv }

enum NotificationType { reminder, system, delete_account_request, account_status }

/// Request status enum
enum RequestStatus {
  pending,
  approved,
  rejected,
  expired,
}

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

enum RewardType {
  avatarFrame('avatar frame'),
  virtualItem('virtual item'),
  coupon('coupon');

  final String value;

  const RewardType(this.value);

  static RewardType fromString(String value) {
    // 处理不同的格式
    final normalizedValue = value.toLowerCase().trim();

    return RewardType.values.firstWhere(
          (e) => e.value == normalizedValue || e.name.toLowerCase() == normalizedValue,
      orElse: () => RewardType.avatarFrame,
    );
  }

  String get displayName {
    switch (this) {
      case RewardType.avatarFrame:
        return 'Avatar Frame';
      case RewardType.virtualItem:
        return 'Virtual Item';
      case RewardType.coupon:
        return 'Coupon';
    }
  }
}

/// User Reward Status
enum UserRewardStatus {
  pending('pending'),
  redeemed('redeemed');

  final String value;

  const UserRewardStatus(this.value);

  static UserRewardStatus fromString(String value) {
    return UserRewardStatus.values.firstWhere(
          (e) => e.value == value.toLowerCase(),
      orElse: () => UserRewardStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case UserRewardStatus.pending:
        return 'Pending';
      case UserRewardStatus.redeemed:
        return 'Redeemed';
    }
  }

  Color get color {
    switch (this) {
      case UserRewardStatus.pending:
        return TColors.warning;
      case UserRewardStatus.redeemed:
        return TColors.success;
    }
  }
}

/// 饮食偏好类型
@HiveType(typeId: 8)
enum DietPreference {
  @HiveField(0)
  vegan('vegan', 'Vegan'),
  @HiveField(1)
  vegetarian('vegetarian', 'Vegetarian'),
  @HiveField(2)
  paleo('paleo', 'Paleo'),
  @HiveField(3)
  whole30('whole30', 'Whole30');

  final String value;
  final String displayName;

  const DietPreference(this.value, this.displayName);

  static DietPreference fromString(String value) {
    return DietPreference.values.firstWhere(
          (e) => e.value == value.toLowerCase(),
      orElse: () => DietPreference.vegan, // 默认值
    );
  }
}

/// 过敏原类型
@HiveType(typeId: 9)
enum Allergen {
  @HiveField(0)
  egg('egg', 'Egg'),
  @HiveField(1)
  dairy('dairy', 'Dairy'),
  @HiveField(2)
  gluten('gluten', 'Gluten'),
  @HiveField(3)
  nut('nut', 'Nut'),
  @HiveField(4)
  grain('grain', 'Grain');

  final String value;
  final String displayName;

  const Allergen(this.value, this.displayName);

  static Allergen fromString(String value) {
    return Allergen.values.firstWhere(
          (e) => e.value == value.toLowerCase(),
      orElse: () => Allergen.egg, // 默认值
    );
  }
}

/// 烹饪方法
@HiveType(typeId: 10)
enum CookingMethod {
  @HiveField(0)
  airFryer('air-fryer', 'Air Fryer'),
  @HiveField(1)
  blender('blender', 'Blender'),
  @HiveField(2)
  grill('grill', 'Grill'),
  @HiveField(3)
  instantPot('instant-pot', 'Instant Pot'),
  @HiveField(4)
  mealPrep('meal-prep', 'Meal Prep'),
  @HiveField(5)
  noBake('no-bake', 'No-Bake'),
  @HiveField(6)
  oven('oven', 'Oven'),
  @HiveField(7)
  slowCooker('slow-cooker', 'Slow Cooker'),
  @HiveField(8)
  smoker('smoker', 'Smoker'),
  @HiveField(9)
  stovetop('stovetop', 'Stovetop'),
  @HiveField(10)
  foodProcessor('food-processor', 'Food Processor'),
  @HiveField(11)
  noCook('no-cook', 'No-Cook'),
  @HiveField(12)
  microwave('microwave', 'Microwave'),
  @HiveField(13)
  sheetPan('sheet-pan', 'Sheet Pan');

  final String value;
  final String displayName;

  const CookingMethod(this.value, this.displayName);

  static CookingMethod fromString(String value) {
    return CookingMethod.values.firstWhere(
          (e) => e.value == value.toLowerCase(),
      orElse: () => CookingMethod.oven, // 默认值
    );
  }
}

@HiveType(typeId: 11)
enum MealPlanType {
  @HiveField(0)
  daily('daily'),
  @HiveField(1)
  weekly('weekly');

  final String value;
  const MealPlanType(this.value);

  static MealPlanType fromString(String value) {
    return MealPlanType.values.firstWhere(
          (e) => e.value == value,
      orElse: () => MealPlanType.daily,
    );
  }
}

@HiveType(typeId: 12)
enum MealPlanStatus {
  @HiveField(0)
  confirmed('confirmed'),
  @HiveField(1)
  completed('completed'),
  @HiveField(2)
  cancelled('cancelled'),
  @HiveField(3)
  expired('expired');

  final String value;
  const MealPlanStatus(this.value);

  static MealPlanStatus fromString(String value) {
    return MealPlanStatus.values.firstWhere(
          (e) => e.value == value,
      orElse: () => MealPlanStatus.confirmed,
    );
  }
}

@HiveType(typeId: 13)
enum MealTimeSlot {
  @HiveField(0)
  breakfast('breakfast'),
  @HiveField(1)
  lunch('lunch'),
  @HiveField(2)
  snack('snack'),
  @HiveField(3)
  dinner('dinner');

  final String value;
  const MealTimeSlot(this.value);

  static MealTimeSlot fromString(String value) {
    return MealTimeSlot.values.firstWhere(
          (e) => e.value == value,
      orElse: () => MealTimeSlot.breakfast,
    );
  }
}

@HiveType(typeId: 14)
enum MealConsumptionStatus {
  @HiveField(0)
  pending('pending'),
  @HiveField(1)
  consumed('consumed'),
  @HiveField(2)
  skipped('skipped');

  final String value;
  const MealConsumptionStatus(this.value);

  static MealConsumptionStatus fromString(String value) {
    return MealConsumptionStatus.values.firstWhere(
          (e) => e.value == value,
      orElse: () => MealConsumptionStatus.pending,
    );
  }
}

/// Report reason enum
enum ReportReason {
  spam('spam', 'Spam'),
  harassment('harassment', 'Harassment'),
  fraud('fraud', 'Fraud'),
  inappropriate('inappropriate', 'Inappropriate Content'),
  misinformation('misinformation', 'Misinformation'),
  other('other', 'Other');

  final String value;
  final String displayName;

  const ReportReason(this.value, this.displayName);

  static ReportReason fromString(String value) {
    return ReportReason.values.firstWhere(
          (e) => e.value == value.toLowerCase(),
      orElse: () => ReportReason.other,
    );
  }
}

/// Report status enum
enum ReportStatus {
  pending('pending', 'Pending'),
  resolved('resolved', 'Resolved');

  final String value;
  final String displayName;

  const ReportStatus(this.value, this.displayName);

  static ReportStatus fromString(String value) {
    return ReportStatus.values.firstWhere(
          (e) => e.value == value.toLowerCase(),
      orElse: () => ReportStatus.pending,
    );
  }
}