// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_analysis_result_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MealAnalysisResultAdapter extends TypeAdapter<MealAnalysisResult> {
  @override
  final int typeId = 3;

  @override
  MealAnalysisResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MealAnalysisResult(
      id: fields[0] as String,
      mealNumber: fields[1] as int,
      foods: (fields[2] as List).cast<DetectedFood>(),
      totalGL: fields[3] as double,
      glCategory: fields[4] as String,
      error: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MealAnalysisResult obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.mealNumber)
      ..writeByte(2)
      ..write(obj.foods)
      ..writeByte(3)
      ..write(obj.totalGL)
      ..writeByte(4)
      ..write(obj.glCategory)
      ..writeByte(5)
      ..write(obj.error);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealAnalysisResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
