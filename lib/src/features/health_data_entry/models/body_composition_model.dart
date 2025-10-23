import '../../../utils/constants/firebase_field_names.dart';

class BodyCompositionModel {
  final double weight; // kg
  final double bodyFat; // cm

  BodyCompositionModel({
    required this.weight,
    required this.bodyFat,
  });

  static BodyCompositionModel empty() {
    return BodyCompositionModel(
      weight: 0,
      bodyFat: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.weight: weight,
      FirebaseFieldNames.bodyFat: bodyFat,
    };
  }

  factory BodyCompositionModel.fromJson(Map<String, dynamic> map) {
    return BodyCompositionModel(
      weight: (map[FirebaseFieldNames.weight] as num?)?.toDouble() ?? 0.0,
      bodyFat: (map[FirebaseFieldNames.bodyFat] as num?)?.toDouble() ?? 0.0,
    );
  }
}
