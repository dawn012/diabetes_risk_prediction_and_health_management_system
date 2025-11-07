// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_photo_record_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MealPhotoRecordAdapter extends TypeAdapter<MealPhotoRecord> {
  @override
  final int typeId = 1;

  @override
  MealPhotoRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MealPhotoRecord(
      id: fields[0] as String,
      localPath: fields[1] as String,
      fileSize: fields[2] as int,
      uploadTime: fields[3] as DateTime,
      needsProcessing: fields[4] as bool,
      analysisResult: fields[5] as MealAnalysisResult?,
    );
  }

  @override
  void write(BinaryWriter writer, MealPhotoRecord obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.localPath)
      ..writeByte(2)
      ..write(obj.fileSize)
      ..writeByte(3)
      ..write(obj.uploadTime)
      ..writeByte(4)
      ..write(obj.needsProcessing)
      ..writeByte(5)
      ..write(obj.analysisResult);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealPhotoRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
