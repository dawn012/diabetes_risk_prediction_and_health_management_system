import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../common/loaders/circular_loader.dart';
import '../../../common/widgets/appbar/appbar.dart';
import '../../../common/widgets/tab_selector/custom_tab_selector.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../../personalization/views/widgets/avatar_with_frame.dart';
import '../controllers/leaderboard_controller.dart';
import '../models/leaderboard_model.dart';
import 'leaderboard_rewards_info_screen.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LeaderboardController());
    final isDark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? TColors.darkBackground : Colors.grey[50],
      appBar: TAppBar(
        backgroundColor: TColors.primary,
        showBackArrow: true,
        title: Text(
          'Leaderboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: TColors.white),
        actions: [
          IconButton(
            icon: Icon(Iconsax.award_bold, color: Colors.white),
            onPressed: () => Get.to(() => const LeaderboardRewardsInfoScreen()),
            tooltip: 'Reward Rules',
          ),
        ],
      ),
      body: Column(
        children: [
          Obx(() => CustomTabSelector(
            tabs: const ["This Month", "Last Month"],
            selectedIndex: controller.selectedTab.value,
            onChanged: (index) => controller.changeTab(index),
          )),
          Obx(() {
            if (controller.selectedTab.value == 0) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: TSizes.defaultSpace, vertical: TSizes.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.refresh,
                      size: 14,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Auto-refreshes every 5 minutes',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return SizedBox.shrink();
            }
          }),
          Obx(() {
            if (controller.isLoading.value) {
              return Expanded(
                child: Center(
                  child: CircularLoader(message: 'Loading leaderboard...'),
                ),
              );
            }

            return Expanded(
              child: PageView(
                controller: controller.pageController,
                onPageChanged: (index) => controller.changeTab(index),
                physics: PageScrollPhysics(),
                children: [
                  _buildLeaderboardContent(controller, isDark, 0),
                  _buildLeaderboardContent(controller, isDark, 1),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLeaderboardContent(LeaderboardController controller, bool isDark, int tabIndex) {
    return Obx(() {
      if (controller.leaderboardData.isEmpty && controller.currentUserRankData.value == null) {
        return _buildEmptyLeaderboard(isDark);
      }

      return Column(
        children: [
          if (controller.leaderboardData.length >= 3)
            _buildTopThreeSection(controller, isDark),

          SizedBox(height: 20),
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
              constraints: BoxConstraints(
                minHeight: 400,
              ),
              decoration: BoxDecoration(
                color: isDark ? TColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : Colors.black)
                        .withOpacity(isDark ? 0.3 : 0.08),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(height: TSizes.defaultSpace),
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (scrollInfo) {
                        controller.updateScrollPosition(scrollInfo.metrics.pixels);
                        return true;
                      },
                      child: Stack(
                        children: [
                          AnimationLimiter(
                            child: ListView.separated(
                              controller: tabIndex == 0
                                  ? controller.scrollControllerThisMonth
                                  : controller.scrollControllerLastMonth,
                              padding: EdgeInsets.only(
                                left: TSizes.defaultSpace,
                                right: TSizes.defaultSpace,
                                top: TSizes.sm,
                                bottom: _shouldShowCurrentUserAtBottom(controller)
                                    ? 120
                                    : TSizes.defaultSpace + 20,
                              ),
                              itemCount: _getDisplayableItems(controller).length,
                              separatorBuilder: (context, index) => SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final leaderboardItem = _getDisplayableItems(controller)[index];

                                return AnimationConfiguration.staggeredList(
                                  position: index,
                                  duration: Duration(milliseconds: 600),
                                  child: SlideAnimation(
                                    verticalOffset: 50.0,
                                    child: FadeInAnimation(
                                      child: _buildLeaderboardItem(
                                        leaderboardItem,
                                        isDark,
                                        isInCorrectPosition: leaderboardItem.isCurrentUser,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (_shouldShowCurrentUserAtBottom(controller))
                            Obx(() {
                              final currentUser = controller.currentUserRankData.value!;
                              final isVisible = !controller.isCurrentUserVisible.value;

                              return AnimatedPositioned(
                                duration: Duration(milliseconds: 300),
                                bottom: isVisible ? 0 : -120,
                                left: 0,
                                right: 0,
                                child: _buildStickyCurrentUser(currentUser, isDark),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: TSizes.defaultSpace),
        ],
      );
    });
  }

  Widget _buildEmptyLeaderboard(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard_outlined,
            size: 80,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          SizedBox(height: TSizes.spaceBtwItems),
          Text(
            'No Rankings Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: TSizes.sm),
          Text(
            'Be the first to get on the leaderboard!',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[500] : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  List<LeaderboardModel> _getDisplayableItems(LeaderboardController controller) {
    return controller.leaderboardData;
  }

  bool _shouldShowCurrentUserAtBottom(LeaderboardController controller) {
    final currentUser = controller.currentUserRankData.value;
    return currentUser != null && currentUser.currentRank > 20;
  }

  Widget _buildTopThreeSection(LeaderboardController controller, bool isDark) {
    final topThree = controller.leaderboardData.take(3).toList();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: TSizes.defaultSpace, vertical: TSizes.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (topThree.length > 1)
            Expanded(child: _buildTopUser(topThree[1], 2, isDark)),
          Expanded(child: _buildTopUser(topThree[0], 1, isDark)),
          if (topThree.length > 2)
            Expanded(child: _buildTopUser(topThree[2], 3, isDark)),
        ],
      ),
    );
  }

  Widget _buildTopUser(LeaderboardModel data, int position, bool isDark) {
    Color borderColor;

    switch (position) {
      case 1:
        borderColor = TColors.gold;
        break;
      case 2:
        borderColor = TColors.silver;
        break;
      case 3:
        borderColor = TColors.bronze;
        break;
      default:
        borderColor = Colors.grey;
    }

    return Column(
      children: [
        if (position == 1) ...[
          Icon(Icons.emoji_events, color: TColors.gold, size: 32),
          SizedBox(height: 8),
        ] else
          SizedBox(height: 40),
        AvatarWithFrame(
          profileImageUrl: data.user.profileImg,
          frameIconUrl: data.user.currentAvatarFrameIconUrl,
          avatarSize: position == 1 ? 70 : 50,
          frameSize: position == 1 ? 85 : 65,
        ),
        SizedBox(height: 8),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: borderColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$position',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(height: 6),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: (position == 1) ? 100 : 80),
          child: Text(
            data.user.userName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? TColors.white : TColors.black,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(height: 2),
        Text(
          '${data.user.totalScore} pts.',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(
      LeaderboardModel data,
      bool isDark, {
        bool isInCorrectPosition = false,
      }) {
    Color backgroundColor = Colors.transparent;

    if (data.isCurrentUser && isInCorrectPosition) {
      backgroundColor =
          TColors.leaderboardCurrentUserBg.withOpacity(isDark ? 0.15 : 0.1);
    } else {
      switch (data.currentRank) {
        case 1:
          backgroundColor = TColors.gold.withOpacity(0.1);
          break;
        case 2:
          backgroundColor = TColors.silver.withOpacity(0.1);
          break;
        case 3:
          backgroundColor = TColors.bronze.withOpacity(0.1);
          break;
        default:
          backgroundColor = Colors.transparent;
      }
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: data.isCurrentUser && isInCorrectPosition
            ? Border.all(
          color: TColors.leaderboardCurrentUserBorder,
          width: 2,
        )
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            child: _buildRankChangeIndicator(data),
          ),
          SizedBox(width: 8),
          Container(
            width: 25,
            child: Text(
              '${data.currentRank}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: data.isCurrentUser
                    ? TColors.primary
                    : isDark
                    ? Colors.grey[400]
                    : Colors.grey[600],
              ),
            ),
          ),
          SizedBox(width: 4),
          AvatarWithFrame(
            profileImageUrl: data.user.profileImg,
            frameIconUrl: data.user.currentAvatarFrameIconUrl,
            avatarSize: 36,
            frameSize: 44,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    data.user.userName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: data.isCurrentUser
                          ? TColors.primary
                          : isDark
                          ? TColors.white
                          : TColors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (data.isCurrentUser) ...[
                  SizedBox(width: 6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: TColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'You',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: TColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 8),
          Text(
            '${data.user.totalScore} pts',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: data.isCurrentUser
                  ? TColors.primary
                  : isDark
                  ? Colors.grey[400]
                  : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyCurrentUser(LeaderboardModel data, bool isDark) {
    return Container(
      margin: EdgeInsets.all(TSizes.md),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TColors.leaderboardCurrentUserBg.withOpacity(isDark ? 0.2 : 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TColors.leaderboardCurrentUserBorder,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: TColors.primary.withOpacity(0.2),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            child: _buildRankChangeIndicator(data),
          ),
          SizedBox(width: 12),
          Container(
            width: 40,
            child: Text(
              '${data.currentRank}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: TColors.primary,
              ),
            ),
          ),
          SizedBox(width: 12),
          AvatarWithFrame(
            profileImageUrl: data.user.profileImg,
            frameIconUrl: data.user.currentAvatarFrameIconUrl,
            avatarSize: 48,
            frameSize: 58,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        data.user.userName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: TColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: TColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'You',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  'Scroll up to see your position',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Text(
            '${data.user.totalScore} pts',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: TColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankChangeIndicator(LeaderboardModel data) {
    if (data.rankChange == null) return SizedBox.shrink();

    switch (data.rankChange!) {
      case RankChange.up:
        return Icon(Icons.keyboard_arrow_up, color: Colors.green, size: 18);
      case RankChange.down:
        return Icon(Icons.keyboard_arrow_down, color: Colors.red, size: 18);
      case RankChange.same:
        return Icon(Icons.remove, color: Colors.grey, size: 18);
      case RankChange.new_entry:
        return Icon(Icons.fiber_new, color: TColors.primary, size: 16);
      default:
        return SizedBox.shrink();
    }
  }
}