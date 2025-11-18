// diabetes_prediction_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../data/repositories/diabetes_prediction/diabetes_prediction_repository.dart';
import '../features/diabetes_prediction/models/diabetes_risk_prediction_model.dart';
import '../features/personalization/controllers/user_controller.dart';
import 'diabetes_hive_storage_manager.dart';

/// 糖尿病预测服务 - 负责 API 调用和本地状态管理
class DiabetesPredictionService extends GetxService {
  static DiabetesPredictionService get instance => Get.find();

  // 依赖
  final DiabetesHiveStorageManager _storageManager = DiabetesHiveStorageManager.instance;
  final DiabetesPredictionRepository _predictionRepository = Get.put(DiabetesPredictionRepository());
  final Uuid _uuid = const Uuid();

  // API 配置
  static const String _baseUrl = 'http://192.168.247.188:5000';
  static const Duration _timeout = Duration(seconds: 30);

  // 状态管理
  final RxBool isPredicting = false.obs;
  final RxBool isApiAvailable = false.obs;
  final Rxn<DiabetesRiskPredictionModel> lastPrediction =
  Rxn<DiabetesRiskPredictionModel>();

  @override
  void onInit() async {
    super.onInit();
    await _initialize();
  }

  /// 初始化服务
  Future<void> _initialize() async {
    try {
      await checkApiAvailability();
      print('🎯 Diabetes Prediction Service initialized');
    } catch (e) {
      print('❌ Diabetes Prediction Service initialization failed: $e');
    }
  }

  /// 检查 API 可用性
  Future<bool> checkApiAvailability() async {
    try {
      final response =
      await http.get(Uri.parse('$_baseUrl/health')).timeout(_timeout);

      isApiAvailable.value = response.statusCode == 200;

      if (isApiAvailable.value) {
        print('✅ Diabetes Prediction API is available');
      } else {
        print('❌ Diabetes Prediction API is not available');
      }

      return isApiAvailable.value;
    } catch (e) {
      isApiAvailable.value = false;
      print('❌ API health check failed: $e');
      return false;
    }
  }

  /// 开始预测流程
  Future<DiabetesRiskPredictionModel> startPrediction() async {
    try {
      isPredicting.value = true;

      // 1. 检查 API 可用性
      if (!isApiAvailable.value) {
        final isHealthy = await checkApiAvailability();
        if (!isHealthy) {
          throw Exception(
              'Prediction service is unavailable. Please check if the API server is running.');
        }
      }

      // 2. 导出评估数据
      final assessmentData = _storageManager.exportToFirestore();
      if (assessmentData == null) {
        throw Exception(
            'Assessment data is incomplete. Please complete all steps before prediction.');
      }

      // 3. 验证数据完整性
      _validateAssessmentData(assessmentData);

      // 4. 准备 API 请求数据
      final requestData = _prepareApiRequest(assessmentData);

      // 5. 调用预测 API
      final apiResponse = await _callPredictionApi(requestData);

      // 6. 创建完整的预测记录
      final predictionRecord =
      await _createPredictionRecord(apiResponse, assessmentData);

      // 7. 保存到 Firestore（使用现有 Repository）
      await _savePredictionToFirestore(predictionRecord);

      // 8. 更新状态
      lastPrediction.value = predictionRecord;

      print(
          '🎉 Prediction completed: ${predictionRecord.riskLevel} (${predictionRecord.riskScore})');

      return predictionRecord;
    } catch (e) {
      print('❌ Prediction failed: $e');
      rethrow;
    } finally {
      isPredicting.value = false;
    }
  }

  /// 验证评估数据完整性
  void _validateAssessmentData(Map<String, dynamic> assessmentData) {
    final requiredFields = [
      'bloodGlucose',
      'sleepDuration',
      'physicalActivityDuration',
      'stressLevel',
      'waterIntake',
      'medicationAdherence',
      'dietHealthy',
    ];

    final missingFields =
    requiredFields.where((field) => assessmentData[field] == null).toList();

    if (missingFields.isNotEmpty) {
      throw Exception('Missing required fields: ${missingFields.join(', ')}');
    }

    // 验证 BMI 或 height/weight
    if (assessmentData['bmi'] == null &&
        (assessmentData['height'] == null ||
            assessmentData['weight'] == null)) {
      throw Exception('BMI or height and weight must be provided');
    }
  }

  /// 准备 API 请求数据
  Map<String, dynamic> _prepareApiRequest(Map<String, dynamic> assessmentData) {
    // 根据 API 要求映射字段名
    final requestData = {
      'bloodGlucose': assessmentData['bloodGlucose']?.toDouble(),
      'sleepDuration': assessmentData['sleepDuration']?.toDouble(),
      'physicalActivityDuration': assessmentData['physicalActivityDuration']?.toDouble(),
      'stressLevel': assessmentData['stressLevel'],
      'waterIntake': assessmentData['waterIntake'],
      'medicationAdherence': assessmentData['medicationAdherence'],
      'dietHealthy': assessmentData['dietHealthy'],
    };

    // 添加 BMI 或 height/weight
    if (assessmentData['bmi'] != null) {
      requestData['bmi'] = assessmentData['bmi']?.toDouble();
    } else if (assessmentData['height'] != null &&
        assessmentData['weight'] != null) {
      requestData['height'] = assessmentData['height']?.toDouble();
      requestData['weight'] = assessmentData['weight']?.toDouble();
    }

    print('📤 Prepared API request data: $requestData');
    return requestData;
  }

  /// 调用预测 API
  Future<ApiPredictionResponse> _callPredictionApi(
      Map<String, dynamic> requestData) async {
    try {
      print('🌐 Calling prediction API...');

      final response = await http
          .post(
        Uri.parse('$_baseUrl/predict'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestData),
      )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('📥 API response received: $responseData');

        return ApiPredictionResponse.fromJson(responseData);
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error'] ??
            'Prediction failed with status ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on TimeoutException catch (e) {
      throw Exception('Request timeout: ${e.message}');
    } catch (e) {
      throw Exception('API call failed: $e');
    }
  }

  /// 创建完整的预测记录
  Future<DiabetesRiskPredictionModel> _createPredictionRecord(
      ApiPredictionResponse apiResponse,
      Map<String, dynamic> assessmentData,
      ) async {
    try {
      // 获取当前的缓存数据
      final currentCache = _storageManager.getCachedAssessment();
      if (currentCache == null) {
        throw Exception('No cached assessment data found');
      }

      final predictionId = _uuid.v4();

      final riskLevel = apiResponse.riskLevel;

      // 生成建议
      final recommendations = _generateRecommendations(riskLevel);

      // 创建完整的预测记录
      return DiabetesRiskPredictionModel(
        predictionId: predictionId,
        predictionDateTime: DateTime.now(),
        riskLevel: riskLevel,
        riskScore: apiResponse.riskScore,
        recommendations: recommendations,
        inputs: currentCache,
      );
    } catch (e) {
      print('❌ Error creating prediction record: $e');
      rethrow;
    }
  }

  /// 保存预测结果到 Firestore
  Future<void> _savePredictionToFirestore(
      DiabetesRiskPredictionModel predictionRecord,
      ) async {
    try {
      await _predictionRepository.saveDiabetesPrediction(
        _getCurrentUserId(),
        predictionRecord,
      );

      print(
          '💾 Prediction saved to Firestore: ${predictionRecord.predictionId}');
    } catch (e) {
      print('❌ Failed to save prediction to Firestore: $e');
      rethrow;
    }
  }

  /// 获取当前用户 ID
  String _getCurrentUserId() {
    return UserController.instance.user.value.userId;
  }

  /// 根据风险等级生成建议
  List<String> _generateRecommendations(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return [
          'Continue maintaining your healthy lifestyle',
          'Regular physical activity (30 mins daily)',
          'Balanced diet with whole grains and vegetables',
          'Monitor your health indicators regularly'
        ];
      case 'medium':
        return [
          'Consider reducing sugar and refined carb intake',
          'Increase physical activity to 45 mins daily',
          'Monitor blood glucose levels regularly',
          'Maintain healthy weight',
          'Increase fiber intake in your diet'
        ];
      case 'high':
        return [
          'Consult with healthcare professional',
          'Implement structured diet plan',
          'Regular blood glucose monitoring',
          'Consider medication if recommended by doctor',
          'Lose weight if overweight',
          'Reduce stress through relaxation techniques'
        ];
      default:
        return [
          'Maintain healthy lifestyle habits',
          'Regular health check-ups',
          'Balanced nutrition and exercise'
        ];
    }
  }

  /// 获取最近的预测
  DiabetesRiskPredictionModel? getRecentPrediction() {
    return lastPrediction.value;
  }

  /// 测试 API 连接
  Future<void> testApiConnection() async {
    try {
      print('🔍 Testing API connection...');

      final isHealthy = await checkApiAvailability();
      if (isHealthy) {
        print('✅ API connection test passed');

        // 可选：测试获取特征信息
        try {
          final response =
          await http.get(Uri.parse('$_baseUrl/features')).timeout(_timeout);

          if (response.statusCode == 200) {
            final featuresInfo = jsonDecode(response.body);
            print('📋 Features info available');
            print('   Required features: ${featuresInfo['required_features']}');
            print('   Feature order: ${featuresInfo['feature_order']}');
          }
        } catch (e) {
          print('⚠️  Features info test failed: $e');
        }
      } else {
        print('❌ API connection test failed');
      }
    } catch (e) {
      print('❌ API connection test error: $e');
    }
  }

  /// 清除预测状态
  void clearPredictionState() {
    lastPrediction.value = null;
    print('🔄 Prediction state cleared');
  }

  /// 获取预测统计信息
  Future<Map<String, dynamic>> getPredictionStats() async {
    try {
      // 这里可以添加获取用户预测统计的逻辑
      // 例如从 Repository 获取历史预测数据
      return {
        'totalPredictions': 0,
        'lastPrediction': lastPrediction.value?.toJson(),
        'apiAvailable': isApiAvailable.value,
      };
    } catch (e) {
      print('❌ Error getting prediction stats: $e');
      return {
        'totalPredictions': 0,
        'lastPrediction': null,
        'apiAvailable': isApiAvailable.value,
        'error': e.toString(),
      };
    }
  }
}

/// API 响应数据模型
class ApiPredictionResponse {
  final double riskScore;
  final String riskLevel;
  final String status;

  ApiPredictionResponse({
    required this.riskScore,
    required this.riskLevel,
    required this.status,
  });

  factory ApiPredictionResponse.fromJson(Map<String, dynamic> json) {
    return ApiPredictionResponse(
      riskScore: (json['risk_score'] as num).toDouble(),
      riskLevel: json['risk_level'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'risk_score': riskScore,
      'risk_level': riskLevel,
      'status': status,
    };
  }

  @override
  String toString() {
    return 'ApiPredictionResponse(riskScore: $riskScore, riskLevel: $riskLevel)';
  }
}