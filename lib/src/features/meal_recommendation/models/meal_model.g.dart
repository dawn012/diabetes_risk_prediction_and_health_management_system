// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MealModelAdapter extends TypeAdapter<MealModel> {
  @override
  final int typeId = 15;

  @override
  MealModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MealModel(
      mealId: fields[0] as String,
      mealName: fields[1] as String,
      mealDescription: fields[2] as String,
      imageUrl: fields[3] as String,
      ingredients: (fields[4] as List).cast<String>(),
      preparationTime: fields[5] as int,
      cookingTime: fields[6] as int,
      nutrient: fields[7] as NutrientModel,
      instructions: (fields[8] as List).cast<String>(),
      serves: fields[9] as int,
      dishType: (fields[10] as List).cast<String>(),
      dietaryRestrictions: (fields[11] as List).cast<String>(),
      dietType: (fields[12] as List).cast<String>(),
      cookingMethod: (fields[13] as List).cast<CookingMethod>(),
      authorName: fields[14] as String,
      notes: (fields[15] as List?)?.cast<String>(),
      sourceUrl: fields[16] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MealModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.mealId)
      ..writeByte(1)
      ..write(obj.mealName)
      ..writeByte(2)
      ..write(obj.mealDescription)
      ..writeByte(3)
      ..write(obj.imageUrl)
      ..writeByte(4)
      ..write(obj.ingredients)
      ..writeByte(5)
      ..write(obj.preparationTime)
      ..writeByte(6)
      ..write(obj.cookingTime)
      ..writeByte(7)
      ..write(obj.nutrient)
      ..writeByte(8)
      ..write(obj.instructions)
      ..writeByte(9)
      ..write(obj.serves)
      ..writeByte(10)
      ..write(obj.dishType)
      ..writeByte(11)
      ..write(obj.dietaryRestrictions)
      ..writeByte(12)
      ..write(obj.dietType)
      ..writeByte(13)
      ..write(obj.cookingMethod)
      ..writeByte(14)
      ..write(obj.authorName)
      ..writeByte(15)
      ..write(obj.notes)
      ..writeByte(16)
      ..write(obj.sourceUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
