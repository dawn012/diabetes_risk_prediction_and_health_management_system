import 'package:cloud_firestore/cloud_firestore.dart';
import 'diabetes_assessment_cache_model.dart';
import 'diet_assessment_report_model.dart';
import 'meal_analysis_result_model.dart';
import 'meal_photo_record_model.dart';
import '../../../utils/constants/firebase_field_names.dart';

class DiabetesRiskPredictionModel {
  final String predictionId;
  final String userId;
  final DateTime predictionDateTime;
  final String riskLevel; // 'low', 'medium', 'high', 'very_high'
  final double riskScore; // 0.0 - 1.0 or 0-100
  final List<String> recommendations;

  // 复用 DiabetesAssessmentCache 作为输入数据
  final DiabetesAssessmentCache inputs;

  DiabetesRiskPredictionModel({
    required this.predictionId,
    required this.userId,
    required this.predictionDateTime,
    required this.riskLevel,
    required this.riskScore,
    required this.recommendations,
    required this.inputs,
  });

  /// Empty constructor for initialization
  factory DiabetesRiskPredictionModel.empty() => DiabetesRiskPredictionModel(
    predictionId: '',
    userId: '',
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
      userId: userId ?? this.userId,
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
      FirebaseFieldNames.userId: userId,
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
      userId: json[FirebaseFieldNames.userId] ?? '',
      predictionDateTime: DateTime.fromMillisecondsSinceEpoch(
        json[FirebaseFieldNames.predictionDateTime] ?? 0,
      ),
      riskLevel: json[FirebaseFieldNames.riskLevel] ?? '',
      riskScore: (json[FirebaseFieldNames.riskScore] ?? 0).toDouble(),
      recommendations: List<String>.from(json[FirebaseFieldNames.recommendations] ?? []),
      inputs: _convertFirestoreToCache(json['inputs'] ?? {}),
    );
  }

  // 转换 Hive Cache 为 Firestore 友好的格式
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

      // 餐食照片信息（包含 analysisResult）
      'mealPhotos': _convertMealPhotosForFirestore(cache.mealPhotos),
      'mealPhotosProcessed': cache.mealPhotosProcessed,

      // 饮食评估结果（只存储汇总信息，不存 meals 数组）
      'dietAssessment': _convertDietAssessmentForFirestore(cache.dietAssessment),
    };
  }

  // 从 Firestore 数据重建 Cache 对象
  static DiabetesAssessmentCache _convertFirestoreToCache(Map<String, dynamic> data) {
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
      mealPhotos: _convertFirestoreToMealPhotos(data['mealPhotos'] ?? []),
      mealPhotosProcessed: data['mealPhotosProcessed'],
      dietAssessment: _convertFirestoreToDietAssessment(data['dietAssessment']),
      lastUpdated: DateTime.now(),
    );
  }

  // 转换餐食照片为 Firestore 格式 - 包含 analysisResult
  static List<Map<String, dynamic>> _convertMealPhotosForFirestore(List<MealPhotoRecord>? photos) {
    if (photos == null) return [];

    return photos.map((photo) {
      return {
        'id': photo.id,
        'imagePath': photo.imagePath, // 共用字段：存储云端URL
        'uploadTime': photo.uploadTime.millisecondsSinceEpoch,
        'needsProcessing': photo.needsProcessing,
        'isFromCloud': true, // 存到 Firestore 时标记为云端
        // 存储每张图片的 analysisResult（包含 totalGL 和 glCategory）
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
        storageUrl: photoData['imagePath'], // 直接使用 imagePath 作为云端URL
        uploadTime: DateTime.fromMillisecondsSinceEpoch(photoData['uploadTime'] ?? 0),
        analysisResult: _convertFirestoreToAnalysisResult(photoData['analysisResult']),
      );
    }).toList();
  }

  // 转换分析结果为 Firestore 格式
  static Map<String, dynamic>? _convertAnalysisResultForFirestore(MealAnalysisResult? result) {
    if (result == null) return null;

    return {
      'id': result.id,
      'mealNumber': result.mealNumber,
      'totalGL': result.totalGL,        // 每张图片的 totalGL
      'glCategory': result.glCategory,  // 每张图片的 GL 分类
      'error': result.error,
      // 不存储 foods 数组
    };
  }

  // 从 Firestore 重建分析结果
  static MealAnalysisResult? _convertFirestoreToAnalysisResult(Map<String, dynamic>? data) {
    if (data == null) return null;

    return MealAnalysisResult(
      id: data['id'] ?? '',
      mealNumber: data['mealNumber'] ?? 0,
      foods: [], // 不重建 foods 数组
      totalGL: (data['totalGL'] ?? 0).toDouble(),
      glCategory: data['glCategory'] ?? 'unknown',
      error: data['error'],
    );
  }

  // 转换饮食评估为 Firestore 格式 - 只存储汇总信息，不存 meals 数组
  static Map<String, dynamic>? _convertDietAssessmentForFirestore(DietAssessmentReport? assessment) {
    if (assessment == null) return null;

    return {
      // 不存储 meals 数组，因为数据在 mealPhotos 中已经有了
      'avgGLPerMeal': assessment.avgGLPerMeal,
      'isHealthy': assessment.isHealthy,
      'warnings': assessment.warnings,
      'mealCount': assessment.mealCount,
      'glThresholds': assessment.glThresholds,
      'assessmentDate': assessment.assessmentDate.millisecondsSinceEpoch,
    };
  }

  // 从 Firestore 重建饮食评估
  static DietAssessmentReport? _convertFirestoreToDietAssessment(Map<String, dynamic>? data) {
    if (data == null) return null;

    return DietAssessmentReport(
      meals: [], // 不重建 meals 数组，因为数据在 mealPhotos 中
      avgGLPerMeal: (data['avgGLPerMeal'] ?? 0).toDouble(),
      isHealthy: data['isHealthy'] ?? false,
      warnings: List<String>.from(data['warnings'] ?? []),
      mealCount: data['mealCount'] ?? 0,
      glThresholds: Map<String, int>.from(data['glThresholds'] ?? {}),
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

    // 从 dietAssessment 获取警告
    if (inputs.dietAssessment?.warnings != null) {
      warnings.addAll(inputs.dietAssessment!.warnings);
    }

    // 从单张图片分析结果获取错误信息
    final photos = inputs.mealPhotos ?? [];
    for (final photo in photos) {
      if (photo.analysisResult?.error != null) {
        warnings.add('图片 ${photo.id} 分析错误: ${photo.analysisResult!.error}');
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