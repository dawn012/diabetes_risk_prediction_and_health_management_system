import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/repositories/diabetes_prediction/diabetes_prediction_repository.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/enums.dart';
import '../../diabetes_prediction/models/diabetes_risk_prediction_model.dart';
import '../../diabetes_prediction/views/diabetes_output/diabetes_risk_detail_screen.dart';
import '../views/health_data_analytics/widgets/health_data_list_screen.dart';

class DiabetesRiskController extends GetxController {
  // Repositories
  final _predictionRepo = Get.put(DiabetesPredictionRepository());
  final _authRepo = AuthenticationRepository.instance;

  // Stream subscription
  StreamSubscription<List<DiabetesRiskPredictionModel>>? _predictionSubscription;

  // Observable variables
  final selectedTimeRange = 'Past 14 Days'.obs;
  final selectedTrendFilter = 'All'.obs;

  final predictionList = <DiabetesRiskPredictionModel>[].obs;
  final latestPrediction = Rxn<DiabetesRiskPredictionModel>();
  final isLoading = false.obs;

  // Statistics
  final lowestScore = 0.0.obs;
  final highestScore = 0.0.obs;
  final currentScore = 0.0.obs;
  final lowCount = 0.obs;
  final mediumCount = 0.obs;
  final highCount = 0.obs;
  final totalCount = 0.obs;

  // Dashboard specific
  final past14DaysCount = 0.obs;

  // Chart data
  final trendsData = <FlSpot>[].obs;
  final trendsLabels = <String>[].obs;
  final trendsOriginalDateTimes = <DateTime>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initializeDataStream();
  }

  @override
  void onClose() {
    _predictionSubscription?.cancel();
    super.onClose();
  }

  /// Reset filters to default values (for Dashboard)
  void resetFilters() {
    selectedTimeRange.value = 'Past 14 Days';
    selectedTrendFilter.value = 'All';
    refreshData();
  }

  /// Initialize data stream
  void _initializeDataStream() {
    final userId = _authRepo.authUser?.uid;
    if (userId == null) return;

    isLoading.value = true;

    final endDate = DateTime.now().add(const Duration(days: 1));
    final startDate = endDate.subtract(const Duration(days: 90));

    _predictionSubscription = _predictionRepo
        .getDiabetesPredictionsStream(userId, startDate, endDate)
        .listen(
          (predictions) {
        predictionList.value = predictions;

        if (predictions.isNotEmpty) {
          latestPrediction.value = predictions.first;
          currentScore.value = predictions.first.riskScore;
        } else {
          latestPrediction.value = null;
          currentScore.value = 0.0;
        }

        refreshData();
        isLoading.value = false;
      },
      onError: (error) {
        TLoaders.errorSnackBar(
          title: 'Error',
          message: 'Failed to load diabetes predictions: ${error.toString()}',
        );
        isLoading.value = false;
      },
    );
  }

  /// Update dashboard counts
  void _updatePast14DaysCount() {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 14));
    past14DaysCount.value = predictionList
        .where((data) => data.predictionDateTime.isAfter(cutoffDate))
        .length;
  }

  /// Calculate statistics based on current filters
  void _calculateStatistics() {
    final filteredData = getFilteredData();

    if (filteredData.isEmpty) {
      _resetStatistics();
      return;
    }

    final scores = filteredData.map((p) => p.riskScore).toList();

    lowestScore.value = scores.reduce((a, b) => a < b ? a : b);
    highestScore.value = scores.reduce((a, b) => a > b ? a : b);
    currentScore.value = latestPrediction.value?.riskScore ?? 0.0;

    totalCount.value = scores.length;

    // Calculate risk level distribution
    int low = 0, medium = 0, high = 0;
    for (final prediction in filteredData) {
      final level = getRiskLevel(prediction.riskScore);
      switch (level) {
        case 'low':
          low++;
          break;
        case 'medium':
          medium++;
          break;
        case 'high':
          high++;
          break;
      }
    }

    lowCount.value = low;
    mediumCount.value = medium;
    highCount.value = high;
  }

  /// Reset statistics to zero
  void _resetStatistics() {
    lowestScore.value = 0.0;
    highestScore.value = 0.0;
    currentScore.value = 0.0;
    lowCount.value = 0;
    mediumCount.value = 0;
    highCount.value = 0;
    totalCount.value = 0;
  }

  /// Get filtered data based on current filters
  List<DiabetesRiskPredictionModel> getFilteredData() {
    List<DiabetesRiskPredictionModel> filtered = List.from(predictionList);

    final timeRangeDays = _getTimeRangeDays(selectedTimeRange.value);
    if (timeRangeDays > 0) {
      final cutoffDate = DateTime.now().subtract(Duration(days: timeRangeDays));
      filtered = filtered
          .where((data) => data.predictionDateTime.isAfter(cutoffDate))
          .toList();
    }

    return filtered;
  }

  /// Get time range in days
  int _getTimeRangeDays(String timeRange) {
    switch (timeRange) {
      case 'Past 7 Days':
        return 7;
      case 'Past 14 Days':
        return 14;
      case 'Past 30 Days':
        return 30;
      case 'Past 60 Days':
        return 60;
      case 'Past 90 Days':
        return 90;
      default:
        return 14;
    }
  }

  /// Update charts data
  void _updateChartsData() {
    _updateTrendsData();
  }

  /// Update trends chart data
  void _updateTrendsData() {
    final filteredData = getFilteredData();

    if (filteredData.isEmpty) {
      trendsData.clear();
      trendsLabels.clear();
      trendsOriginalDateTimes.clear();
      return;
    }

    filteredData.sort((a, b) => a.predictionDateTime.compareTo(b.predictionDateTime));

    final spots = <FlSpot>[];
    final labels = <String>[];
    final originalDateTimes = <DateTime>[];

    for (int i = 0; i < filteredData.length; i++) {
      final data = filteredData[i];
      spots.add(FlSpot(i.toDouble(), data.riskScore));
      labels.add('${data.predictionDateTime.month}/${data.predictionDateTime.day}');
      originalDateTimes.add(data.predictionDateTime);
    }

    trendsData.value = spots;
    trendsLabels.value = labels;
    trendsOriginalDateTimes.value = originalDateTimes;
  }

  /// Determine risk level category
  String getRiskLevel(double score) {
    if (score <= 30) {
      return 'low';
    } else if (score <= 60) {
      return 'medium';
    } else {
      return 'high';
    }
  }

  /// Get risk level color
  Color getRiskLevelColor(double score) {
    final level = getRiskLevel(score);
    switch (level) {
      case 'low':
        return TColors.success;
      case 'medium':
        return TColors.warning;
      case 'high':
        return TColors.error;
      default:
        return TColors.darkGrey;
    }
  }

  /// Update time range
  void updateTimeRange(String timeRange) {
    selectedTimeRange.value = timeRange;
    _calculateStatistics();
    _updateChartsData();
  }

  /// Update trend filter
  void updateTrendFilter(String filter) {
    selectedTrendFilter.value = filter;
    _updateChartsData();
  }

  /// Navigation methods
  void navigateToLowestRecord() {
    final filteredData = getFilteredData();
    final lowestRecord = filteredData
        .where((data) => data.riskScore == lowestScore.value)
        .first;

    Get.to(() => DiabetesRiskDetailScreen(prediction: lowestRecord));
  }

  void navigateToHighestRecord() {
    final filteredData = getFilteredData();
    final highestRecord = filteredData
        .where((data) => data.riskScore == highestScore.value)
        .first;

    Get.to(() => DiabetesRiskDetailScreen(prediction: highestRecord));
  }

  void navigateToCurrentRecord() {
    if (latestPrediction.value != null) {
      Get.to(() => DiabetesRiskDetailScreen(prediction: latestPrediction.value!));
    }
  }

  void showAllRecords() {
    Get.to(() => HealthDataListScreen(
      title: 'All Records',
      healthDataType: HealthDataType.diabetesRisk,
      filterType: 'all',
    ));
  }

  void showLowRecords() {
    Get.to(() => HealthDataListScreen(
      title: 'Low Risk Records',
      healthDataType: HealthDataType.diabetesRisk,
      filterType: 'low',
    ));
  }

  void showMediumRecords() {
    Get.to(() => HealthDataListScreen(
      title: 'Medium Risk Records',
      healthDataType: HealthDataType.diabetesRisk,
      filterType: 'medium',
    ));
  }

  void showHighRecords() {
    Get.to(() => HealthDataListScreen(
      title: 'High Risk Records',
      healthDataType: HealthDataType.diabetesRisk,
      filterType: 'high',
    ));
  }

  /// Refresh data
  Future<void> refreshData() async {
    _calculateStatistics();
    _updateChartsData();
    _updatePast14DaysCount();
  }
}