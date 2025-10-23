import '../../../utils/constants/firebase_field_names.dart';

class BloodPressureModel {
  final int systolic;
  final int diastolic;
  final int pulse;

  BloodPressureModel({
    required this.systolic,
    required this.diastolic,
    required this.pulse,
  });

  static BloodPressureModel empty() {
    return BloodPressureModel(
      systolic: 0,
      diastolic: 0,
      pulse: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.systolic: systolic,
      FirebaseFieldNames.diastolic: diastolic,
      FirebaseFieldNames.pulse: pulse,
    };
  }

  factory BloodPressureModel.fromJson(Map<String, dynamic> map) {
    return BloodPressureModel(
      systolic: map[FirebaseFieldNames.systolic] as int,
      diastolic: map[FirebaseFieldNames.diastolic] as int,
      pulse: map[FirebaseFieldNames.pulse] as int,
    );
  }
}
