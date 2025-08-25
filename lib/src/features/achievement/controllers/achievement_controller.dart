import 'package:get/get.dart';
import '../models/achievement_level_model.dart';
import '../models/achievement_model.dart';

class AchievementController extends GetxController {
  static AchievementController get instance => Get.find();

  // 所有系统成就（从 Firestore 获取）
  final allAchievements = <AchievementModel>[].obs;

  // 加载状态
  final isLoading = false.obs;

  // 错误信息
  final errorMessage = RxString('');

  @override
  void onInit() {
    super.onInit();
    loadSystemAchievements();
  }

  /// 加载系统成就数据 (后续替换为 Firestore 调用)
  Future<void> loadSystemAchievements() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // 模拟网络延迟
      await Future.delayed(Duration(milliseconds: 500));

      // TODO: 替换为实际的 Firestore 调用
      // final achievementsSnapshot = await FirebaseFirestore.instance
      //     .collection('achievements')
      //     .where('isActive', isEqualTo: true)
      //     .orderBy('createdAt')
      //     .get();
      //
      // allAchievements.value = achievementsSnapshot.docs
      //     .map((doc) => AchievementModel.fromFirestore(doc))
      //     .toList();

      allAchievements.value = _getMockSystemAchievements();

    } catch (e) {
      errorMessage.value = 'Failed to load achievements: ${e.toString()}';
      Get.snackbar('Error', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  /// 模拟系统成就数据（后续移除）
  List<AchievementModel> _getMockSystemAchievements() {
    return [
      // Periodic Achievements
      AchievementModel(
        achievementId: '1',
        achievementTitle: 'Track Blood Glucose',
        description: 'Stay consistent with your health journey by recording your blood glucose every day.',
        achievementType: 'periodic',
        imagePath: 'assets/icons/blood_glucose.png',
        levels: [
          AchievementLevelModel(level: 'Bronze', criteria: 7, criteriaUnit: 'days', points: 100),
          AchievementLevelModel(level: 'Silver', criteria: 30, criteriaUnit: 'days', points: 300),
          AchievementLevelModel(level: 'Gold', criteria: 90, criteriaUnit: 'days', points: 500),
        ],
        isActive: true,
        createdAt: DateTime.now(),
      ),
      AchievementModel(
        achievementId: '2',
        achievementTitle: 'Track Blood Pressure',
        description: 'Monitor your blood pressure regularly for better health management.',
        achievementType: 'periodic',
        imagePath: 'assets/icons/blood_pressure.png',
        levels: [
          AchievementLevelModel(level: 'Bronze', criteria: 5, criteriaUnit: 'days', points: 80),
          AchievementLevelModel(level: 'Silver', criteria: 15, criteriaUnit: 'days', points: 200),
          AchievementLevelModel(level: 'Gold', criteria: 30, criteriaUnit: 'days', points: 400),
        ],
        isActive: true,
        createdAt: DateTime.now(),
      ),
      AchievementModel(
        achievementId: '3',
        achievementTitle: 'Track Body Weight',
        description: 'Keep track of your weight to maintain a healthy lifestyle.',
        achievementType: 'periodic',
        imagePath: 'assets/icons/body_weight.png',
        levels: [
          AchievementLevelModel(level: 'Bronze', criteria: 10, criteriaUnit: 'times', points: 50),
          AchievementLevelModel(level: 'Silver', criteria: 30, criteriaUnit: 'times', points: 150),
          AchievementLevelModel(level: 'Gold', criteria: 60, criteriaUnit: 'times', points: 300),
        ],
        isActive: true,
        createdAt: DateTime.now(),
      ),

      // Permanent Achievements
      AchievementModel(
        achievementId: '4',
        achievementTitle: 'Exercise',
        description: 'Stay active with regular exercise sessions.',
        achievementType: 'permanent',
        imagePath: 'assets/icons/exercise.png',
        levels: [
          AchievementLevelModel(level: 'Bronze', criteria: 30, criteriaUnit: 'minutes', points: 100),
          AchievementLevelModel(level: 'Silver', criteria: 120, criteriaUnit: 'minutes', points: 300),
          AchievementLevelModel(level: 'Gold', criteria: 300, criteriaUnit: 'minutes', points: 600),
        ],
        isActive: true,
        createdAt: DateTime.now(),
      ),
      AchievementModel(
        achievementId: '5',
        achievementTitle: 'Generate Meal Plan',
        description: 'Create personalized meal plans for better nutrition.',
        achievementType: 'permanent',
        imagePath: 'assets/icons/meal_plan.png',
        levels: [
          AchievementLevelModel(level: 'Bronze', criteria: 5, criteriaUnit: 'times', points: 80),
          AchievementLevelModel(level: 'Silver', criteria: 20, criteriaUnit: 'times', points: 250),
          AchievementLevelModel(level: 'Gold', criteria: 50, criteriaUnit: 'times', points: 500),
        ],
        isActive: true,
        createdAt: DateTime.now(),
      ),
      AchievementModel(
        achievementId: '6',
        achievementTitle: 'Track Sleep',
        description: 'Monitor your sleep patterns for better health.',
        achievementType: 'permanent',
        imagePath: 'assets/icons/sleep.png',
        levels: [
          AchievementLevelModel(level: 'Bronze', criteria: 10, criteriaUnit: 'nights', points: 60),
          AchievementLevelModel(level: 'Silver', criteria: 30, criteriaUnit: 'nights', points: 180),
          AchievementLevelModel(level: 'Gold', criteria: 90, criteriaUnit: 'nights', points: 400),
        ],
        isActive: true,
        createdAt: DateTime.now(),
      ),
    ];
  }

  // ---------- 公共查询方法 ----------

  /// 根据ID获取成就详情
  AchievementModel? getAchievementById(String achievementId) {
    return allAchievements.firstWhereOrNull(
            (achievement) => achievement.achievementId == achievementId
    );
  }

  /// 获取特定类型的成就
  List<AchievementModel> getAchievementsByType(String type) {
    return allAchievements.where(
            (achievement) => achievement.achievementType == type && achievement.isActive
    ).toList();
  }

  /// 获取所有活跃成就
  List<AchievementModel> getActiveAchievements() {
    return allAchievements.where((achievement) => achievement.isActive).toList();
  }

  /// 获取周期性成就
  List<AchievementModel> get periodicAchievements => getAchievementsByType('periodic');

  /// 获取永久性成就
  List<AchievementModel> get permanentAchievements => getAchievementsByType('permanent');

  /// 刷新成就数据 (供其他 Controller 调用)
  Future<void> refreshAchievements() async {
    await loadSystemAchievements();
  }

  /// 检查成就是否存在
  bool achievementExists(String achievementId) {
    return getAchievementById(achievementId) != null;
  }
}