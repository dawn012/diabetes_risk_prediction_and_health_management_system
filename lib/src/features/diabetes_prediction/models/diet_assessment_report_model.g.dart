// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diet_assessment_report_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DietAssessmentReportAdapter extends TypeAdapter<DietAssessmentReport> {
  @override
  final int typeId = 2;

  @override
  DietAssessmentReport read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DietAssessmentReport(
      meals: (fields[0] as List).cast<MealAnalysisResult>(),
      avgGLPerMeal: fields[1] as double,
      isHealthy: fields[2] as bool,
      warnings: (fields[3] as List).cast<String>(),
      mealCount: fields[4] as int,
      glThresholds: (fields[5] as Map).cast<String, int>(),
      assessmentDate: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DietAssessmentReport obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.meals)
      ..writeByte(1)
      ..write(obj.avgGLPerMeal)
      ..writeByte(2)
      ..write(obj.isHealthy)
      ..writeByte(3)
      ..write(obj.warnings)
      ..writeByte(4)
      ..write(obj.mealCount)
      ..writeByte(5)
      ..write(obj.glThresholds)
      ..writeByte(6)
      ..write(obj.assessmentDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DietAssessmentReportAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
