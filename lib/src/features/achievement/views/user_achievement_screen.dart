// user_achievement_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/loaders/circular_loader.dart';
import '../../../common/widgets/tab_selector/custom_tab_selector.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/device/device_utility.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../controllers/user_achievement_controller.dart';
import '../controllers/achievement_controller.dart';
import '../models/achievement_display_data.dart';
import 'leaderboard_screen.dart';

class UserAchievementScreen extends StatelessWidget {
  const UserAchievementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);

    // 确保 AchievementController 先初始化
    Get.put(AchievementController());
    final controller = Get.put(UserAchievementController());

    return Scaffold(
      backgroundColor: isDark ? TColors.darkBackground : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: TColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
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
          return const CircularLoader(message: 'Loading achievements...');
        }

        return Column(
          children: [
            // Tab Section with slide animation
            CustomTabSelector(
              tabs: const ["Periodic", "Permanent"],
              selectedIndex: controller.selectedTab.value,
              onChanged: (index) => controller.changeTab(index),
            ),

            // PageView for swipeable content
            Expanded(
              child: PageView(
                controller: controller.pageController,
                onPageChanged: (index) => controller.changeTab(index),
                physics: PageScrollPhysics(),
                children: [
                  // Periodic Tab Content
                  _buildTabContent(controller, isDark),
                  // Permanent Tab Content
                  _buildTabContent(controller, isDark),
                ],
              ),
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
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () {
            Get.to(() => const LeaderboardScreen());
          },
          child: const Icon(
            Icons.leaderboard,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(UserAchievementController controller, bool isDark) {
    return Column(
      children: [
        // Filter Chips
        Container(
          height: 50,
          margin: const EdgeInsets.only(left: TSizes.defaultSpace, top: TSizes.sm),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip('All', 'all', controller, isDark),
              const SizedBox(width: TSizes.sm),
              _buildFilterChip('Locked', 'locked', controller, isDark),
              const SizedBox(width: TSizes.sm),
              _buildFilterChip('Unlocked', 'unlocked', controller, isDark),
              const SizedBox(width: TSizes.sm),
              _buildFilterChip('Bronze', 'bronze', controller, isDark),
              const SizedBox(width: TSizes.sm),
              _buildFilterChip('Silver', 'silver', controller, isDark),
              const SizedBox(width: TSizes.sm),
              _buildFilterChip('Gold', 'gold', controller, isDark),
              const SizedBox(width: TSizes.defaultSpace),
            ],
          ),
        ),

        const SizedBox(height: TSizes.spaceBtwItems),

        // Progress Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? TColors.white : TColors.black,
                ),
              ),
              // Only show progress counter when filter is 'all'
              if (controller.shouldShowProgress)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: TColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      '${controller.completedCount}/${controller.totalCount} completed',
                      key: ValueKey('${controller.completedCount}-${controller.totalCount}'),
                      style: const TextStyle(
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

        const SizedBox(height: TSizes.spaceBtwItems),

        // Achievement List
        Expanded(
          child: _buildAchievementList(controller, isDark),
        ),
      ],
    );
  }

  Widget _buildAchievementList(UserAchievementController controller, bool isDark) {
    return Obx(() {
      final filteredAchievements = controller.filteredAchievements;

      if (filteredAchievements.isEmpty) {
        return _buildEmptyState(isDark);
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
        itemCount: filteredAchievements.length,
        itemBuilder: (context, index) {
          final achievementData = filteredAchievements[index];

          return AnimatedContainer(
            duration: Duration(milliseconds: 300 + (index * 50)),
            curve: Curves.easeOutBack,
            child: _buildAchievementCard(achievementData, controller, context, isDark),
          );
        },
      );
    });
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 80,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          Text(
            'No achievements found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey,
            ),
          ),
          const SizedBox(height: TSizes.sm),
          Text(
            'Try changing your filter settings',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[500] : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, UserAchievementController controller, bool isDark) {
    return Obx(() {
      final isSelected = controller.selectedFilter.value == value;
      return GestureDetector(
        onTap: () => controller.changeFilter(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? TColors.primary
                : isDark ? TColors.chipBackgroundDark : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected
                  ? TColors.primary
                  : isDark ? TColors.cardBorderDark : Colors.grey[300]!,
              width: 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: TColors.primary.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
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
                  color: isSelected
                      ? Colors.white
                      : isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(width: 4),
              ] else if (value != 'all' && value != 'unlocked') ...[
                Icon(
                  Icons.emoji_events,
                  size: 16,
                  color: isSelected ? Colors.white : _getMedalColor(value),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : isDark ? Colors.grey[300] : Colors.grey[700],
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
      AchievementDisplayData achievementData,
      UserAchievementController controller,
      BuildContext context,
      bool isDark,
      ) {
    final achievement = achievementData.achievement;
    final progress = controller.getProgress(achievementData);
    final progressText = controller.getProgressText(achievementData);
    final medalType = controller.getMedalType(achievementData);
    final isLocked = achievementData.isLocked;

    return Obx(() {
      final isExpanded = controller.isAchievementExpanded(achievement.achievementId);

      return Container(
        margin: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
        decoration: BoxDecoration(
          color: isDark ? TColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : Colors.black).withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
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
                padding: const EdgeInsets.all(TSizes.md), // 🔥 减少内边距
                child: Row(
                  children: [
                    // Achievement Icon - 缩小尺寸
                    Container(
                      width: 55, // 🔥 从 64 缩小到 50
                      height: 55, // 🔥 从 64 缩小到 50
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getMedalColor(medalType).withOpacity(0.2),
                            _getMedalColor(medalType).withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14), // 🔥 稍微缩小圆角
                        border: Border.all(
                          color: _getMedalColor(medalType).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Base icon - 缩小图标
                          Icon(
                            achievement.iconData,
                            color: isLocked
                                ? (isDark ? Colors.grey[600] : Colors.grey[400])
                                : _getMedalColor(medalType),
                            size: 28, // 🔥 从 32 缩小到 24
                          ),
                          // Lock overlay for locked achievements
                          if (isLocked)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.lock,
                                color: Colors.white,
                                size: 18, // 🔥 从 20 缩小到 16
                              ),
                            ),
                          // Medal indicator for unlocked achievements
                          if (!isLocked && medalType != 'unlocked')
                            Positioned(
                              top: 3, // 🔥 调整位置
                              right: 3, // 🔥 调整位置
                              child: Container(
                                width: 18, // 🔥 从 20 缩小到 16
                                height: 18, // 🔥 从 20 缩小到 16
                                decoration: BoxDecoration(
                                  color: _getMedalColor(medalType),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.emoji_events,
                                  color: Colors.white,
                                  size: 12, // 🔥 从 12 缩小到 10
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(width: TSizes.sm + 5), // 🔥 减少间距

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
                                    fontSize: 16, // 🔥 从 18 缩小到 16
                                    fontWeight: FontWeight.bold,
                                    color: isLocked
                                        ? (isDark ? Colors.grey[400] : Colors.grey[500])
                                        : isDark ? TColors.white : TColors.black,
                                  ),
                                  maxLines: 2, // 🔥 限制标题行数
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              AnimatedRotation(
                                duration: const Duration(milliseconds: 300),
                                turns: isExpanded ? 0.5 : 0.0,
                                child: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                                  size: 20, // 🔥 明确设置大小
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: TSizes.xs),

                          // 🔥 修复进度文本溢出问题
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Progress',
                                      style: TextStyle(
                                        fontSize: 12, // 🔥 从 14 缩小到 12
                                        color: isDark ? Colors.grey[400] : Colors.grey,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Flexible(
                                    child: Text(
                                      progressText,
                                      style: TextStyle(
                                        fontSize: 12, // 🔥 从 14 缩小到 12
                                        color: isLocked
                                            ? (isDark ? Colors.grey[400] : Colors.grey[500])
                                            : TColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: TSizes.xs),

                          // Modern Progress Bar
                          Stack(
                            children: [
                              Container(
                                height: 6, // 🔥 从 8 缩小到 6
                                decoration: BoxDecoration(
                                  color: isDark ? TColors.darkContainer : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                width: (TDeviceUtils.getScreenWidth(context) * 0.6) * progress,
                                height: 6, // 🔥 从 8 缩小到 6
                                decoration: BoxDecoration(
                                  gradient: isLocked
                                      ? LinearGradient(
                                      colors: isDark
                                          ? [Colors.grey[700]!, Colors.grey[700]!]
                                          : [Colors.grey[400]!, Colors.grey[400]!]
                                  )
                                      : const LinearGradient(
                                    colors: [
                                      TColors.primary,
                                      TColors.primary,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: TSizes.xs),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  isLocked
                                      ? 'Locked'
                                      : achievementData.currentLevel == UserAchievementLevel.none
                                      ? 'No Level'
                                      : '${achievementData.currentLevel.displayName} Level',
                                  style: TextStyle(
                                    fontSize: 10, // 🔥 从 12 缩小到 10
                                    color: isDark ? Colors.grey[400] : Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  '${(progress * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 10, // 🔥 从 12 缩小到 10
                                    color: isLocked
                                        ? (isDark ? Colors.grey[400] : Colors.grey[500])
                                        : TColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
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
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? _buildExpandedContent(achievementData, controller, isDark)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildExpandedContent(
      AchievementDisplayData achievementData,
      UserAchievementController controller,
      bool isDark,
      ) {
    final achievement = achievementData.achievement;
    final isLocked = achievementData.isLocked;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(TSizes.lg, 0, TSizes.lg, TSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 1,
            color: isDark ? TColors.cardBorderDark : Colors.grey[200],
            margin: const EdgeInsets.only(bottom: TSizes.md),
          ),

          // Description Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isLocked
                      ? (isDark ? Colors.grey[400] : Colors.grey[500])
                      : isDark ? TColors.white : TColors.black,
                ),
              ),
              const SizedBox(height: TSizes.sm),
              Text(
                achievement.description,
                style: TextStyle(
                  fontSize: 14,
                  color: isLocked
                      ? (isDark ? Colors.grey[500] : Colors.grey[500])
                      : isDark ? Colors.grey[400] : Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ],
          ),

          // Levels Section
          if (achievement.levels.isNotEmpty) ...[
            const SizedBox(height: TSizes.md),
            Text(
              'Levels',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isLocked
                    ? (isDark ? Colors.grey[400] : Colors.grey[500])
                    : isDark ? TColors.white : TColors.black,
              ),
            ),
            const SizedBox(height: TSizes.sm),

            // Animated level cards
            ...achievement.levels.asMap().entries.map((entry) {
              final index = entry.key;
              final level = entry.value;
              final currentLevel = achievementData.currentLevel;
              final isCurrentLevel = !isLocked && currentLevel == level.level;
              final isAchieved = !isLocked && controller.isLevelAchieved(achievementData, level.level);

              return AnimatedContainer(
                duration: Duration(milliseconds: 300 + (index * 100)),
                margin: const EdgeInsets.only(bottom: TSizes.xs),
                padding: const EdgeInsets.all(TSizes.md),
                decoration: BoxDecoration(
                  color: isLocked
                      ? (isDark ? TColors.darkContainer : Colors.grey[100])
                      : isCurrentLevel
                      ? _getMedalColor(level.level.value.toLowerCase()).withOpacity(0.1)
                      : isAchieved
                      ? _getMedalColor(level.level.value.toLowerCase()).withOpacity(0.05)
                      : isDark ? TColors.darkContainer : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLocked
                        ? (isDark ? Colors.grey[700]! : Colors.grey[300]!)
                        : isCurrentLevel
                        ? _getMedalColor(level.level.value.toLowerCase()).withOpacity(0.3)
                        : isAchieved
                        ? _getMedalColor(level.level.value.toLowerCase()).withOpacity(0.2)
                        : isDark ? Colors.grey[700]! : Colors.grey[200]!,
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
                            ? (isDark ? Colors.grey[700] : Colors.grey[300])
                            : _getMedalColor(level.level.value.toLowerCase()).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.emoji_events,
                        color: isLocked
                            ? (isDark ? Colors.grey[500] : Colors.grey[500])
                            : _getMedalColor(level.level.value.toLowerCase()),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: TSizes.sm),

                    // Level info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${level.level.displayName} Level',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isLocked
                                      ? (isDark ? Colors.grey[400] : Colors.grey[500])
                                      : isDark ? TColors.white : TColors.black,
                                ),
                              ),
                              if (isLocked)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Icon(
                                    Icons.lock_outline,
                                    size: 14,
                                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            '${level.criteria} ${level.criteriaUnit} • ${level.points} points',
                            style: TextStyle(
                              fontSize: 12,
                              color: isLocked
                                  ? (isDark ? Colors.grey[500] : Colors.grey[400])
                                  : isDark ? Colors.grey[400] : Colors.grey[600],
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
                          color: _getMedalColor(level.level.value.toLowerCase()),
                          size: 20,
                        )
                      else if (isCurrentLevel)
                        Container(
                          padding: const EdgeInsets.all(4),
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
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
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

  /// 根据当前 tab 决定滑动方向
  ScrollPhysics _getPagePhysics(UserAchievementController controller) {
    // 在 PageView 中，我们不能完全禁止某个方向的滑动
    // 但我们可以通过监听来处理
    return PageScrollPhysics();
  }

  Color _getMedalColor(String medalType) {
    switch (medalType.toLowerCase()) {
      case 'gold':
        return TColors.gold;
      case 'silver':
        return TColors.silver;
      case 'bronze':
        return TColors.bronze;
      case 'locked':
        return Colors.grey[500]!;
      case 'unlocked':
      default:
        return Colors.grey[400]!;
    }
  }
}