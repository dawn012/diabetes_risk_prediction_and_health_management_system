import '../../../utils/constants/firebase_field_names.dart';

class BloodGlucoseModel {
  final double glucoseLevel;

  BloodGlucoseModel({
    required this.glucoseLevel,
  });

  static BloodGlucoseModel empty() {
    return BloodGlucoseModel(
      glucoseLevel: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.glucoseLevel: glucoseLevel,
    };
  }

  factory BloodGlucoseModel.fromJson(Map<String, dynamic> map) {
    return BloodGlucoseModel(
      glucoseLevel: (map[FirebaseFieldNames.glucoseLevel] as num?)?.toDouble() ?? 0.0,
    );
  }
}
