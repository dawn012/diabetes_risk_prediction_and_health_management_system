import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../../utils/constants/enums.dart';
import '../../../utils/constants/firebase_field_names.dart';
import 'meal_plan_meal_model.dart';

part 'meal_plan_model.g.dart';

@HiveType(typeId: 6)
class MealPlanModel extends HiveObject {
  @HiveField(0)
  final String mealPlanId;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final List<MealPlanMealModel> scheduledMeals;

  @HiveField(3)
  final MealPlanType planType;

  @HiveField(4)
  final DateTime startDateTime;

  @HiveField(5)
  final DateTime endDateTime;

  @HiveField(6)
  final int adherence;

  @HiveField(7)
  final MealPlanStatus status;

  MealPlanModel({
    required this.mealPlanId,
    required this.userId,
    required this.scheduledMeals,
    required this.planType,
    required this.startDateTime,
    required this.endDateTime,
    required this.adherence,
    required this.status,
  });

  static MealPlanModel empty() {
    return MealPlanModel(
      mealPlanId: '',
      userId: '',
      scheduledMeals: [],
      planType: MealPlanType.daily,
      startDateTime: DateTime.now(),
      endDateTime: DateTime.now(),
      adherence: 0,
      status: MealPlanStatus.confirmed,
    );
  }

  MealPlanModel copyWith({
    String? mealPlanId,
    String? userId,
    List<MealPlanMealModel>? scheduledMeals,
    MealPlanType? planType,
    DateTime? startDateTime,
    DateTime? endDateTime,
    int? adherence,
    MealPlanStatus? status,
  }) {
    return MealPlanModel(
      mealPlanId: mealPlanId ?? this.mealPlanId,
      userId: userId ?? this.userId,
      scheduledMeals: scheduledMeals ?? this.scheduledMeals,
      planType: planType ?? this.planType,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      adherence: adherence ?? this.adherence,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.mealPlanId: mealPlanId,
      FirebaseFieldNames.userId: userId,
      FirebaseFieldNames.planType: planType.value,
      FirebaseFieldNames.startDateTime: startDateTime.millisecondsSinceEpoch,
      FirebaseFieldNames.endDateTime: endDateTime.millisecondsSinceEpoch,
      FirebaseFieldNames.adherence: adherence,
      FirebaseFieldNames.status: status.value,
    };
  }

  factory MealPlanModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return MealPlanModel.empty();

    return MealPlanModel(
      mealPlanId: data[FirebaseFieldNames.mealPlanId] ?? '',
      userId: data[FirebaseFieldNames.userId] ?? '',
      scheduledMeals: [],
      planType: MealPlanType.fromString(data[FirebaseFieldNames.planType] ?? 'daily'),
      startDateTime: data[FirebaseFieldNames.startDateTime] != null
          ? DateTime.fromMillisecondsSinceEpoch(data[FirebaseFieldNames.startDateTime])
          : DateTime.now(),
      endDateTime: data[FirebaseFieldNames.endDateTime] != null
          ? DateTime.fromMillisecondsSinceEpoch(data[FirebaseFieldNames.endDateTime])
          : DateTime.now(),
      adherence: data[FirebaseFieldNames.adherence] ?? 0,
      status: MealPlanStatus.fromString(data[FirebaseFieldNames.status] ?? 'confirmed'),
    );
  }

  // Helper methods
  bool get hasScheduledMeals => scheduledMeals.isNotEmpty;
  bool get isCompleted => status == MealPlanStatus.completed;
  bool get isExpired => status == MealPlanStatus.expired;
  bool get isActive => status == MealPlanStatus.confirmed;
  bool get isCancelled => status == MealPlanStatus.cancelled;

  String get planTypeDisplay => planType.value.capitalizeFirst!;
  String get statusDisplay => status.value.capitalizeFirst!;

  // Additional helper methods
  int get totalMeals => scheduledMeals.length;

  int get consumedMeals => scheduledMeals.where((meal) => meal.isConsumed).length;

  int get skippedMeals => scheduledMeals.where((meal) => meal.isSkipped).length;

  int get pendingMeals => scheduledMeals.where((meal) => meal.isPending).length;

  double get completionRate {
    if (scheduledMeals.isEmpty) return 0.0;
    return consumedMeals / scheduledMeals.length;
  }

  bool get isWithinDateRange {
    final now = DateTime.now();
    return now.isAfter(startDateTime) && now.isBefore(endDateTime);
  }

  bool get hasEnded => DateTime.now().isAfter(endDateTime);

  List<MealPlanMealModel> getMealsForDate(DateTime date) {
    return scheduledMeals.where((meal) =>
    meal.scheduledDate.year == date.year &&
        meal.scheduledDate.month == date.month &&
        meal.scheduledDate.day == date.day
    ).toList();
  }

  List<MealPlanMealModel> getMealsForTimeSlot(MealTimeSlot timeSlot) {
    return scheduledMeals.where((meal) => meal.mealTimeSlot == timeSlot).toList();
  }
}