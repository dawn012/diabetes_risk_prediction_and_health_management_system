import '../../../utils/constants/enums.dart';
import '../../../utils/constants/firebase_field_names.dart';

class PhysicalActivityModel {
  final String activityType;
  final int duration;
  final IntensityLevel intensityLevel;

  PhysicalActivityModel({
    required this.activityType,
    required this.duration,
    required this.intensityLevel,
  });

  static PhysicalActivityModel empty() {
    return PhysicalActivityModel(
      activityType: '',
      duration: 0,
      intensityLevel: IntensityLevel.moderate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.activityType: activityType,
      FirebaseFieldNames.duration: duration,
      FirebaseFieldNames.intensityLevel: intensityLevel.value,
    };
  }

  factory PhysicalActivityModel.fromJson(Map<String, dynamic> map) {
    return PhysicalActivityModel(
      activityType: map[FirebaseFieldNames.activityType] ?? '',
      duration: map[FirebaseFieldNames.duration] ?? 0,
      intensityLevel: IntensityLevel.fromString(
          map[FirebaseFieldNames.intensityLevel] ?? 'moderate'),
    );
  }
}