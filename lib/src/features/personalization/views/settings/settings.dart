import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../navigation_menu.dart';
import '../../../../common/loaders/loaders.dart';
import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/custom_shapes/containers/primary_header_container.dart';
import '../../../../common/widgets/dialogs/dialog.dart';
import '../../../../common/widgets/list_tiles/user_profile_tile.dart';
import '../../../../common/widgets/texts/section_heading.dart';
import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../services/tutorial_flow_manager.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../achievement/views/leaderboard_screen.dart';
import '../../../achievement/views/user_achievement_screen.dart';
import '../../../health_data_entry/views/dashboard.dart';
import '../../../notification/views/notification_screen.dart';
import '../../../reward/views/reward_shop_screen.dart';
import '../../../subscription/views/subscription_history_screen.dart';
import '../../../subscription/views/subscription_plan_selection_screen.dart';
import '../../../subscription/views/transaction_history_screen.dart';
import '../../controllers/user_controller.dart';
import '../profile/profile.dart';
import 'avatar_frame_manager_screen.dart';
import 'help_support_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);
    final userController = UserController.instance;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// -- Header
            TPrimaryHeaderContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TAppBar(
                    title: Text(
                      'Settings',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium!
                          .apply(color: TColors.white),
                    ),
                    isCenter: false,
                  ),

                  /// -- User Profile Card with Points Display
                  Obx(() {
                    final user = userController.user.value;
                    return TUserProfileTile(
                      onPressed: () => Get.to(() => const ProfileScreen()),
                      showDefaultSubtitle: false, // 不显示默认的 email subtitle
                      customSubtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Email
                          Text(
                            user.email,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 6),
                          // Points Row
                          Row(
                            children: [
                              // Total Score
                              Icon(
                                Iconsax.star_1_bold,
                                size: 14,
                                color: TColors.warning,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${user.totalScore} pts',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              SizedBox(width: 12),
                              // Reward Points
                              Icon(
                                Iconsax.coin_1_bold,
                                size: 14,
                                color: TColors.gold,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${user.rewardPoints} coins',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: TSizes.defaultSpace),
                ],
              ),
            ),

            /// - Body
            Padding(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// - Account Section
                  const TSectionHeading(
                    title: 'Account',
                    showActionButton: false,
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),

                  _buildSettingItem(
                    context: context,
                    icon: Iconsax.frame_bold,
                    title: 'Avatar Frames',
                    subtitle: 'Manage your avatar frames',
                    iconColor: const Color(0xFF8B5CF6),
                    iconBgColor: const Color(0xFF8B5CF6).withOpacity(0.1),
                    onTap: () => Get.to(() => const AvatarFrameManagerScreen()),
                    darkMode: darkMode,
                  ),
                  const SizedBox(height: TSizes.sm),

                  // Account Settings Items
                  _buildSettingItem(
                    context: context,
                    icon: Iconsax.award_bold,
                    title: 'Achievements',
                    subtitle: 'View your achievements & badges',
                    iconColor: TColors.warning,
                    iconBgColor: TColors.warning.withOpacity(0.1),
                    onTap: () => Get.to(() => const UserAchievementScreen()),
                    darkMode: darkMode,
                  ),
                  const SizedBox(height: TSizes.sm),

                  _buildSettingItem(
                    context: context,
                    icon: Iconsax.ranking_bold,
                    title: 'Leaderboard',
                    subtitle: 'Check your ranking & compete',
                    iconColor: TColors.gold,
                    iconBgColor: TColors.gold.withOpacity(0.1),
                    onTap: () => Get.to(() => const LeaderboardScreen()),
                    darkMode: darkMode,
                  ),
                  const SizedBox(height: TSizes.sm),

                  _buildSettingItem(
                    context: context,
                    icon: Iconsax.shop_bold,
                    title: 'Reward Shop',
                    subtitle: 'Redeem exclusive rewards',
                    iconColor: TColors.info,
                    iconBgColor: TColors.info.withOpacity(0.1),
                    onTap: () => Get.to(() => const RewardShopScreen()),
                    darkMode: darkMode,
                  ),
                  const SizedBox(height: TSizes.sm),

                  _buildSettingItem(
                    context: context,
                    icon: Iconsax.crown_1_bold,
                    title: 'Upgrade to Premium',
                    subtitle: 'Unlock exclusive features',
                    iconColor: TColors.success,
                    iconBgColor: TColors.success.withOpacity(0.1),
                    onTap: () => Get.to(() => const SubscriptionPlanScreen()),
                    darkMode: darkMode,
                  ),
                  const SizedBox(height: TSizes.sm),

                  _buildSettingItem(
                    context: context,
                    icon: Iconsax.receipt_1_bold,
                    title: 'Subscription',
                    subtitle: 'View your subscription',
                    iconColor: TColors.primary,
                    iconBgColor: TColors.primary.withOpacity(0.1),
                    onTap: () => Get.to(() => const SubscriptionHistoryScreen()),
                    darkMode: darkMode,
                  ),
                  const SizedBox(height: TSizes.sm),

                  _buildSettingItem(
                    context: context,
                    icon: Iconsax.receipt_text_bold,
                    title: 'Transaction History',
                    subtitle: 'View all your transactions',
                    iconColor: const Color(0xFFEC4899),
                    iconBgColor: const Color(0xFFEC4899).withOpacity(0.1),
                    onTap: () => Get.to(() => const TransactionHistoryScreen()),
                    darkMode: darkMode,
                  ),

                  const SizedBox(height: TSizes.spaceBtwSections),

                  /// - Preferences Section
                  const TSectionHeading(
                    title: 'Preferences',
                    showActionButton: false,
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),

                  _buildSettingItem(
                    context: context,
                    icon: Iconsax.notification_bold,
                    title: 'Notifications',
                    subtitle: 'Manage your notification',
                    iconColor: TColors.info,
                    iconBgColor: TColors.info.withOpacity(0.1),
                    onTap: () => Get.to(() => const NotificationScreen()),
                    darkMode: darkMode,
                  ),
                  const SizedBox(height: TSizes.sm),

                  // _buildSettingItem(
                  //   context: context,
                  //   icon: Iconsax.lock_bold,
                  //   title: 'Account Privacy',
                  //   subtitle: 'Manage data & privacy settings',
                  //   iconColor: TColors.error,
                  //   iconBgColor: TColors.error.withOpacity(0.1),
                  //   onTap: () {
                  //     // TODO: Navigate to privacy settings
                  //   },
                  //   darkMode: darkMode,
                  // ),

                  _buildSettingItem(
                    context: context,
                    icon: Iconsax.refresh_bold, // 使用刷新图标
                    title: 'Restart Tutorial',
                    subtitle: 'Restart the app tutorial guide',
                    iconColor: TColors.info, // 可以使用 info 颜色
                    iconBgColor: TColors.info.withOpacity(0.1),
                    onTap: () {
                      // 显示确认对话框
                      _showRestartTutorialConfirmation(context);
                    },
                    darkMode: darkMode,
                  ),
                  const SizedBox(height: TSizes.sm),

                  // Dark Mode Toggle
                  _buildDarkModeToggle(context, darkMode),

                  const SizedBox(height: TSizes.spaceBtwSections),

                  /// - Support Section
                  const TSectionHeading(
                    title: 'Support',
                    showActionButton: false,
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),

                  _buildSettingItem(
                    context: context,
                    icon: Iconsax.message_question_bold,
                    title: 'Help & Support',
                    subtitle: 'Get help with your account',
                    iconColor: const Color(0xFF8B5CF6),
                    iconBgColor: const Color(0xFF8B5CF6).withOpacity(0.1),
                    onTap: () => Get.to(() => const HelpSupportScreen()),
                    darkMode: darkMode,
                  ),
                  const SizedBox(height: TSizes.sm),

                  _buildSettingItem(
                    context: context,
                    icon: Iconsax.document_text_bold,
                    title: 'Terms & Conditions',
                    subtitle: 'Read our terms of service',
                    iconColor: const Color(0xFF06B6D4),
                    iconBgColor: const Color(0xFF06B6D4).withOpacity(0.1),
                    onTap: () => Get.to(() => const TermsConditionsScreen()),
                    darkMode: darkMode,
                  ),
                  const SizedBox(height: TSizes.sm),

                  _buildSettingItem(
                    context: context,
                    icon: Iconsax.shield_tick_bold,
                    title: 'Privacy Policy',
                    subtitle: 'Learn how we protect your data',
                    iconColor: const Color(0xFFEC4899),
                    iconBgColor: const Color(0xFFEC4899).withOpacity(0.1),
                    onTap: () => Get.to(() => const PrivacyPolicyScreen()),
                    darkMode: darkMode,
                  ),

                  const SizedBox(height: TSizes.spaceBtwSections),

                  /// - Logout Button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                      gradient: LinearGradient(
                        colors: [
                          TColors.error.withOpacity(0.1),
                          TColors.error.withOpacity(0.05),
                        ],
                      ),
                      border: Border.all(
                        color: TColors.error.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          TDialog.confirmDialog(title: 'Confirm Logout', message: 'Are you sure you want to log out from your account?', confirmButtonColor: TColors.error, confirmText: 'Logout', onConfirm: () => AuthenticationRepository.instance.logout());
                        },
                        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: TSizes.md,
                            vertical: 18,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Iconsax.logout_bold,
                                color: TColors.error,
                                size: 22,
                              ),
                              const SizedBox(width: TSizes.sm),
                              Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: TColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: TSizes.spaceBtwSections),

                  // App Version
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TSizes.md,
                        vertical: TSizes.sm,
                      ),
                      decoration: BoxDecoration(
                        color: darkMode
                            ? TColors.darkGrey.withOpacity(0.3)
                            : TColors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Version 1.0.0',
                        style: Theme.of(context).textTheme.bodySmall!.apply(
                          color: darkMode ? TColors.lightGrey : TColors.darkerGrey,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: TSizes.defaultSpace),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
    required bool darkMode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: darkMode ? TColors.dark : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: darkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
          child: Padding(
            padding: const EdgeInsets.all(TSizes.md),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: TSizes.md),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall!.apply(
                          color: darkMode ? TColors.darkGrey : TColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDarkModeToggle(BuildContext context, bool darkMode) {
    return Container(
      decoration: BoxDecoration(
        color: darkMode ? TColors.dark : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: darkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(TSizes.md),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: darkMode
                    ? const Color(0xFF8B5CF6).withOpacity(0.1)
                    : TColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Transform.translate(
                offset: darkMode ? Offset(0, 0) : Offset(12, 0),
                child: Icon(
                  darkMode ? Iconsax.moon_bold : Iconsax.sun_1_bold,
                  color: darkMode ? const Color(0xFF8B5CF6) : TColors.warning,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: TSizes.md),

            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dark Mode',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Switch between light & dark theme',
                    style: Theme.of(context).textTheme.bodySmall!.apply(
                      color: darkMode ? TColors.darkGrey : TColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Switch
            Transform.scale(
              scale: 0.9,
              child: Switch(
                value: darkMode,
                onChanged: (value) {
                  Get.changeThemeMode(
                    value ? ThemeMode.dark : ThemeMode.light,
                  );
                },
                activeColor: TColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRestartTutorialConfirmation(BuildContext context) {
    TDialog.confirmDialog(
      title: 'Restart Tutorial?',
      message: 'Are you sure you want to restart the tutorial? This will guide you through all the app features again.',
      confirmText: 'Restart',
      cancelText: 'Cancel',
      icon: Iconsax.refresh_bold,
      iconColor: TColors.info,
      confirmButtonColor: TColors.primary,
      onConfirm: () {
        // 重启教学
        final tutorialManager = TutorialFlowManager.instance;
        tutorialManager.resetTutorial();

        // 显示成功消息
        TLoaders.successSnackBar(
          title: 'Tutorial Restarted!',
          message: 'Returning to dashboard to start the tutorial...',
        );

        // 立即导航回 Dashboard
        Future.delayed(const Duration(milliseconds: 1000), () {
          // 重置导航索引到 Dashboard
          final navController = Get.find<NavigationController>();
          navController.selectedIndex.value = 0;
          // 不需要在这里手动启动教学，Dashboard 会自动检测并开始
        });
      },
    );
  }
}