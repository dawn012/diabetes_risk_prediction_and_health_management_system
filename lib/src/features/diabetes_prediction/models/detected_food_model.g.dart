// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detected_food_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DetectedFoodAdapter extends TypeAdapter<DetectedFood> {
  @override
  final int typeId = 4;

  @override
  DetectedFood read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DetectedFood(
      name: fields[0] as String,
      calories: fields[1] as double,
      carbs: fields[2] as double,
      protein: fields[3] as double,
      fat: fields[4] as double,
      fiber: fields[5] as double,
      sugar: fields[6] as double,
      sodium: fields[7] as double,
      saturatedFat: fields[8] as double,
      giValue: fields[9] as int?,
      glycemicLoad: fields[10] as double?,
      glCategory: fields[11] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DetectedFood obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.calories)
      ..writeByte(2)
      ..write(obj.carbs)
      ..writeByte(3)
      ..write(obj.protein)
      ..writeByte(4)
      ..write(obj.fat)
      ..writeByte(5)
      ..write(obj.fiber)
      ..writeByte(6)
      ..write(obj.sugar)
      ..writeByte(7)
      ..write(obj.sodium)
      ..writeByte(8)
      ..write(obj.saturatedFat)
      ..writeByte(9)
      ..write(obj.giValue)
      ..writeByte(10)
      ..write(obj.glycemicLoad)
      ..writeByte(11)
      ..write(obj.glCategory);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DetectedFoodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
