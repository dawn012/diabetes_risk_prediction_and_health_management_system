import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../features/health_data_entry/models/blood_glucose_model.dart';
import '../../../features/health_data_entry/models/blood_pressure_model.dart';
import '../../../features/health_data_entry/models/body_composition_model.dart';
import '../../../features/health_data_entry/models/health_data_model.dart';
import '../../../features/health_data_entry/models/physical_activity_model.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/firebase_collection_names.dart';
import '../../../utils/constants/firebase_field_names.dart';

class HealthLogRepository extends GetxController {
  static HealthLogRepository get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get health logs collection reference for a user
  CollectionReference<Map<String, dynamic>> _getHealthLogsCollection(String userId) {
    return _db.collection(FirebaseCollectionNames.healthLogs).doc(userId).collection('logs');
  }

  /// 智能保存健康数据 - 自动合并相同时间的记录
  Future<void> saveHealthLog(String userId, HealthDataModel healthData) async {
    try {
      // 查找相同时间的现有记录
      final existingLog = await findLogAtExactTime(
        userId: userId,
        logDateTime: healthData.logDateTime,
        physiologicalTimePeriod: healthData.physiologicalTimePeriod,
      );

      if (existingLog != null) {
        // 合并数据并更新现有记录
        final mergedData = _mergeHealthData(existingLog, healthData);
        await _updateHealthLog(userId, mergedData);
      } else {
        // 创建新记录
        await _createNewLog(userId, healthData);
      }
    } catch (e) {
      throw 'Failed to save health log: ${e.toString()}';
    }
  }

  /// 查找相同时间的记录（精确匹配）
  Future<HealthDataModel?> findLogAtExactTime({
    required String userId,
    required DateTime logDateTime,
    required PhysiologicalTimePeriod physiologicalTimePeriod,
  }) async {
    // 精确匹配相同的时间（年、月、日、时、分）
    final exactTime = DateTime(
      logDateTime.year,
      logDateTime.month,
      logDateTime.day,
      logDateTime.hour,
      logDateTime.minute,
    );

    final querySnapshot = await _getHealthLogsCollection(userId)
        .where(FirebaseFieldNames.logDateTime, isEqualTo: exactTime.millisecondsSinceEpoch)
        .where(FirebaseFieldNames.physiologicalTimePeriod, isEqualTo: physiologicalTimePeriod.value)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return HealthDataModel.fromSnapshot(querySnapshot.docs.first);
    }

    return null;
  }

  /// 查找时间范围内的记录
  Future<List<HealthDataModel>> findLogsInTimeRange({
    required String userId,
    required DateTime startTime,
    required DateTime endTime,
    required PhysiologicalTimePeriod physiologicalTimePeriod,
  }) async {
    final querySnapshot = await _getHealthLogsCollection(userId)
        .where(FirebaseFieldNames.logDateTime,
        isGreaterThanOrEqualTo: startTime.millisecondsSinceEpoch)
        .where(FirebaseFieldNames.logDateTime,
        isLessThanOrEqualTo: endTime.millisecondsSinceEpoch)
        .where(FirebaseFieldNames.physiologicalTimePeriod,
        isEqualTo: physiologicalTimePeriod.value)
        .orderBy(FirebaseFieldNames.logDateTime, descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => HealthDataModel.fromSnapshot(doc))
        .toList();
  }

  Future<HealthDataModel?> findStepRecordForDate({
    required String userId,
    required DateTime date,
  }) async {

    final querySnapshot = await _getHealthLogsCollection(userId)
        .where(FirebaseFieldNames.logDateTime, isEqualTo: date.millisecondsSinceEpoch)
        .where(FirebaseFieldNames.physiologicalTimePeriod, isEqualTo: PhysiologicalTimePeriod.wakeUp.value)
        .where(FirebaseFieldNames.steps, isGreaterThan: 0)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final log = HealthDataModel.fromSnapshot(querySnapshot.docs.first);
      print('✅ Found step record for $date: ${log.steps} steps');
      return log;
    }

    print('❌ No step record found for $date');
    return null;
  }

  /// 检查记录是否包含特定数据类型
  bool hasDataType(HealthDataModel healthData, String dataType) {
    switch (dataType) {
      case 'bloodGlucose':
        return healthData.bloodGlucose.glucoseLevel > 0;
      case 'bloodPressure':
        return healthData.bloodPressure.systolic > 0 ||
            healthData.bloodPressure.diastolic > 0;
      case 'bodyComposition':
        return healthData.bodyComposition.weight > 0 ||
            healthData.bodyComposition.bodyFat > 0;
      case 'physicalActivity':
        return healthData.physicalActivity.activityType.isNotEmpty;
      default:
        return false;
    }
  }

  /// 合并健康数据（只合并新数据，不覆盖现有数据）
  HealthDataModel _mergeHealthData(HealthDataModel existing, HealthDataModel newData) {
    // 确定使用哪个步数值
    int mergedSteps = existing.steps ?? 0;

    // 如果新数据有步数，且大于现有步数，使用新步数
    if (newData.steps != null && newData.steps! > mergedSteps) {
      mergedSteps = newData.steps!;
      print('🔄 Merging steps: $mergedSteps (existing: ${existing.steps}, new: ${newData.steps})');
    }

    return HealthDataModel(
      logId: existing.logId,
      logDateTime: existing.logDateTime,
      physiologicalTimePeriod: existing.physiologicalTimePeriod,

      // 血压数据：新数据优先，但如果新数据为空则保留原有数据
      bloodPressure: BloodPressureModel(
        systolic: newData.bloodPressure.systolic > 0 ? newData.bloodPressure.systolic : existing.bloodPressure.systolic,
        diastolic: newData.bloodPressure.diastolic > 0 ? newData.bloodPressure.diastolic : existing.bloodPressure.diastolic,
        pulse: newData.bloodPressure.pulse > 0 ? newData.bloodPressure.pulse : existing.bloodPressure.pulse,
      ),

      // 血糖数据
      bloodGlucose: BloodGlucoseModel(
        glucoseLevel: newData.bloodGlucose.glucoseLevel > 0 ? newData.bloodGlucose.glucoseLevel : existing.bloodGlucose.glucoseLevel,
      ),

      // 身体成分数据
      bodyComposition: BodyCompositionModel(
        weight: newData.bodyComposition.weight > 0 ? newData.bodyComposition.weight : existing.bodyComposition.weight,
        bodyFat: newData.bodyComposition.bodyFat > 0 ? newData.bodyComposition.bodyFat : existing.bodyComposition.bodyFat,
      ),

      // 运动数据
      physicalActivity: PhysicalActivityModel(
        activityType: newData.physicalActivity.activityType.isNotEmpty ? newData.physicalActivity.activityType : existing.physicalActivity.activityType,
        duration: newData.physicalActivity.duration > 0 ? newData.physicalActivity.duration : existing.physicalActivity.duration,
        intensityLevel: newData.physicalActivity.activityType.isNotEmpty ? newData.physicalActivity.intensityLevel : existing.physicalActivity.intensityLevel,
      ),

      // 步数数据：新数据优先
      steps: mergedSteps,
    );
  }

  /// 创建新记录
  Future<void> _createNewLog(String userId, HealthDataModel healthData) async {
    await _getHealthLogsCollection(userId)
        .doc(healthData.logId)
        .set(healthData.toJson());
  }

  /// 更新现有记录
  Future<void> _updateHealthLog(String userId, HealthDataModel healthData) async {
    await _getHealthLogsCollection(userId)
        .doc(healthData.logId)
        .update(healthData.toJson());
  }

  /// Update a health log (用于编辑模式)
  Future<void> updateHealthLog(String userId, HealthDataModel healthData) async {
    try {
      await _getHealthLogsCollection(userId)
          .doc(healthData.logId)
          .update(healthData.toJson());
    } catch (e) {
      throw 'Failed to update health log: ${e.toString()}';
    }
  }

  /// Delete a health log
  Future<void> deleteHealthLog(String userId, String logId) async {
    try {
      await _getHealthLogsCollection(userId).doc(logId).delete();
    } catch (e) {
      throw 'Failed to delete health log: ${e.toString()}';
    }
  }

  /// Get a specific health log
  Future<HealthDataModel?> getHealthLog(String userId, String logId) async {
    try {
      final doc = await _getHealthLogsCollection(userId).doc(logId).get();
      if (doc.exists) {
        return HealthDataModel.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      throw 'Failed to get health log: ${e.toString()}';
    }
  }

  /// Get all health logs for a user
  Future<List<HealthDataModel>> getAllHealthLogs(String userId) async {
    try {
      final snapshot = await _getHealthLogsCollection(userId)
          .orderBy(FirebaseFieldNames.logDateTime, descending: true)
          .get();

      return snapshot.docs
          .map((doc) => HealthDataModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw 'Failed to get health logs: ${e.toString()}';
    }
  }

  /// Get health logs within a date range as stream
  Stream<List<HealthDataModel>> getHealthLogsByDateRangeStream(
      String userId, DateTime startDate, DateTime endDate) {
    try {
      return _getHealthLogsCollection(userId)
          .where(FirebaseFieldNames.logDateTime,
          isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch)
          .where(FirebaseFieldNames.logDateTime,
          isLessThanOrEqualTo: endDate.millisecondsSinceEpoch)
          .orderBy(FirebaseFieldNames.logDateTime, descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
          .map((doc) => HealthDataModel.fromSnapshot(doc))
          .toList());
    } catch (e) {
      throw 'Failed to get health logs by date range: ${e.toString()}';
    }
  }

  /// Get blood glucose logs as stream
  Stream<List<HealthDataModel>> getBloodGlucoseLogsStream(
      String userId, DateTime startDate, DateTime endDate) {
    return getHealthLogsByDateRangeStream(userId, startDate, endDate)
        .map((logs) => logs
        .where((log) => log.bloodGlucose.glucoseLevel > 0)
        .toList());
  }

  /// Get blood pressure logs as stream
  Stream<List<HealthDataModel>> getBloodPressureLogsStream(
      String userId, DateTime startDate, DateTime endDate) {
    return getHealthLogsByDateRangeStream(userId, startDate, endDate)
        .map((logs) => logs
        .where((log) =>
    log.bloodPressure.systolic > 0 ||
        log.bloodPressure.diastolic > 0 ||
        log.bloodPressure.pulse > 0)
        .toList());
  }

  /// Get body composition logs as stream
  Stream<List<HealthDataModel>> getBodyCompositionLogsStream(
      String userId, DateTime startDate, DateTime endDate) {
    return getHealthLogsByDateRangeStream(userId, startDate, endDate)
        .map((logs) => logs
        .where((log) =>
    log.bodyComposition.weight > 0 || log.bodyComposition.bodyFat > 0)
        .toList());
  }

  /// Get physical activity logs as stream
  Stream<List<HealthDataModel>> getPhysicalActivityLogsStream(
      String userId, DateTime startDate, DateTime endDate) {
    return getHealthLogsByDateRangeStream(userId, startDate, endDate)
        .map((logs) => logs
        .where((log) => log.physicalActivity.activityType.isNotEmpty)
        .toList());
  }

  /// Stream health logs (for real-time updates)
  Stream<List<HealthDataModel>> streamHealthLogs(String userId) {
    return _getHealthLogsCollection(userId)
        .orderBy(FirebaseFieldNames.logDateTime, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => HealthDataModel.fromSnapshot(doc))
        .toList());
  }

  /// Get recent logs (last N logs)
  Future<List<HealthDataModel>> getRecentLogs(String userId, int limit) async {
    try {
      final snapshot = await _getHealthLogsCollection(userId)
          .orderBy(FirebaseFieldNames.logDateTime, descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => HealthDataModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw 'Failed to get recent logs: ${e.toString()}';
    }
  }
}