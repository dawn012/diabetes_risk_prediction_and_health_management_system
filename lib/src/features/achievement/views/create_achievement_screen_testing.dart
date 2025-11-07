import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../common/loaders/loaders.dart';

class CreateAchievementScreen extends StatefulWidget {
  const CreateAchievementScreen({super.key});

  @override
  State<CreateAchievementScreen> createState() => _CreateAchievementScreenState();
}

class _CreateAchievementScreenState extends State<CreateAchievementScreen> {
  final _db = FirebaseFirestore.instance;
  bool _isLoading = false;

  // 获取当前月份天数
  int _getCurrentMonthDays() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0).day;
  }

  // 所有预配置的成就
  List<Map<String, dynamic>> _getPredefinedAchievements() {
    final currentMonthDays = _getCurrentMonthDays();

    return [
      // ==================== 健康数据周期性成就 ====================
      {
        'achievementTitle': 'Blood Glucose Monitoring',
        'description': 'Track your blood glucose levels regularly',
        'achievementType': 'periodic',
        'dataType': 'bloodGlucose',
        'trackingStrategy': 'uniqueDays',
        'iconCodePoint': Icons.water_drop.codePoint,
        'makeupConfig': {
          'enabled': true,
          'maxDaysBack': 7,
          'maxMakeupCount': 3,
        },
        'levels': [
          {'level': 'bronze', 'criteria': 7, 'criteriaUnit': 'days', 'points': 20, 'isDynamic': false},
          {'level': 'silver', 'criteria': 15, 'criteriaUnit': 'days', 'points': 40, 'isDynamic': false},
          {'level': 'gold', 'criteria': currentMonthDays, 'criteriaUnit': 'days', 'points': 65, 'isDynamic': true},
        ],
      },
      {
        'achievementTitle': 'Blood Pressure Monitoring',
        'description': 'Monitor your blood pressure consistently',
        'achievementType': 'periodic',
        'dataType': 'bloodPressure',
        'trackingStrategy': 'uniqueDays',
        'iconCodePoint': Icons.monitor_heart.codePoint,
        'makeupConfig': {
          'enabled': true,
          'maxDaysBack': 7,
          'maxMakeupCount': 3,
        },
        'levels': [
          {'level': 'bronze', 'criteria': 7, 'criteriaUnit': 'days', 'points': 20, 'isDynamic': false},
          {'level': 'silver', 'criteria': 15, 'criteriaUnit': 'days', 'points': 40, 'isDynamic': false},
          {'level': 'gold', 'criteria': currentMonthDays, 'criteriaUnit': 'days', 'points': 65, 'isDynamic': true},
        ],
      },
      {
        'achievementTitle': 'Weight Tracking',
        'description': 'Keep track of your weight regularly',
        'achievementType': 'periodic',
        'dataType': 'bodyWeight',
        'trackingStrategy': 'uniqueDays',
        'iconCodePoint': Icons.monitor_weight.codePoint,
        'makeupConfig': {
          'enabled': true,
          'maxDaysBack': 7,
          'maxMakeupCount': 3,
        },
        'levels': [
          {'level': 'bronze', 'criteria': 4, 'criteriaUnit': 'days', 'points': 15, 'isDynamic': false},
          {'level': 'silver', 'criteria': 8, 'criteriaUnit': 'days', 'points': 30, 'isDynamic': false},
          {'level': 'gold', 'criteria': 12, 'criteriaUnit': 'days', 'points': 50, 'isDynamic': false},
        ],
      },
      {
        'achievementTitle': 'Physical Activity',
        'description': 'Stay active with regular exercise',
        'achievementType': 'periodic',
        'dataType': 'physicalActivity',
        'trackingStrategy': 'sumDuration',
        'iconCodePoint': Icons.directions_run.codePoint,
        'makeupConfig': {
          'enabled': true,
          'maxDaysBack': 7,
          'maxMakeupCount': 3,
        },
        'levels': [
          {'level': 'bronze', 'criteria': 150, 'criteriaUnit': 'minutes', 'points': 25, 'isDynamic': false},
          {'level': 'silver', 'criteria': 300, 'criteriaUnit': 'minutes', 'points': 50, 'isDynamic': false},
          {'level': 'gold', 'criteria': 450, 'criteriaUnit': 'minutes', 'points': 80, 'isDynamic': false},
        ],
      },
      {
        'achievementTitle': 'Steps Challenge',
        'description': 'Reach your daily step goals',
        'achievementType': 'periodic',
        'dataType': 'steps',
        'trackingStrategy': 'qualifiedDays',
        'iconCodePoint': Icons.directions_walk.codePoint,
        'makeupConfig': {
          'enabled': false,
        },
        'stepsConfig': {
          'dailyTarget': 8000,
        },
        'levels': [
          {'level': 'bronze', 'criteria': 7, 'criteriaUnit': 'days', 'points': 25, 'isDynamic': false},
          {'level': 'silver', 'criteria': 15, 'criteriaUnit': 'days', 'points': 50, 'isDynamic': false},
          {'level': 'gold', 'criteria': 22, 'criteriaUnit': 'days', 'points': 80, 'isDynamic': false},
        ],
      },

      // ==================== 社区周期性成就 ====================
      {
        'achievementTitle': 'Monthly Contributor',
        'description': 'Share valuable posts with the community this month.',
        'achievementType': 'periodic',
        'dataType': 'communityPost',
        'trackingStrategy': 'uniqueDays',
        'iconCodePoint': Icons.edit.codePoint,
        'makeupConfig': {'enabled': false},
        'levels': [
          {'level': 'bronze', 'criteria': 3, 'criteriaUnit': 'posts', 'points': 100, 'isDynamic': false},
          {'level': 'silver', 'criteria': 8, 'criteriaUnit': 'posts', 'points': 300, 'isDynamic': false},
          {'level': 'gold', 'criteria': 15, 'criteriaUnit': 'posts', 'points': 500, 'isDynamic': false},
        ],
      },
      {
        'achievementTitle': 'Community Engager',
        'description': 'Leave meaningful comments and support others’ posts.',
        'achievementType': 'periodic',
        'dataType': 'communityComment',
        'trackingStrategy': 'uniqueDays',
        'iconCodePoint': Icons.chat_bubble.codePoint,
        'makeupConfig': {'enabled': false},
        'levels': [
          {'level': 'bronze', 'criteria': 10, 'criteriaUnit': 'comments', 'points': 50, 'isDynamic': false},
          {'level': 'silver', 'criteria': 25, 'criteriaUnit': 'comments', 'points': 100, 'isDynamic': false},
          {'level': 'gold', 'criteria': 50, 'criteriaUnit': 'comments', 'points': 150, 'isDynamic': false},
        ],
      },
      {
        'achievementTitle': 'Daily Engager',
        'description': 'Stay active across multiple days this month.',
        'achievementType': 'periodic',
        'dataType': 'communityActiveDay',
        'trackingStrategy': 'uniqueDays',
        'iconCodePoint': Icons.calendar_view_day.codePoint,
        'makeupConfig': {'enabled': false},
        'levels': [
          {'level': 'bronze', 'criteria': 7, 'criteriaUnit': 'days', 'points': 100, 'isDynamic': false},
          {'level': 'silver', 'criteria': 15, 'criteriaUnit': 'days', 'points': 200, 'isDynamic': false},
          {'level': 'gold', 'criteria': 25, 'criteriaUnit': 'days', 'points': 300, 'isDynamic': false},
        ],
      },

      // 💪 Permanent Achievements（健康类长期追踪奖励）
      {
        'achievementTitle': 'Glucose Tracking Veteran',
        'description': 'Track your blood glucose consistently across months.',
        'achievementType': 'permanent',
        'dataType': 'glucoseGoldCount',
        'trackingStrategy': 'uniqueDays',
        'iconCodePoint': Icons.timeline.codePoint,
        'makeupConfig': {'enabled': false},
        'levels': [
          {'level': 'bronze', 'criteria': 3, 'criteriaUnit': 'golds', 'points': 0, 'isDynamic': false},
          {'level': 'silver', 'criteria': 6, 'criteriaUnit': 'golds', 'points': 0, 'isDynamic': false},
          {'level': 'gold', 'criteria': 12, 'criteriaUnit': 'golds', 'points': 0, 'isDynamic': false},
        ],
      },
      {
        'achievementTitle': 'Pressure Monitoring Pro',
        'description': 'Keep a steady habit of tracking your blood pressure.',
        'achievementType': 'permanent',
        'dataType': 'pressureGoldCount',
        'trackingStrategy': 'uniqueDays',
        'iconCodePoint': Icons.favorite.codePoint,
        'makeupConfig': {'enabled': false},
        'levels': [
          {'level': 'bronze', 'criteria': 3, 'criteriaUnit': 'golds', 'points': 0, 'isDynamic': false},
          {'level': 'silver', 'criteria': 6, 'criteriaUnit': 'golds', 'points': 0, 'isDynamic': false},
          {'level': 'gold', 'criteria': 12, 'criteriaUnit': 'golds', 'points': 0, 'isDynamic': false},
        ],
      },
      {
        'achievementTitle': 'Weight Management Expert',
        'description': 'Maintain a long-term weight tracking routine.',
        'achievementType': 'permanent',
        'dataType': 'weightGoldCount',
        'trackingStrategy': 'uniqueDays',
        'iconCodePoint': Icons.monitor_weight.codePoint,
        'makeupConfig': {'enabled': false},
        'levels': [
          {'level': 'bronze', 'criteria': 3, 'criteriaUnit': 'golds', 'points': 0, 'isDynamic': false},
          {'level': 'silver', 'criteria': 6, 'criteriaUnit': 'golds', 'points': 0, 'isDynamic': false},
          {'level': 'gold', 'criteria': 12, 'criteriaUnit': 'golds', 'points': 0, 'isDynamic': false},
        ],
      },
      {
        'achievementTitle': 'Fitness Champion',
        'description': 'Stay active month after month through consistent exercise tracking.',
        'achievementType': 'permanent',
        'dataType': 'activityGoldCount',
        'trackingStrategy': 'uniqueDays',
        'iconCodePoint': Icons.fitness_center.codePoint,
        'makeupConfig': {'enabled': false},
        'levels': [
          {'level': 'bronze', 'criteria': 3, 'criteriaUnit': 'golds', 'points': 0, 'isDynamic': false},
          {'level': 'silver', 'criteria': 6, 'criteriaUnit': 'golds', 'points': 0, 'isDynamic': false},
          {'level': 'gold', 'criteria': 12, 'criteriaUnit': 'golds', 'points': 0, 'isDynamic': false},
        ],
      },

      // 🏅 Collectors（收藏家成就）
      {
        'achievementTitle': 'Gold Collector',
        'description': 'Collect gold achievements across all categories.',
        'achievementType': 'permanent',
        'dataType': 'totalGold',
        'trackingStrategy': 'uniqueDays',
        'iconCodePoint': Icons.military_tech.codePoint,
        'makeupConfig': {'enabled': false},
        'levels': [
          {'level': 'bronze', 'criteria': 10, 'criteriaUnit': 'golds', 'points': 0, 'isDynamic': false},
          {'level': 'silver', 'criteria': 25, 'criteriaUnit': 'golds', 'points': 0, 'isDynamic': false},
          {'level': 'gold', 'criteria': 50, 'criteriaUnit': 'golds', 'points': 0, 'isDynamic': false},
        ],
      },
      {
        'achievementTitle': 'Silver Collector',
        'description': 'Collect silver achievements across all categories.',
        'achievementType': 'permanent',
        'dataType': 'totalSilver',
        'trackingStrategy': 'uniqueDays',
        'iconCodePoint': Icons.workspace_premium.codePoint,
        'makeupConfig': {'enabled': false},
        'levels': [
          {'level': 'bronze', 'criteria': 10, 'criteriaUnit': 'silvers', 'points': 0, 'isDynamic': false},
          {'level': 'silver', 'criteria': 25, 'criteriaUnit': 'silvers', 'points': 0, 'isDynamic': false},
          {'level': 'gold', 'criteria': 50, 'criteriaUnit': 'silvers', 'points': 0, 'isDynamic': false},
        ],
      },
      {
        'achievementTitle': 'Bronze Collector',
        'description': 'Collect bronze achievements across all categories.',
        'achievementType': 'permanent',
        'dataType': 'totalBronze',
        'trackingStrategy': 'uniqueDays',
        'iconCodePoint': Icons.emoji_events.codePoint,
        'makeupConfig': {'enabled': false},
        'levels': [
          {'level': 'bronze', 'criteria': 10, 'criteriaUnit': 'bronzes', 'points': 0, 'isDynamic': false},
          {'level': 'silver', 'criteria': 25, 'criteriaUnit': 'bronzes', 'points': 0, 'isDynamic': false},
          {'level': 'gold', 'criteria': 50, 'criteriaUnit': 'bronzes', 'points': 0, 'isDynamic': false},
        ],
      },

      // 📊 Lifetime Stats（终身统计）
      {
        'achievementTitle': 'Lifetime Steps',
        'description': 'Record a remarkable total step count on your journey.',
        'achievementType': 'permanent',
        'dataType': 'lifetimeSteps',
        'trackingStrategy': 'cumulative',
        'iconCodePoint': Icons.directions_walk.codePoint,
        'makeupConfig': {'enabled': false},
        'levels': [
          {'level': 'bronze', 'criteria': 100000, 'criteriaUnit': 'steps', 'points': 0, 'isDynamic': false},
          {'level': 'silver', 'criteria': 500000, 'criteriaUnit': 'steps', 'points': 0, 'isDynamic': false},
          {'level': 'gold', 'criteria': 1000000, 'criteriaUnit': 'steps', 'points': 0, 'isDynamic': false},
        ],
      },
      {
        'achievementTitle': 'Prolific Poster',
        'description': 'Share many posts over time and inspire the community.',
        'achievementType': 'permanent',
        'dataType': 'totalCommunityPosts',
        'trackingStrategy': 'cumulative',
        'iconCodePoint': Icons.article.codePoint,
        'makeupConfig': {'enabled': false},
        'levels': [
          {'level': 'bronze', 'criteria': 20, 'criteriaUnit': 'posts', 'points': 0, 'isDynamic': false},
          {'level': 'silver', 'criteria': 50, 'criteriaUnit': 'posts', 'points': 0, 'isDynamic': false},
          {'level': 'gold', 'criteria': 100, 'criteriaUnit': 'posts', 'points': 0, 'isDynamic': false},
        ],
      },
      // 🧩 Category Masters（分类专家）
      {
        'achievementTitle': 'General Discussion Master',
        'description': 'Actively participate in general discussion topics.',
        'achievementType': 'permanent',
        'dataType': 'generalDiscussionPosts',
        'trackingStrategy': 'cumulative',
        'iconCodePoint': Icons.forum.codePoint,
        'makeupConfig': {'enabled': false},
        'levels': [
          {'level': 'bronze', 'criteria': 5, 'criteriaUnit': 'posts', 'points': 0, 'isDynamic': false},
          {'level': 'silver', 'criteria': 15, 'criteriaUnit': 'posts', 'points': 0, 'isDynamic': false},
          {'level': 'gold', 'criteria': 30, 'criteriaUnit': 'posts', 'points': 0, 'isDynamic': false},
        ],
      },
      {
        'achievementTitle': 'Tip Giver',
        'description': 'Share helpful lifestyle and health tips with others.',
        'achievementType': 'permanent',
        'dataType': 'tipsPosts',
        'trackingStrategy': 'cumulative',
        'iconCodePoint': Icons.lightbulb.codePoint,
        'makeupConfig': {'enabled': false},
        'levels': [
          {'level': 'bronze', 'criteria': 5, 'criteriaUnit': 'posts', 'points': 0, 'isDynamic': false},
          {'level': 'silver', 'criteria': 15, 'criteriaUnit': 'posts', 'points': 0, 'isDynamic': false},
          {'level': 'gold', 'criteria': 30, 'criteriaUnit': 'posts', 'points': 0, 'isDynamic': false},
        ],
      },
      {
        'achievementTitle': 'Recipe Creator',
        'description': 'Share your own healthy and creative recipes.',
        'achievementType': 'permanent',
        'dataType': 'recipePosts',
        'trackingStrategy': 'cumulative',
        'iconCodePoint': Icons.restaurant_menu.codePoint,
        'makeupConfig': {'enabled': false},
        'levels': [
          {'level': 'bronze', 'criteria': 5, 'criteriaUnit': 'posts', 'points': 0, 'isDynamic': false},
          {'level': 'silver', 'criteria': 15, 'criteriaUnit': 'posts', 'points': 0, 'isDynamic': false},
          {'level': 'gold', 'criteria': 30, 'criteriaUnit': 'posts', 'points': 0, 'isDynamic': false},
        ],
      },
      {
        'achievementTitle': 'Story Teller',
        'description': 'Post inspiring personal stories that motivate others.',
        'achievementType': 'permanent',
        'dataType': 'storyPosts',
        'trackingStrategy': 'cumulative',
        'iconCodePoint': Icons.book.codePoint,
        'makeupConfig': {'enabled': false},
        'levels': [
          {'level': 'bronze', 'criteria': 3, 'criteriaUnit': 'posts', 'points': 0, 'isDynamic': false},
          {'level': 'silver', 'criteria': 10, 'criteriaUnit': 'posts', 'points': 0, 'isDynamic': false},
          {'level': 'gold', 'criteria': 20, 'criteriaUnit': 'posts', 'points': 0, 'isDynamic': false},
        ],
      },

      // 💞 Social Support Achievements（社交支持类）
      {
        'achievementTitle': 'Supportive Member',
        'description': 'Comment on many different posts to support others.',
        'achievementType': 'permanent',
        'dataType': 'uniqueCommentedPosts',
        'trackingStrategy': 'uniqueCount',
        'iconCodePoint': Icons.handshake.codePoint,
        'makeupConfig': {'enabled': false},
        'levels': [
          {'level': 'bronze', 'criteria': 10, 'criteriaUnit': 'uniquePosts', 'points': 0, 'isDynamic': false},
          {'level': 'silver', 'criteria': 30, 'criteriaUnit': 'uniquePosts', 'points': 0, 'isDynamic': false},
          {'level': 'gold', 'criteria': 60, 'criteriaUnit': 'uniquePosts', 'points': 0, 'isDynamic': false},
        ],
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final achievements = _getPredefinedAchievements();
    final periodicAchievements = achievements.where((a) => a['achievementType'] == 'periodic').toList();
    final permanentAchievements = achievements.where((a) => a['achievementType'] == 'permanent').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Achievements', style: Theme.of(context).textTheme.headlineMedium),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Card(
              color: TColors.info.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(TSizes.md),
                child: Row(
                  children: [
                    Icon(Iconsax.info_circle_bold, color: TColors.info),
                    const SizedBox(width: TSizes.md),
                    Expanded(
                      child: Text(
                        'Click on any achievement below to create it in Firestore',
                        style: TextStyle(color: TColors.info),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Periodic Achievements
            _buildSectionHeader('Periodic Achievements (${periodicAchievements.length})'),
            Text(
              'Monthly achievements with points',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),
            ...periodicAchievements.map((achievement) => _buildAchievementCard(achievement)),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Permanent Achievements
            _buildSectionHeader('Permanent Achievements (${permanentAchievements.length})'),
            Text(
              'Lifetime achievements without monthly reset',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),
            ...permanentAchievements.map((achievement) => _buildAchievementCard(achievement)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        color: TColors.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildAchievementCard(Map<String, dynamic> achievement) {
    final levels = achievement['levels'] as List;
    final isPeriodic = achievement['achievementType'] == 'periodic';

    return Card(
      margin: const EdgeInsets.only(bottom: TSizes.md),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(TSizes.sm),
              decoration: BoxDecoration(
                color: TColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
              ),
              child: Icon(
                IconData(achievement['iconCodePoint'] as int, fontFamily: 'MaterialIcons'),
                color: TColors.primary,
              ),
            ),
            title: Text(
              achievement['achievementTitle'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement['description'] as String),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildChip(isPeriodic ? 'Periodic' : 'Permanent',
                        isPeriodic ? TColors.primary : TColors.success),
                    _buildChip(achievement['dataType'] as String, Colors.grey),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              onPressed: () => _createAchievement(achievement),
              icon: const Icon(Icons.add_circle, color: TColors.primary, size: 32),
              tooltip: 'Create Achievement',
            ),
          ),
          // Levels Preview
          Padding(
            padding: const EdgeInsets.fromLTRB(TSizes.md, 0, TSizes.md, TSizes.md),
            child: Row(
              children: [
                _buildLevelPreview('B', levels[0], TColors.bronze),
                const SizedBox(width: TSizes.sm),
                _buildLevelPreview('S', levels[1], TColors.silver),
                const SizedBox(width: TSizes.sm),
                _buildLevelPreview('G', levels[2], TColors.gold),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildLevelPreview(String level, Map<String, dynamic> data, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(TSizes.sm),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              level,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 12,
              ),
            ),
            Text(
              '${data['criteria']} ${data['criteriaUnit']}',
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
            ),
            if (data['points'] > 0)
              Text(
                '${data['points']}pts',
                style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _createAchievement(Map<String, dynamic> achievementData) async {
    setState(() => _isLoading = true);

    try {
      // 生成 UUID v1
      final uuid = Uuid();
      final achievementId = uuid.v1();

      // 准备数据
      final data = {
        'achievementId': achievementId,
        'achievementTitle': achievementData['achievementTitle'],
        'description': achievementData['description'],
        'achievementType': achievementData['achievementType'],
        'dataType': achievementData['dataType'],
        'trackingStrategy': achievementData['trackingStrategy'],
        'iconCodePoint': achievementData['iconCodePoint'],
        'makeupConfig': achievementData['makeupConfig'],
        'levels': achievementData['levels'],
        'isActive': true,
        'createdAt': DateTime.now().millisecondsSinceEpoch, // 毫秒时间戳
      };

      // 如果有 stepsConfig，添加它
      if (achievementData.containsKey('stepsConfig')) {
        data['stepsConfig'] = achievementData['stepsConfig'];
      }

      // 创建文档，使用 UUID 作为文档 ID
      await _db.collection('achievements').doc(achievementId).set(data);

      TLoaders.successSnackBar(
        title: 'Success',
        message: '${achievementData['achievementTitle']} created successfully!',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to create achievement: ${e.toString()}',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}