// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_preference_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MealPreferenceModelAdapter extends TypeAdapter<MealPreferenceModel> {
  @override
  final int typeId = 5;

  @override
  MealPreferenceModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MealPreferenceModel(
      dietPreference: fields[0] as DietPreference?,
      allergens: (fields[1] as List).cast<Allergen>(),
      preferredCookingMethods: (fields[2] as List).cast<CookingMethod>(),
      maxPreparationTime: fields[3] as int,
      planType: fields[4] as MealPlanType,
      updatedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MealPreferenceModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.dietPreference)
      ..writeByte(1)
      ..write(obj.allergens)
      ..writeByte(2)
      ..write(obj.preferredCookingMethods)
      ..writeByte(3)
      ..write(obj.maxPreparationTime)
      ..writeByte(4)
      ..write(obj.planType)
      ..writeByte(5)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealPreferenceModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
