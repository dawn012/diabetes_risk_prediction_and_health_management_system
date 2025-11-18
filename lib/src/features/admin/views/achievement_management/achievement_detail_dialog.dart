import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../utils/constants/admin_colors.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../achievement/models/achievement_model.dart';
import '../../controllers/achievement_management_controller.dart';

class AchievementDetailDialog extends StatelessWidget {
  final AchievementModel achievement;
  final AchievementManagementController controller;

  const AchievementDetailDialog({
    super.key,
    required this.achievement,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);
    final isWeb = THelperFunctions.screenWidth() > 600;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isWeb ? 800 : 400,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: TAdminColors.getSurfaceColor(darkMode),
            borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(isWeb ? 24 : 20),
                decoration: BoxDecoration(
                  color: TAdminColors.getSurfaceVariantColor(darkMode),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isWeb ? 20 : 16),
                    topRight: Radius.circular(isWeb ? 20 : 16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.award_bold,
                      color: TAdminColors.primary,
                      size: isWeb ? 28 : 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Achievement Details',
                        style: TextStyle(
                          fontSize: isWeb ? 24 : 20,
                          fontWeight: FontWeight.bold,
                          color: TAdminColors.getOnSurfaceColor(darkMode),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(
                        Iconsax.close_circle_bold,
                        color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isWeb ? 24 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Achievement Info Section
                      _buildSection(
                        'Achievement Information',
                        _buildAchievementInfo(darkMode, isWeb),
                        darkMode,
                      ),

                      SizedBox(height: 24),

                      // Levels Section
                      _buildSection(
                        'Achievement Levels',
                        _buildLevelsInfo(darkMode, isWeb),
                        darkMode,
                      ),

                      SizedBox(height: 24),

                      // Completion Statistics Section
                      _buildSection(
                        'Completion Statistics',
                        _buildCompletionStats(darkMode, isWeb),
                        darkMode,
                      ),
                    ],
                  ),
                ),
              ),

              // Footer Actions
              Container(
                padding: EdgeInsets.all(isWeb ? 24 : 20),
                decoration: BoxDecoration(
                  color: TAdminColors.getSurfaceVariantColor(darkMode),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(isWeb ? 20 : 16),
                    bottomRight: Radius.circular(isWeb ? 20 : 16),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: TAdminColors.getBorderColor(darkMode),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Status indicator
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: achievement.isActive
                            ? TAdminColors.success.withOpacity(0.1)
                            : TAdminColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: achievement.isActive
                              ? TAdminColors.success.withOpacity(0.3)
                              : TAdminColors.error.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            achievement.isActive ? Iconsax.eye_bold : Iconsax.eye_slash_bold,
                            size: 14,
                            color: achievement.isActive ? TAdminColors.success : TAdminColors.error,
                          ),
                          SizedBox(width: 6),
                          Text(
                            achievement.isActive ? 'Active' : 'Disabled',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: achievement.isActive ? TAdminColors.success : TAdminColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Spacer(),

                    // Action buttons
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => Get.back(),
                          icon: Icon(Iconsax.arrow_left_2_bold, size: 16),
                          label: Text('Close'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: isWeb ? 20 : 16,
                              vertical: isWeb ? 14 : 12,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Get.back();
                            controller.openEditAchievementDialog(achievement);
                          },
                          icon: Icon(Iconsax.edit_bold, size: 16),
                          label: Text('Edit Achievement'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TAdminColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: isWeb ? 20 : 16,
                              vertical: isWeb ? 14 : 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content, bool darkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: TAdminColors.getOnSurfaceColor(darkMode),
          ),
        ),
        SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildAchievementInfo(bool darkMode, bool isWeb) {
    return Container(
      padding: EdgeInsets.all(isWeb ? 20 : 16),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceVariantColor(darkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TAdminColors.getBorderColor(darkMode)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Achievement image and basic info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Achievement image
              Container(
                width: isWeb ? 80 : 60,
                height: isWeb ? 80 : 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TAdminColors.getBorderColor(darkMode)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: _buildDefaultIcon(darkMode, isWeb),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.achievementTitle,
                      style: TextStyle(
                        fontSize: isWeb ? 20 : 16,
                        fontWeight: FontWeight.bold,
                        color: TAdminColors.getOnSurfaceColor(darkMode),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      achievement.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 16),
          Divider(color: TAdminColors.getBorderColor(darkMode)),
          SizedBox(height: 16),

          // Achievement details
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Achievement ID',
                  achievement.achievementId,
                  Iconsax.hashtag_bold,
                  darkMode,
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: _buildInfoItem(
                  'Type',
                  achievement.achievementType.displayName,
                  achievement.achievementType == AchievementType.periodic ? Iconsax.calendar_bold : Iconsax.award_bold,
                  darkMode,
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Created Date',
                  '${achievement.createdAt.day}/${achievement.createdAt.month}/${achievement.createdAt.year}',
                  Iconsax.calendar_add_bold,
                  darkMode,
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: _buildInfoItem(
                  'Total Levels',
                  '${achievement.levels.length}',
                  Iconsax.layer_bold,
                  darkMode,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultIcon(bool darkMode, bool isWeb) {
    // 使用成就自己的图标
    final iconData = IconData(achievement.iconCodePoint, fontFamily: 'MaterialIcons');

    // 根据成就类型设置不同的背景色
    Color backgroundColor;
    Color iconColor;

    switch (achievement.achievementType) {
      case AchievementType.periodic:
        backgroundColor = TAdminColors.warning.withOpacity(0.1);
        iconColor = TAdminColors.warning;
        break;
      case AchievementType.permanent:
        backgroundColor = TAdminColors.primary.withOpacity(0.1);
        iconColor = TAdminColors.primary;
        break;
      default:
        backgroundColor = TAdminColors.getSurfaceVariantColor(darkMode);
        iconColor = TAdminColors.getOnSurfaceVariantColor(darkMode);
    }

    return Container(
      color: backgroundColor,
      child: Center(
        child: Icon(
          iconData, // 使用成就的图标
          size: isWeb ? 32 : 24,
          color: iconColor,
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, bool darkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: TAdminColors.getOnSurfaceVariantColor(darkMode),
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: TAdminColors.getOnSurfaceColor(darkMode),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelsInfo(bool darkMode, bool isWeb) {
    return Container(
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceVariantColor(darkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TAdminColors.getBorderColor(darkMode)),
      ),
      child: Column(
        children: achievement.levels.asMap().entries.map((entry) {
          final index = entry.key;
          final level = entry.value;
          final isLast = index == achievement.levels.length - 1;

          return Container(
            padding: EdgeInsets.all(isWeb ? 20 : 16),
            decoration: BoxDecoration(
              border: isLast ? null : Border(
                bottom: BorderSide(
                  color: TAdminColors.getBorderColor(darkMode),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                // Level badge
                Container(
                  width: isWeb ? 50 : 40,
                  height: isWeb ? 50 : 40,
                  decoration: BoxDecoration(
                    color: _getLevelColor(level.level, achievement.achievementType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getLevelColor(level.level, achievement.achievementType).withOpacity(0.3),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _getLevelIcon(level.level, achievement.achievementType),
                      color: _getLevelColor(level.level, achievement.achievementType),
                      size: isWeb ? 24 : 20,
                    ),
                  ),
                ),

                SizedBox(width: 16),

                // Level info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            level.level.displayName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: TAdminColors.getOnSurfaceColor(darkMode),
                            ),
                          ),
                          if (level.points > 0) ...[
                            SizedBox(width: 12),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: TAdminColors.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${level.points} pts',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: TAdminColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Requirement: ${level.criteria} ${level.criteriaUnit}',
                        style: TextStyle(
                          fontSize: 14,
                          color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompletionStats(bool darkMode, bool isWeb) {
    final stats = controller.getCompletionStats(achievement);
    final totalCompletions = stats['total'] ?? 0;
    final recentCompletions = stats['recent'] ?? 0;

    return Container(
      padding: EdgeInsets.all(isWeb ? 20 : 16),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceVariantColor(darkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TAdminColors.getBorderColor(darkMode)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  (achievement.achievementType == AchievementType.periodic) ? 'Total Participants' : 'Total Completion',
                  '$totalCompletions',
                  Iconsax.people_bold,
                  TAdminColors.primary,
                  darkMode,
                  isWeb,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  (achievement.achievementType == AchievementType.periodic) ? 'Today Participants' : 'This Month Completion',
                  '$recentCompletions',
                  Iconsax.calendar_1_bold,
                  TAdminColors.success,
                  darkMode,
                  isWeb,
                ),
              ),
            ],
          ),

          if (achievement.achievementType == AchievementType.periodic && achievement.levels.length > 1) ...[
            SizedBox(height: 16),
            Divider(color: TAdminColors.getBorderColor(darkMode)),
            SizedBox(height: 16),

            // Level breakdown for monthly achievements
            Text(
              'Level Distribution',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: TAdminColors.getOnSurfaceColor(darkMode),
              ),
            ),
            SizedBox(height: 12),

            Column(
              children: achievement.levels.map((level) {
                final levelCompletions = controller.getLevelCompletions(achievement.achievementId, level.level.value);
                final percentage = totalCompletions > 0 ? (levelCompletions / totalCompletions * 100) : 0;

                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _getLevelColor(level.level, achievement.achievementType),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              level.level.displayName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: TAdminColors.getOnSurfaceColor(darkMode),
                              ),
                            ),
                          ),
                          Text(
                            '$levelCompletions (${percentage.toStringAsFixed(1)}%)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: totalCompletions > 0 ? levelCompletions / totalCompletions : 0,
                        backgroundColor: TAdminColors.getBorderColor(darkMode),
                        valueColor: AlwaysStoppedAnimation(
                          _getLevelColor(level.level, achievement.achievementType),
                        ),
                        minHeight: 4,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title,
      String value,
      IconData icon,
      Color color,
      bool darkMode,
      bool isWeb,
      ) {
    return Container(
      padding: EdgeInsets.all(isWeb ? 16 : 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isWeb ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(AchievementLevel level, AchievementType achievementType) {
    if (achievementType == AchievementType.periodic) {
      switch (level) {
        case AchievementLevel.bronze:
          return const Color(0xFFCD7F32);
        case AchievementLevel.silver:
          return const Color(0xFFC0C0C0);
        case AchievementLevel.gold:
          return const Color(0xFFFFD700);
        default:
          return TAdminColors.primary;
      }
    } else {
      switch (level) {
        case AchievementLevel.bronze:
          return TAdminColors.success;
        case AchievementLevel.silver:
          return TAdminColors.warning;
        case AchievementLevel.gold:
          return TAdminColors.error;
        default:
          return TAdminColors.info;
      }
    }
  }

  IconData _getLevelIcon(AchievementLevel level, AchievementType achievementType) {
    if (achievementType == AchievementType.periodic) {
      switch (level) {
        case AchievementLevel.bronze:
          return Iconsax.medal_bold;
        case AchievementLevel.silver:
          return Iconsax.medal_star_bold;
        case AchievementLevel.gold:
          return Iconsax.crown_1_bold;
        default:
          return Iconsax.award_bold;
      }
    } else {
      switch (level) {
        case AchievementLevel.bronze:
          return Iconsax.flag_bold;
        case AchievementLevel.silver:
          return Iconsax.star_bold;
        case AchievementLevel.gold:
          return Iconsax.medal_bold;
        default:
          return Iconsax.award_bold;
      }
    }
  }
}