import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../common/loaders/circular_loader.dart';
import '../../../common/widgets/tab_selector/custom_tab_selector.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../controllers/leaderboard_controller.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LeaderboardController());

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
          'Leaderboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                TColors.primary,
                TColors.primary.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Tab Section with enhanced design (always visible)
          Obx(() => CustomTabSelector(
              tabs: ["This Month", "Last Month"],
              selectedIndex: controller.selectedTab.value,
              onChanged: (index) => controller.changeTab(index),
            ),
          ),

          // Content that depends on loading state
          Obx(() {
            if (controller.isLoading.value) {
              return Expanded(
                child: Center(
                  child: CircularLoader(message: 'Loading leaderboard...'),
                ),
              );
            }

            return Expanded(
              child: Column(
                children: [
                  // Top 3 Section (Simple horizontal layout without background)
                  if (controller.leaderboardData.length >= 3)
                    _buildTopThreeSection(controller),

                  SizedBox(height: 20),

                  // Leaderboard List
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // View All Button
                          Padding(
                            padding: EdgeInsets.all(TSizes.defaultSpace),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    // Handle view all action
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'View All',
                                        style: TextStyle(
                                          color: TColors.primary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: TColors.primary,
                                        size: 12,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Leaderboard List
                          Expanded(
                            child: Column(
                              children: [
                                Expanded(
                                  child: AnimationLimiter(
                                    child: ListView.separated(
                                      padding: EdgeInsets.only(
                                        left: TSizes.defaultSpace,
                                        right: TSizes.defaultSpace,
                                        bottom: TSizes.defaultSpace,
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
                                              child: _buildLeaderboardItem(leaderboardItem),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),

                                // Current User Ranking (如果不在榜单上则显示在最下面)
                                if (_shouldShowCurrentUserAtBottom(controller))
                                  _buildCurrentUserRanking(controller.currentUserRankData.value!),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 获取要显示的项目（排除自己如果在榜单上）
  List<LeaderboardModel> _getDisplayableItems(LeaderboardController controller) {
    return controller.leaderboardData.where((item) =>
    !item.isCurrentUser || item.currentRank <= 20
    ).toList();
  }

  // 判断是否在底部显示当前用户排名
  bool _shouldShowCurrentUserAtBottom(LeaderboardController controller) {
    final currentUser = controller.currentUserRankData.value;
    return currentUser != null && currentUser.currentRank > 20;
  }

  Widget _buildTopThreeSection(LeaderboardController controller) {
    final topThree = controller.leaderboardData.take(3).toList();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Second place
          if (topThree.length > 1) _buildTopUser(topThree[1], 2),
          // First place (with crown)
          _buildTopUser(topThree[0], 1),
          // Third place
          if (topThree.length > 2) _buildTopUser(topThree[2], 3),
        ],
      ),
    );
  }

  Widget _buildTopUser(LeaderboardModel data, int position) {
    Color borderColor;

    switch (position) {
      case 1:
        borderColor = TColors.gold; // Gold
        break;
      case 2:
        borderColor = TColors.silver; // Silver
        break;
      case 3:
        borderColor = TColors.bronze; // Bronze
        break;
      default:
        borderColor = Colors.grey;
    }

    return Column(
      children: [
        // Crown for first place only
        if (position == 1) ...[
          Icon(
            Icons.emoji_events,
            color: TColors.gold,
            size: 32,
          ),
          SizedBox(height: 8),
        ],

        // Profile Picture with colored border
        Container(
          width: (position == 1) ? 95 : 70,
          height: (position == 1) ? 95 : 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 3),
          ),
          child: CircleAvatar(
            radius: 32,
            backgroundColor: Colors.grey[200],
            child: Text(
              data.user.userName[0].toUpperCase(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: TColors.primary,
              ),
            ),
          ),
        ),

        SizedBox(height: 8),

        // Rank circle
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

        SizedBox(height: 8),

        // Username
        Text(
          data.user.userName,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: TColors.black,
          ),
          textAlign: TextAlign.center,
        ),

        // Points
        Text(
          '${data.user.totalScore} pts.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(LeaderboardModel data) {
    Color backgroundColor = Colors.transparent;

    // 根据排名设置背景色
    switch (data.currentRank) {
      case 1:
        backgroundColor = TColors.gold.withOpacity(0.1); // Gold background
        break;
      case 2:
        backgroundColor = TColors.silver.withOpacity(0.1); // Silver background
        break;
      case 3:
        backgroundColor = TColors.bronze.withOpacity(0.1); // Bronze background
        break;
      default:
        backgroundColor = Colors.transparent;
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Rank change indicator
          Container(
            width: 20,
            child: _buildRankChangeIndicator(data),
          ),

          SizedBox(width: 8),

          // Rank number
          Container(
            width: 30,
            child: Text(
              '${data.currentRank}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),

          SizedBox(width: 12),

          // Profile Picture
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[200],
            child: Text(
              data.user.userName[0].toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: TColors.primary,
              ),
            ),
          ),

          SizedBox(width: 12),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.user.userName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: TColors.black,
                  ),
                ),
              ],
            ),
          ),

          // Score
          Text(
            '${data.user.totalScore} pts',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
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
        return Icon(
          Icons.keyboard_arrow_up,
          color: Colors.green,
          size: 18,
        );
      case RankChange.down:
        return Icon(
          Icons.keyboard_arrow_down,
          color: Colors.red,
          size: 18,
        );
      case RankChange.same:
        return Icon(
          Icons.remove,
          color: Colors.grey,
          size: 18,
        );
      case RankChange.new_entry:
        return Icon(
          Icons.fiber_new,
          color: TColors.primary,
          size: 16,
        );
      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildCurrentUserRanking(LeaderboardModel data) {
    return Container(
      margin: EdgeInsets.all(TSizes.defaultSpace),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TColors.primary.withOpacity(0.1), // 浅主题色背景
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Rank change indicator
          Container(
            width: 20,
            child: _buildRankChangeIndicator(data),
          ),

          SizedBox(width: 8),

          // Rank number
          Container(
            width: 30,
            child: Text(
              '${data.currentRank}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: TColors.primary,
              ),
            ),
          ),

          SizedBox(width: 12),

          // Profile Picture
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[200],
            child: Text(
              data.user.userName[0].toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: TColors.primary,
              ),
            ),
          ),

          SizedBox(width: 12),

          // User Info
          Expanded(
            child: Text(
              data.user.userName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: TColors.primary,
              ),
            ),
          ),

          // Score
          Text(
            '${data.user.totalScore} pts',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}