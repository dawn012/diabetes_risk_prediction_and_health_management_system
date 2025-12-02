import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../common/widgets/appbar/appbar.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/helpers/helper_functions.dart';

class LeaderboardRewardsInfoScreen extends StatelessWidget {
  const LeaderboardRewardsInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : Colors.grey[50],
      appBar: TAppBar(
        backgroundColor: TColors.primary,
        showBackArrow: true,
        title: Text(
          'Leaderboard Rewards',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: TColors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: EdgeInsets.all(TSizes.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    TColors.gold,
                    TColors.gold.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: TColors.gold.withOpacity(0.3),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Iconsax.award_bold,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  SizedBox(width: TSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Rewards',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Top 100 users earn reward points',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: TSizes.spaceBtwSections),

            // How It Works
            Text(
              'How It Works',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : TColors.black,
              ),
            ),
            SizedBox(height: TSizes.md),

            _buildInfoCard(
              icon: Iconsax.calendar_bold,
              title: 'Monthly Reset',
              description: 'Leaderboard scores are reset at 12:00 AM on the 1st of every month.',
              color: TColors.info,
              isDark: isDark,
            ),

            SizedBox(height: TSizes.sm),

            _buildInfoCard(
              icon: Iconsax.clock_bold,
              title: 'Distribution Time',
              description: 'Rewards are automatically distributed on the 1st of each month at 12:10 AM.',
              color: TColors.success,
              isDark: isDark,
            ),

            SizedBox(height: TSizes.sm),

            _buildInfoCard(
              icon: Iconsax.ranking_bold,
              title: 'Top 100 Only',
              description: 'Only the top 100 users on the leaderboard will receive reward points.',
              color: TColors.warning,
              isDark: isDark,
            ),

            SizedBox(height: TSizes.spaceBtwSections),

            // Reward Distribution
            Text(
              'Reward Distribution',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : TColors.black,
              ),
            ),
            SizedBox(height: TSizes.md),

            // Rewards List
            _buildRewardTier(
              rank: '1st Place',
              points: 1000,
              icon: Iconsax.crown_1_bold,
              color: TColors.gold,
              isDark: isDark,
            ),

            SizedBox(height: TSizes.sm),

            _buildRewardTier(
              rank: '2nd Place',
              points: 800,
              icon: Iconsax.medal_star_bold,
              color: TColors.silver,
              isDark: isDark,
            ),

            SizedBox(height: TSizes.sm),

            _buildRewardTier(
              rank: '3rd Place',
              points: 600,
              icon: Iconsax.medal_bold,
              color: TColors.bronze,
              isDark: isDark,
            ),

            SizedBox(height: TSizes.sm),

            _buildRewardTier(
              rank: '4th - 10th Place',
              points: 400,
              icon: Iconsax.star_1_bold,
              color: TColors.primary,
              isDark: isDark,
            ),

            SizedBox(height: TSizes.sm),

            _buildRewardTier(
              rank: '11th - 50th Place',
              points: 200,
              icon: Iconsax.cup_bold,
              color: TColors.info,
              isDark: isDark,
            ),

            SizedBox(height: TSizes.sm),

            _buildRewardTier(
              rank: '51st - 100th Place',
              points: 100,
              icon: Iconsax.award_bold,
              color: TColors.success,
              isDark: isDark,
            ),

            SizedBox(height: TSizes.spaceBtwSections),

            // Tips Card
            Container(
              padding: EdgeInsets.all(TSizes.md),
              decoration: BoxDecoration(
                color: isDark
                    ? TColors.primary.withOpacity(0.1)
                    : TColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: TColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Iconsax.lamp_charge_bold,
                    color: TColors.primary,
                    size: 24,
                  ),
                  SizedBox(width: TSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pro Tip',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: TColors.primary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Stay consistent! Log your health data daily, engage with the community, and complete achievements to maximize your monthly score.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? TColors.lightGrey : TColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required bool isDark,
  }) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          SizedBox(width: TSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : TColors.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? TColors.darkGrey : TColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardTier({
    required String rank,
    required int points,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: isDark ? TColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
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
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          SizedBox(width: TSizes.md),
          Expanded(
            child: Text(
              rank,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : TColors.black,
              ),
            ),
          ),
          Row(
            children: [
              Icon(
                Iconsax.coin_1_bold,
                color: TColors.warning,
                size: 20,
              ),
              SizedBox(width: 4),
              Text(
                '$points',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}