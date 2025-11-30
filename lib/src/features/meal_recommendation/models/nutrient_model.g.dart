// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nutrient_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NutrientModelAdapter extends TypeAdapter<NutrientModel> {
  @override
  final int typeId = 16;

  @override
  NutrientModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NutrientModel(
      calories: fields[0] as double,
      protein: fields[1] as double,
      fat: fields[2] as double,
      saturatedFat: fields[3] as double,
      carbohydrates: fields[4] as double,
      fiber: fields[5] as double,
      sugar: fields[6] as double,
      sodium: fields[7] as double,
      cholesterol: fields[8] as double,
    );
  }

  @override
  void write(BinaryWriter writer, NutrientModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.calories)
      ..writeByte(1)
      ..write(obj.protein)
      ..writeByte(2)
      ..write(obj.fat)
      ..writeByte(3)
      ..write(obj.saturatedFat)
      ..writeByte(4)
      ..write(obj.carbohydrates)
      ..writeByte(5)
      ..write(obj.fiber)
      ..writeByte(6)
      ..write(obj.sugar)
      ..writeByte(7)
      ..write(obj.sodium)
      ..writeByte(8)
      ..write(obj.cholesterol);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NutrientModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
