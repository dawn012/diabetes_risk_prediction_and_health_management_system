import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../common/loaders/circular_loader.dart';
import '../../../common/widgets/tab_selector/custom_tab_selector.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../controllers/user_achievement_controller.dart';
import '../controllers/achievement_controller.dart';
import '../models/achievement_model.dart';
import 'leaderboard_screen.dart';

class UserAchievementScreen extends StatelessWidget {
  const UserAchievementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 确保 AchievementController 先初始化
    Get.put(AchievementController());
    final controller = Get.put(UserAchievementController());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: TColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Achievement',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return CircularLoader(message: 'Loading achievements...');
        }

        return Column(
          children: [
            // Tab Section with slide animation
            CustomTabSelector(
              tabs: ["Periodic", "Permanent"],
              selectedIndex: controller.selectedTab.value,
              onChanged: (index) => controller.changeTab(index),
            ),

            // Filter Chips
            Container(
              height: 50,
              margin: EdgeInsets.only(left: TSizes.defaultSpace),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip('All', 'all', controller),
                  SizedBox(width: TSizes.sm),
                  _buildFilterChip('Locked', 'locked', controller),
                  SizedBox(width: TSizes.sm),
                  _buildFilterChip('Unlocked', 'unlocked', controller),
                  SizedBox(width: TSizes.sm),
                  _buildFilterChip('Bronze', 'bronze', controller),
                  SizedBox(width: TSizes.sm),
                  _buildFilterChip('Silver', 'silver', controller),
                  SizedBox(width: TSizes.sm),
                  _buildFilterChip('Gold', 'gold', controller),
                  SizedBox(width: TSizes.defaultSpace),
                ],
              ),
            ),

            SizedBox(height: TSizes.spaceBtwItems),

            // Progress Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: TColors.black,
                    ),
                  ),
                  // Only show progress counter when filter is 'all'
                  if (controller.shouldShowProgress)
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: TColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 300),
                        child: Text(
                          '${controller.completedCount}/${controller.totalCount} completed',
                          key: ValueKey('${controller.completedCount}-${controller.totalCount}'),
                          style: TextStyle(
                            fontSize: 14,
                            color: TColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: TSizes.spaceBtwItems),

            // Achievement List
            Expanded(
              child: _buildAchievementList(controller),
            ),
          ],
        );
      }),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [TColors.primary, TColors.primary.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: TColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () {
            Get.to(() => const LeaderboardScreen());
          },
          child: Icon(
            Icons.leaderboard,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementList(UserAchievementController controller) {
    return Obx(() {
      final filteredAchievements = controller.filteredAchievements;

      if (filteredAchievements.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
        itemCount: filteredAchievements.length,
        itemBuilder: (context, index) {
          final achievementData = filteredAchievements[index];

          return AnimatedContainer(
            duration: Duration(milliseconds: 300 + (index * 50)),
            curve: Curves.easeOutBack,
            child: SlideTransition(
              position: AlwaysStoppedAnimation(Offset.zero),
              child: FadeTransition(
                opacity: AlwaysStoppedAnimation(1.0),
                child: _buildAchievementCard(achievementData, controller),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          SizedBox(height: TSizes.spaceBtwItems),
          Text(
            'No achievements found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: TSizes.sm),
          Text(
            'Try changing your filter settings',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, UserAchievementController controller) {
    return Obx(() {
      final isSelected = controller.selectedFilter.value == value;
      return GestureDetector(
        onTap: () => controller.changeFilter(value),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? TColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected ? TColors.primary : Colors.grey[300]!,
              width: 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: TColors.primary.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ] : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (value == 'locked') ...[
                Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
                SizedBox(width: 4),
              ] else if (value != 'all' && value != 'unlocked') ...[
                Icon(
                  Icons.emoji_events,
                  size: 16,
                  color: isSelected ? Colors.white : _getMedalColor(value),
                ),
                SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildAchievementCard(
      Map<String, dynamic> achievementData,
      UserAchievementController controller
      ) {
    AchievementModel achievement = achievementData['achievement'] as AchievementModel;
    final progress = controller.getProgress(achievementData);
    final progressText = controller.getProgressText(achievementData);
    final medalType = controller.getMedalType(achievementData);
    final isLocked = achievementData['isLocked'] as bool;

    return Obx(() {
      final isExpanded = controller.isAchievementExpanded(achievement.achievementId);

      return Container(
        margin: EdgeInsets.only(bottom: TSizes.spaceBtwItems),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Main Achievement Card
            InkWell(
              onTap: () => controller.toggleAchievement(achievement.achievementId),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: EdgeInsets.all(TSizes.lg),
                child: Row(
                  children: [
                    // Achievement Icon with modern design
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getMedalColor(medalType).withOpacity(0.2),
                            _getMedalColor(medalType).withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _getMedalColor(medalType).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Base icon
                          Icon(
                            _getAchievementIcon(achievement.achievementTitle),
                            color: isLocked
                                ? Colors.grey[400]
                                : _getMedalColor(medalType),
                            size: 32,
                          ),
                          // Lock overlay for locked achievements
                          if (isLocked)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                Icons.lock,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          // Medal indicator for unlocked achievements
                          if (!isLocked && medalType != 'unlocked')
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: _getMedalColor(medalType),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.emoji_events,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    SizedBox(width: TSizes.spaceBtwItems),

                    // Achievement Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  achievement.achievementTitle,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isLocked
                                        ? Colors.grey[500]
                                        : TColors.black,
                                  ),
                                ),
                              ),
                              AnimatedRotation(
                                duration: Duration(milliseconds: 300),
                                turns: isExpanded ? 0.5 : 0.0,
                                child: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: TSizes.xs),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                progressText,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isLocked
                                      ? Colors.grey[500]
                                      : TColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: TSizes.sm),

                          // Modern Progress Bar
                          Stack(
                            children: [
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              AnimatedContainer(
                                duration: Duration(milliseconds: 500),
                                width: MediaQuery.of(Get.context!).size.width * 0.6 * progress,
                                height: 8,
                                decoration: BoxDecoration(
                                  gradient: isLocked
                                      ? LinearGradient(colors: [Colors.grey[400]!, Colors.grey[400]!])
                                      : LinearGradient(
                                    colors: [
                                      TColors.primary,
                                      TColors.primary.withOpacity(0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: TSizes.xs),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isLocked
                                    ? 'Locked'
                                    : achievementData['currentLevel'] == 'none'
                                    ? 'No Level'
                                    : '${achievementData['currentLevel']} Level',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isLocked
                                      ? Colors.grey[500]
                                      : TColors.primary,
                                  fontWeight: FontWeight.w600,
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

            // Expanded Description with animation
            AnimatedSize(
              duration: Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? _buildExpandedContent(achievementData, controller)
                  : SizedBox.shrink(),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildExpandedContent(
      Map<String, dynamic> achievementData,
      UserAchievementController controller) {

    AchievementModel achievement = achievementData['achievement'] as AchievementModel;
    final isLocked = achievementData['isLocked'] as bool;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(TSizes.lg, 0, TSizes.lg, TSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 1,
            color: Colors.grey[200],
            margin: EdgeInsets.only(bottom: TSizes.md),
          ),

          // Description Section
          FadeTransition(
            opacity: AlwaysStoppedAnimation(1.0),
            child: SlideTransition(
              position: AlwaysStoppedAnimation(Offset.zero),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isLocked
                          ? Colors.grey[500]
                          : TColors.black,
                    ),
                  ),
                  SizedBox(height: TSizes.sm),
                  Text(
                    achievement.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isLocked
                          ? Colors.grey[500]
                          : Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Levels Section
          if (achievement.levels.isNotEmpty) ...[
            SizedBox(height: TSizes.md),
            Text(
              'Levels',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isLocked
                    ? Colors.grey[500]
                    : TColors.black,
              ),
            ),
            SizedBox(height: TSizes.sm),

            // Animated level cards
            ...achievement.levels.asMap().entries.map((entry) {
              int index = entry.key;
              var level = entry.value;
              String currentLevel = achievementData['currentLevel'] as String;
              bool isCurrentLevel = !isLocked && currentLevel == level.level;
              bool isAchieved = !isLocked && controller.isLevelAchieved(achievementData, level.level);

              return AnimatedContainer(
                duration: Duration(milliseconds: 300 + (index * 100)),
                margin: EdgeInsets.only(bottom: TSizes.xs),
                padding: EdgeInsets.all(TSizes.md),
                decoration: BoxDecoration(
                  color: isLocked
                      ? Colors.grey[100]
                      : isCurrentLevel
                      ? _getMedalColor(level.level.toLowerCase()).withOpacity(0.1)
                      : isAchieved
                      ? _getMedalColor(level.level.toLowerCase()).withOpacity(0.05)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLocked
                        ? Colors.grey[300]!
                        : isCurrentLevel
                        ? _getMedalColor(level.level.toLowerCase()).withOpacity(0.3)
                        : isAchieved
                        ? _getMedalColor(level.level.toLowerCase()).withOpacity(0.2)
                        : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    // Medal icon
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isLocked
                            ? Colors.grey[300]
                            : _getMedalColor(level.level.toLowerCase()).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.emoji_events,
                        color: isLocked
                            ? Colors.grey[500]
                            : _getMedalColor(level.level.toLowerCase()),
                        size: 18,
                      ),
                    ),
                    SizedBox(width: TSizes.sm),

                    // Level info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${level.level} Level',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isLocked
                                      ? Colors.grey[500]
                                      : TColors.black,
                                ),
                              ),
                              if (isLocked)
                                Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Icon(
                                    Icons.lock_outline,
                                    size: 14,
                                    color: Colors.grey[400],
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            '${level.criteria} ${level.criteriaUnit} • ${level.points} points',
                            style: TextStyle(
                              fontSize: 12,
                              color: isLocked
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Achievement status
                    if (!isLocked) ...[
                      if (isAchieved)
                        Icon(
                          Icons.check_circle,
                          color: _getMedalColor(level.level.toLowerCase()),
                          size: 20,
                        )
                      else if (isCurrentLevel)
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: TColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.trending_up,
                            color: TColors.primary,
                            size: 16,
                          ),
                        )
                      else
                        Icon(
                          Icons.radio_button_unchecked,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  IconData _getAchievementIcon(String title) {
    switch (title.toLowerCase()) {
      case 'track blood glucose':
        return Icons.water_drop_outlined;
      case 'track blood pressure':
        return Icons.monitor_heart_outlined;
      case 'track body weight':
        return Icons.fitness_center_outlined;
      case 'exercise':
        return Icons.directions_run_outlined;
      case 'generate meal plan':
        return Icons.restaurant_menu_outlined;
      case 'track sleep':
        return Icons.bedtime_outlined;
      default:
        return Icons.emoji_events_outlined;
    }
  }

  Color _getMedalColor(String medalType) {
    switch (medalType.toLowerCase()) {
      case 'gold':
        return TColors.gold; // Modern gold
      case 'silver':
        return TColors.silver; // Modern silver
      case 'bronze':
        return TColors.bronze; // Modern bronze
      case 'locked':
        return Colors.grey[500]!;
      case 'unlocked':
      default:
        return Colors.grey[400]!;
    }
  }
}