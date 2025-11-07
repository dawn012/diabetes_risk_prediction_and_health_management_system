import '../../../utils/constants/enums.dart';
import 'achievement_model.dart';
import 'user_achievement_model.dart';

class AchievementDisplayData {
  final AchievementModel achievement;
  final UserAchievementModel? userAchievement;
  final bool isLocked;
  final UserAchievementLevel currentLevel;
  final int currentCount;
  final AchievementStatus status;

  AchievementDisplayData({
    required this.achievement,
    required this.userAchievement,
    required this.isLocked,
    required this.currentLevel,
    required this.currentCount,
    required this.status,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is AchievementDisplayData &&
              runtimeType == other.runtimeType &&
              achievement.achievementId == other.achievement.achievementId;

  @override
  int get hashCode => achievement.achievementId.hashCode;
}