// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diabetes_assessment_cache_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DiabetesAssessmentCacheAdapter
    extends TypeAdapter<DiabetesAssessmentCache> {
  @override
  final int typeId = 0;

  @override
  DiabetesAssessmentCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DiabetesAssessmentCache(
      height: fields[0] as double?,
      weight: fields[1] as double?,
      bloodGlucose: fields[2] as double?,
      glucoseUnit: fields[3] as String?,
      physicalActivityDuration: fields[4] as int?,
      stressLevel: fields[5] as int?,
      sleepDuration: fields[6] as double?,
      waterIntake: fields[7] as double?,
      takesMedication: fields[8] as bool?,
      medicationAdherence: fields[9] as int?,
      mealPhotos: (fields[10] as List?)?.cast<MealPhotoRecord>(),
      mealPhotosProcessed: fields[11] as bool?,
      dietAssessment: fields[12] as DietAssessmentReport?,
      currentStep: fields[13] as int,
      lastUpdated: fields[14] as DateTime,
      completedSteps: (fields[15] as Map?)?.cast<int, bool>(),
      isComplete: fields[16] as bool,
      isFirstTime: fields[17] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DiabetesAssessmentCache obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.height)
      ..writeByte(1)
      ..write(obj.weight)
      ..writeByte(2)
      ..write(obj.bloodGlucose)
      ..writeByte(3)
      ..write(obj.glucoseUnit)
      ..writeByte(4)
      ..write(obj.physicalActivityDuration)
      ..writeByte(5)
      ..write(obj.stressLevel)
      ..writeByte(6)
      ..write(obj.sleepDuration)
      ..writeByte(7)
      ..write(obj.waterIntake)
      ..writeByte(8)
      ..write(obj.takesMedication)
      ..writeByte(9)
      ..write(obj.medicationAdherence)
      ..writeByte(10)
      ..write(obj.mealPhotos)
      ..writeByte(11)
      ..write(obj.mealPhotosProcessed)
      ..writeByte(12)
      ..write(obj.dietAssessment)
      ..writeByte(13)
      ..write(obj.currentStep)
      ..writeByte(14)
      ..write(obj.lastUpdated)
      ..writeByte(15)
      ..write(obj.completedSteps)
      ..writeByte(16)
      ..write(obj.isComplete)
      ..writeByte(17)
      ..write(obj.isFirstTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiabetesAssessmentCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
