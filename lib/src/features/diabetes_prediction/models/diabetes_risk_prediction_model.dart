import 'package:cloud_firestore/cloud_firestore.dart';
import 'diabetes_assessment_cache_model.dart';
import 'diet_assessment_report_model.dart';
import 'meal_analysis_result_model.dart';
import 'meal_photo_record_model.dart';
import 'detected_food_model.dart';
import '../../../utils/constants/firebase_field_names.dart';

class DiabetesRiskPredictionModel {
  final String predictionId;
  final DateTime predictionDateTime;
  final String riskLevel; // 'low', 'medium', 'high'
  final double riskScore; // 0.0 - 1.0 or 0-100
  final List<String> recommendations;

  // 复用 DiabetesAssessmentCache 作为输入数据
  final DiabetesAssessmentCache inputs;

  DiabetesRiskPredictionModel({
    required this.predictionId,
    required this.predictionDateTime,
    required this.riskLevel,
    required this.riskScore,
    required this.recommendations,
    required this.inputs,
  });

  /// Empty constructor for initialization
  factory DiabetesRiskPredictionModel.empty() => DiabetesRiskPredictionModel(
    predictionId: '',
    predictionDateTime: DateTime.fromMillisecondsSinceEpoch(0),
    riskLevel: '',
    riskScore: 0.0,
    recommendations: const [],
    inputs: DiabetesAssessmentCache.empty(),
  );

  /// Create a copy of the model with updated fields
  DiabetesRiskPredictionModel copyWith({
    String? predictionId,
    String? userId,
    DateTime? predictionDateTime,
    String? riskLevel,
    double? riskScore,
    List<String>? recommendations,
    DiabetesAssessmentCache? inputs,
  }) {
    return DiabetesRiskPredictionModel(
      predictionId: predictionId ?? this.predictionId,
      predictionDateTime: predictionDateTime ?? this.predictionDateTime,
      riskLevel: riskLevel ?? this.riskLevel,
      riskScore: riskScore ?? this.riskScore,
      recommendations: recommendations ?? this.recommendations,
      inputs: inputs ?? this.inputs,
    );
  }

  /// Convert model to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.predictionId: predictionId,
      FirebaseFieldNames.predictionDateTime: predictionDateTime.millisecondsSinceEpoch,
      FirebaseFieldNames.riskLevel: riskLevel,
      FirebaseFieldNames.riskScore: riskScore,
      FirebaseFieldNames.recommendations: recommendations,
      'inputs': _convertCacheToFirestore(inputs),
    };
  }

  /// Create model from Firestore document snapshot
  factory DiabetesRiskPredictionModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? {};
    return DiabetesRiskPredictionModel.fromJson(data);
  }

  /// Create model from JSON data
  factory DiabetesRiskPredictionModel.fromJson(Map<String, dynamic> json) {
    return DiabetesRiskPredictionModel(
      predictionId: json[FirebaseFieldNames.predictionId] ?? '',
      predictionDateTime: DateTime.fromMillisecondsSinceEpoch(
        json[FirebaseFieldNames.predictionDateTime] ?? 0,
      ),
      riskLevel: json[FirebaseFieldNames.riskLevel] ?? '',
      riskScore: (json[FirebaseFieldNames.riskScore] ?? 0).toDouble(),
      recommendations: List<String>.from(json[FirebaseFieldNames.recommendations] ?? []),
      inputs: _convertFirestoreToCache(json['inputs'] ?? {}),
    );
  }

  // 转换 Hive Cache 为 Firestore 友好的格式 - 包含完整的 food 数据
  static Map<String, dynamic> _convertCacheToFirestore(DiabetesAssessmentCache cache) {
    return {
      // 基础健康数据
      FirebaseFieldNames.height: cache.height,
      FirebaseFieldNames.weight: cache.weight,
      'bloodGlucose': cache.bloodGlucose,
      'glucoseUnit': cache.glucoseUnit,

      // 生活方式数据
      'physicalActivityDuration': cache.physicalActivityDuration,
      FirebaseFieldNames.stressLevel: cache.stressLevel,
      FirebaseFieldNames.sleepDuration: cache.sleepDuration,
      FirebaseFieldNames.waterIntake: cache.waterIntake,

      // 用药情况
      FirebaseFieldNames.isTakeMedication: cache.takesMedication,
      FirebaseFieldNames.medicationAdherence: cache.medicationAdherence,

      // 餐食照片信息（包含 analysisResult 和完整的 foods 数据）
      'mealPhotos': _convertMealPhotosForFirestore(cache.mealPhotos),
      'mealPhotosProcessed': cache.mealPhotosProcessed,

      // 饮食评估结果
      'dietAssessment': _convertDietAssessmentForFirestore(cache.dietAssessment),
    };
  }

  // 从 Firestore 数据重建 Cache 对象
  static DiabetesAssessmentCache _convertFirestoreToCache(Map<String, dynamic> data) {
    final mealPhotos = _convertFirestoreToMealPhotos(data['mealPhotos'] ?? []);

    return DiabetesAssessmentCache(
      height: data[FirebaseFieldNames.height]?.toDouble(),
      weight: data[FirebaseFieldNames.weight]?.toDouble(),
      bloodGlucose: data['bloodGlucose']?.toDouble(),
      glucoseUnit: data['glucoseUnit'] ?? 'mmol/L',
      physicalActivityDuration: data['physicalActivityDuration'],
      stressLevel: data[FirebaseFieldNames.stressLevel],
      sleepDuration: data[FirebaseFieldNames.sleepDuration]?.toDouble(),
      waterIntake: data[FirebaseFieldNames.waterIntake]?.toDouble(),
      takesMedication: data[FirebaseFieldNames.isTakeMedication],
      medicationAdherence: data[FirebaseFieldNames.medicationAdherence],
      mealPhotos: mealPhotos,
      mealPhotosProcessed: data['mealPhotosProcessed'],
      dietAssessment: _convertFirestoreToDietAssessment(data['dietAssessment'], mealPhotos),
      lastUpdated: DateTime.now(),
    );
  }

  // 转换餐食照片为 Firestore 格式
  static List<Map<String, dynamic>> _convertMealPhotosForFirestore(List<MealPhotoRecord>? photos) {
    if (photos == null) return [];

    return photos.map((photo) {
      return {
        'id': photo.id,
        'imagePath': photo.imagePath,
        'uploadTime': photo.uploadTime.millisecondsSinceEpoch,
        'needsProcessing': photo.needsProcessing,
        'isFromCloud': true,
        'analysisResult': _convertAnalysisResultForFirestore(photo.analysisResult),
      };
    }).toList();
  }

  // 从 Firestore 重建餐食照片
  static List<MealPhotoRecord> _convertFirestoreToMealPhotos(List<dynamic> photosData) {
    return photosData.map((data) {
      final photoData = data as Map<String, dynamic>;
      return MealPhotoRecord.createFromCloud(
        id: photoData['id'] ?? '',
        storageUrl: photoData['imagePath'],
        uploadTime: DateTime.fromMillisecondsSinceEpoch(photoData['uploadTime'] ?? 0),
        analysisResult: _convertFirestoreToAnalysisResult(photoData['analysisResult']),
      );
    }).toList();
  }

  // 转换分析结果为 Firestore 格式 - 包含完整的 foods 数组
  static Map<String, dynamic>? _convertAnalysisResultForFirestore(MealAnalysisResult? result) {
    if (result == null) return null;

    return {
      'id': result.id,
      'mealNumber': result.mealNumber,
      'totalGL': result.totalGL,
      'glCategory': result.glCategory,
      'error': result.error,
      // 现在存储完整的 foods 数组
      'foods': result.foods.map((food) => _convertFoodForFirestore(food)).toList(),
    };
  }

  // 转换单个 food 为 Firestore 格式
  static Map<String, dynamic> _convertFoodForFirestore(DetectedFood food) {
    return {
      'name': food.name,
      'calories': food.calories,
      'carbs': food.carbs,
      'protein': food.protein,
      'fat': food.fat,
      'fiber': food.fiber,
      'sugar': food.sugar,
      'sodium': food.sodium,
      'saturatedFat': food.saturatedFat,
      'giValue': food.giValue,
      'glycemicLoad': food.glycemicLoad,
      'glCategory': food.glCategory,
    };
  }

  // 从 Firestore 重建分析结果 - 包含完整的 foods 数组
  static MealAnalysisResult? _convertFirestoreToAnalysisResult(Map<String, dynamic>? data) {
    if (data == null) return null;

    // 重建 foods 数组
    final foods = (data['foods'] as List<dynamic>?)
        ?.map((foodData) => _convertFirestoreToFood(foodData as Map<String, dynamic>))
        .toList() ?? [];

    return MealAnalysisResult(
      id: data['id'] ?? '',
      mealNumber: data['mealNumber'] ?? 0,
      foods: foods,
      totalGL: (data['totalGL'] ?? 0).toDouble(),
      glCategory: data['glCategory'] ?? 'unknown',
      error: data['error'],
    );
  }

  // 从 Firestore 重建单个 food
  static DetectedFood _convertFirestoreToFood(Map<String, dynamic> data) {
    return DetectedFood(
      name: data['name'] ?? 'Unknown',
      calories: (data['calories'] ?? 0).toDouble(),
      carbs: (data['carbs'] ?? 0).toDouble(),
      protein: (data['protein'] ?? 0).toDouble(),
      fat: (data['fat'] ?? 0).toDouble(),
      fiber: (data['fiber'] ?? 0).toDouble(),
      sugar: (data['sugar'] ?? 0).toDouble(),
      sodium: (data['sodium'] ?? 0).toDouble(),
      saturatedFat: (data['saturatedFat'] ?? 0).toDouble(),
      giValue: data['giValue'],
      glycemicLoad: data['glycemicLoad']?.toDouble(),
      glCategory: data['glCategory'] ?? 'unknown',
    );
  }

  // 转换饮食评估为 Firestore 格式 - 不存储 meals 数组（因为在 mealPhotos 中已有）
  static Map<String, dynamic>? _convertDietAssessmentForFirestore(DietAssessmentReport? assessment) {
    if (assessment == null) return null;

    return {
      'avgGLPerMeal': assessment.avgGLPerMeal,
      'isHealthy': assessment.isHealthy,
      'warnings': assessment.warnings,
      'mealCount': assessment.mealCount,
      'glThresholds': assessment.glThresholds,
      'assessmentDate': assessment.assessmentDate.millisecondsSinceEpoch,
    };
  }

  // 从 Firestore 重建饮食评估
  static DietAssessmentReport? _convertFirestoreToDietAssessment(
      Map<String, dynamic>? data,
      List<MealPhotoRecord>? mealPhotos
      ) {
    if (data == null) return null;

    List<MealAnalysisResult> meals = [];
    if (mealPhotos != null) {
      for (int i = 0; i < mealPhotos.length; i++) {
        final photo = mealPhotos[i];
        if (photo.analysisResult != null) {
          meals.add(photo.analysisResult!);
        }
      }
    }

    print('🔄 Rebuilt ${meals.length} meals from ${mealPhotos?.length ?? 0} photos');

    return DietAssessmentReport(
      meals: meals,
      avgGLPerMeal: (data['avgGLPerMeal'] ?? 0).toDouble(),
      isHealthy: data['isHealthy'] ?? false,
      warnings: List<String>.from(data['warnings'] ?? []),
      mealCount: data['mealCount'] ?? meals.length,
      glThresholds: Map<String, int>.from(data['glThresholds'] ?? {
        'low': 10, 'medium': 20, 'high': 20
      }),
      assessmentDate: DateTime.fromMillisecondsSinceEpoch(data['assessmentDate'] ?? 0),
    );
  }

  // 便捷方法：获取所有餐食图片的总 GL
  double get totalGlycemicLoad {
    final photos = inputs.mealPhotos ?? [];
    return photos.fold(0.0, (sum, photo) {
      return sum + (photo.analysisResult?.totalGL ?? 0);
    });
  }

  // 便捷方法：获取平均每餐 GL
  double get averageGlycemicLoadPerMeal {
    final photos = inputs.mealPhotos ?? [];
    if (photos.isEmpty) return 0.0;
    return totalGlycemicLoad / photos.length;
  }

  // 便捷方法：获取所有警告信息
  List<String> get allWarnings {
    final warnings = <String>[];

    if (inputs.dietAssessment?.warnings != null) {
      warnings.addAll(inputs.dietAssessment!.warnings);
    }

    final photos = inputs.mealPhotos ?? [];
    for (final photo in photos) {
      if (photo.analysisResult?.error != null) {
        warnings.add('Photo ${photo.id} analysis error: ${photo.analysisResult!.error}');
      }
    }

    return warnings;
  }

  @override
  String toString() {
    return 'DiabetesRiskPredictionModel(predictionId: $predictionId, '
        'riskLevel: $riskLevel, riskScore: $riskScore, '
        'mealCount: ${inputs.mealPhotos?.length ?? 0})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiabetesRiskPredictionModel && other.predictionId == predictionId;
  }

  @override
  int get hashCode => predictionId.hashCode;
}