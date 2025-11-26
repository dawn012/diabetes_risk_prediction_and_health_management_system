// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_plan_meal_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MealPlanMealModelAdapter extends TypeAdapter<MealPlanMealModel> {
  @override
  final int typeId = 7;

  @override
  MealPlanMealModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MealPlanMealModel(
      mealPlanMealId: fields[0] as String,
      meal: fields[1] as MealModel,
      scheduledDate: fields[2] as DateTime,
      mealTimeSlot: fields[3] as MealTimeSlot,
      status: fields[4] as MealConsumptionStatus,
    );
  }

  @override
  void write(BinaryWriter writer, MealPlanMealModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.mealPlanMealId)
      ..writeByte(1)
      ..write(obj.meal)
      ..writeByte(2)
      ..write(obj.scheduledDate)
      ..writeByte(3)
      ..write(obj.mealTimeSlot)
      ..writeByte(4)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealPlanMealModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
