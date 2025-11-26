import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../../utils/constants/enums.dart';
import '../../../utils/constants/firebase_field_names.dart';
import 'meal_model.dart';

part 'meal_plan_meal_model.g.dart';

@HiveType(typeId: 7)
class MealPlanMealModel extends HiveObject {
  @HiveField(0)
  final String mealPlanMealId;

  @HiveField(1)
  final MealModel meal;

  @HiveField(2)
  final DateTime scheduledDate;

  @HiveField(3)
  final MealTimeSlot mealTimeSlot;

  @HiveField(4)
  final MealConsumptionStatus status;

  MealPlanMealModel({
    required this.mealPlanMealId,
    required this.meal,
    required this.scheduledDate,
    required this.mealTimeSlot,
    required this.status,
  });

  static MealPlanMealModel empty() {
    return MealPlanMealModel(
      mealPlanMealId: '',
      meal: MealModel.empty(),
      scheduledDate: DateTime.now(),
      mealTimeSlot: MealTimeSlot.breakfast,
      status: MealConsumptionStatus.pending,
    );
  }

  MealPlanMealModel copyWith({
    String? mealPlanMealId,
    MealModel? meal,
    DateTime? scheduledDate,
    MealTimeSlot? mealTimeSlot,
    MealConsumptionStatus? status,
  }) {
    return MealPlanMealModel(
      mealPlanMealId: mealPlanMealId ?? this.mealPlanMealId,
      meal: meal ?? this.meal,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      mealTimeSlot: mealTimeSlot ?? this.mealTimeSlot,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.mealPlanMealId: mealPlanMealId,
      FirebaseFieldNames.scheduledDate: scheduledDate.millisecondsSinceEpoch,
      FirebaseFieldNames.mealTimeSlot: mealTimeSlot.value,
      FirebaseFieldNames.status: status.value,
    };
  }

  factory MealPlanMealModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return MealPlanMealModel.empty();

    return MealPlanMealModel(
      mealPlanMealId: data[FirebaseFieldNames.mealPlanMealId] ?? '',
      meal: MealModel.empty(),
      scheduledDate: data[FirebaseFieldNames.scheduledDate] != null
          ? DateTime.fromMillisecondsSinceEpoch(data[FirebaseFieldNames.scheduledDate])
          : DateTime.now(),
      mealTimeSlot: MealTimeSlot.fromString(data[FirebaseFieldNames.mealTimeSlot] ?? 'breakfast'),
      status: MealConsumptionStatus.fromString(data[FirebaseFieldNames.status] ?? 'pending'),
    );
  }

  // Helper methods
  bool get isConsumed => status == MealConsumptionStatus.consumed;
  bool get isSkipped => status == MealConsumptionStatus.skipped;
  bool get isPending => status == MealConsumptionStatus.pending;

  String get mealTimeSlotDisplay => mealTimeSlot.value.capitalizeFirst!;
  String get statusDisplay => status.value.capitalizeFirst!;

  // Additional helper methods
  bool isScheduledForDate(DateTime date) {
    return scheduledDate.year == date.year &&
        scheduledDate.month == date.month &&
        scheduledDate.day == date.day;
  }

  bool isScheduledForDateTime(DateTime dateTime) {
    return scheduledDate.year == dateTime.year &&
        scheduledDate.month == dateTime.month &&
        scheduledDate.day == dateTime.day &&
        mealTimeSlot == _getMealTimeSlotFromTime(dateTime);
  }

  MealTimeSlot _getMealTimeSlotFromTime(DateTime dateTime) {
    final hour = dateTime.hour;
    if (hour >= 6 && hour < 10) return MealTimeSlot.breakfast;
    if (hour >= 12 && hour < 14) return MealTimeSlot.lunch;
    if (hour >= 18 && hour < 21) return MealTimeSlot.dinner;
    return MealTimeSlot.snack;
  }

  DateTime get scheduledDateTime {
    return DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      _getHourForMealTimeSlot(mealTimeSlot),
    );
  }

  int _getHourForMealTimeSlot(MealTimeSlot slot) {
    switch (slot) {
      case MealTimeSlot.breakfast:
        return 8; // 8 AM
      case MealTimeSlot.lunch:
        return 13; // 1 PM
      case MealTimeSlot.dinner:
        return 19; // 7 PM
      case MealTimeSlot.snack:
        return 15; // 3 PM
    }
  }

  bool get isOverdue {
    if (isConsumed || isSkipped) return false;
    return DateTime.now().isAfter(scheduledDateTime);
  }

  Duration get timeUntilScheduled {
    return scheduledDateTime.difference(DateTime.now());
  }

  bool get canBeConsumed {
    return isPending && !isOverdue;
  }

  bool get canBeSkipped {
    return isPending;
  }
}