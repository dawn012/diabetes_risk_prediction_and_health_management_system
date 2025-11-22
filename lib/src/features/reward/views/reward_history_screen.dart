import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../common/loaders/circular_loader.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/formatters/formatter.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../controllers/reward_controller.dart';

class RewardHistoryScreen extends StatelessWidget {
  const RewardHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RewardController());
    final isDark = THelperFunctions.isDarkMode(context);

    // Fetch history on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchUserRewardHistory();
    });

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: TColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Reward History',
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
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularLoader(message: 'Loading history...'),
          );
        }

        if (controller.userRewardHistory.isEmpty) {
          return _buildEmptyState(isDark);
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchUserRewardHistory(),
          child: ListView.separated(
            padding: EdgeInsets.all(TSizes.defaultSpace),
            itemCount: controller.userRewardHistory.length,
            separatorBuilder: (context, index) => SizedBox(height: TSizes.sm),
            itemBuilder: (context, index) {
              final userReward = controller.userRewardHistory[index];
              return _buildHistoryCard(userReward, isDark);
            },
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.receipt_text_bold,
            size: 80,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          SizedBox(height: TSizes.spaceBtwItems),
          Text(
            'No Reward History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          SizedBox(height: TSizes.sm),
          Text(
            'Your redeemed rewards will appear here',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[500] : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(dynamic userReward, bool isDark) {
    final reward = userReward.reward;
    final formattedDate = TFormatter.formatHistoryDateTime(userReward.redeemedAt);

    return Container(
      padding: EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: isDark ? TColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: isDark ? TColors.darkGrey : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: reward.icon,
                fit: BoxFit.contain,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(
                    color: TColors.primary,
                    strokeWidth: 2,
                  ),
                ),
                errorWidget: (context, url, error) => Icon(
                  Iconsax.gallery_slash_bold,
                  color: TColors.darkGrey,
                  size: 24,
                ),
              ),
            ),
          ),

          SizedBox(width: TSizes.md),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  reward.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : TColors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: 8),

                // Points and Date in separate rows
                Row(
                  children: [
                    Icon(
                      Iconsax.coin_1_bold,
                      color: TColors.warning,
                      size: 13,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${userReward.pointsSpent} points',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? TColors.darkGrey : TColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 4),

                // Date
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start, // 顶部对齐
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 2), // 稍微向下调整图标位置
                      child: Icon(
                        Iconsax.clock_bold,
                        color: isDark ? TColors.darkGrey : TColors.textSecondary,
                        size: 12,
                      ),
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? TColors.darkGrey : TColors.textSecondary,
                        ),
                        maxLines: 2, // 允许最多两行
                        overflow: TextOverflow.visible, // 允许文字溢出显示
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status Badge - 放在最右边
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: TColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Iconsax.tick_circle_bold,
                  color: TColors.success,
                  size: 14,
                ),
                SizedBox(width: 4),
                Text(
                  'Redeemed',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: TColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}