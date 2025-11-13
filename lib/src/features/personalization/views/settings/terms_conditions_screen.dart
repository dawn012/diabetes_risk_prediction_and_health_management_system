import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: darkMode ? TColors.dark : TColors.light,
      appBar: TAppBar(
        title: Text(TTexts.termsTitle),
        showBackArrow: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    TColors.info.withOpacity(0.15),
                    TColors.secondary.withOpacity(0.05),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              TColors.info,
                              TColors.info.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: TColors.info.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Iconsax.document_text_bold,
                          size: 40,
                          color: TColors.white,
                        ),
                      ),
                      const SizedBox(width: TSizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              TTexts.termsTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium!
                                  .copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              TTexts.termsSubtitle,
                              style:
                              Theme.of(context).textTheme.bodyMedium!.apply(
                                color: darkMode
                                    ? TColors.darkGrey
                                    : TColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TSizes.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TSizes.md,
                      vertical: TSizes.sm,
                    ),
                    decoration: BoxDecoration(
                      color: darkMode
                          ? TColors.darkContainer.withOpacity(0.5)
                          : TColors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: TColors.info.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.calendar_bold,
                          size: 16,
                          color: TColors.info,
                        ),
                        const SizedBox(width: TSizes.xs),
                        Text(
                          '${TTexts.lastUpdated}: November 11, 2025',
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: darkMode
                                ? TColors.darkGrey
                                : TColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Content Sections with enhanced design
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    context: context,
                    number: '1',
                    icon: Iconsax.tick_circle_bold,
                    iconColor: TColors.success,
                    title: 'Acceptance of Terms',
                    content:
                    'By registering and using DiaTrack (hereinafter referred to as "the App" or "we"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree, please discontinue use.\n\nWe reserve the right to modify these Terms at any time. Updated Terms will be published within the app, and continued use signifies acceptance of the modifications.',
                    darkMode: darkMode,
                  ),
                  _buildSection(
                    context: context,
                    number: '2',
                    icon: Iconsax.health_bold,
                    iconColor: TColors.primary,
                    title: 'Service Description',
                    content:
                    'DiaTrack provides the following services:\n\n• Health data tracking (blood glucose, blood pressure, weight, body fat, etc.)\n• AI-powered diabetes risk prediction\n• Personalized health guidance\n• Subscription-based meal recommendation service\n• Monthly achievement system\n• Community interaction features\n\nThis app is intended for health management and educational purposes only and does not replace professional medical diagnosis or treatment.',
                    darkMode: darkMode,
                  ),
                  _buildSection(
                    context: context,
                    number: '3',
                    icon: Iconsax.user_bold,
                    iconColor: TColors.warning,
                    title: 'User Accounts',
                    content:
                    '• You must provide accurate and complete registration information\n• You are responsible for maintaining the security of your password\n• You are accountable for all activities under your account\n• Notify us immediately of any unauthorized use\n• We reserve the right to suspend or terminate accounts that violate these Terms',
                    darkMode: darkMode,
                  ),
                  _buildSection(
                    context: context,
                    number: '4',
                    icon: Iconsax.shield_cross_bold,
                    iconColor: TColors.error,
                    title: 'Data Accuracy & Disclaimer',
                    content:
                    '• Users are responsible for ensuring the accuracy of input data\n• AI prediction results are for reference only and do not constitute medical advice\n• We make no guarantees regarding the accuracy, reliability, or suitability of predictions\n• Always consult a qualified healthcare professional for medical decisions\n• We are not liable for any direct or indirect damages arising from the use of this app',
                    darkMode: darkMode,
                  ),
                  _buildSection(
                    context: context,
                    number: '5',
                    icon: Iconsax.crown_bold,
                    iconColor: TColors.gold,
                    title: 'Subscription Services',
                    content:
                    '• The meal recommendation feature requires a paid subscription\n• Subscription fees are displayed clearly at the time of purchase\n• Subscriptions renew automatically unless canceled prior to the renewal date\n• Refunds follow the applicable app store policies\n• We reserve the right to adjust pricing, with advance notice to existing users',
                    darkMode: darkMode,
                  ),
                  _buildSection(
                    context: context,
                    number: '6',
                    icon: Iconsax.copyright_bold,
                    iconColor: Color(0xFF8B5CF6),
                    title: 'Intellectual Property',
                    content:
                    '• All app content, designs, code, and trademarks are the property of DiaTrack\n• You may not copy, modify, distribute, or reverse-engineer any part of the app without authorization\n• User-generated content (e.g., community posts) remains owned by the creator, but grants DiaTrack the right to use and display it within the app',
                    darkMode: darkMode,
                  ),
                  _buildSection(
                    context: context,
                    number: '7',
                    icon: Iconsax.people_bold,
                    iconColor: TColors.secondary,
                    title: 'Community Guidelines',
                    content:
                    'When using community features, you must not:\n\n• Post false, misleading, or harmful health information\n• Harass, threaten, or defame other users\n• Share content that violates privacy or intellectual property rights\n• Spread malware or perform network attacks\n• Post spam or conduct commercial promotions\n\nViolations may result in content removal, account suspension, or permanent bans.',
                    darkMode: darkMode,
                  ),
                  _buildSection(
                    context: context,
                    number: '8',
                    icon: Iconsax.close_circle_bold,
                    iconColor: TColors.error,
                    title: 'Termination of Service',
                    content:
                    'We reserve the right to suspend or terminate your account under the following circumstances:\n\n• Violation of these Terms\n• Providing false or misleading information\n• Fraudulent or illegal activity\n• Extended inactivity\n\nUpon termination, you will lose access to all data and app content.',
                    darkMode: darkMode,
                  ),
                  _buildSection(
                    context: context,
                    number: '9',
                    icon: Iconsax.courthouse_bold,
                    iconColor: Color(0xFF06B6D4),
                    title: 'Governing Law',
                    content:
                    'These Terms are governed by the laws of Malaysia. Any disputes shall be resolved through amicable negotiation; if unresolved, they shall be submitted to the appropriate courts in Malaysia.',
                    darkMode: darkMode,
                  ),
                  _buildSection(
                    context: context,
                    number: '10',
                    icon: Iconsax.message_bold,
                    iconColor: TColors.success,
                    title: 'Contact Us',
                    content:
                    'If you have any questions regarding these Terms, please contact us via:\n\n• Email: ${TTexts.supportEmail}\n• Phone: ${TTexts.supportPhone}\n• Address: DiaTrack Health Solutions, Penang, Malaysia',
                    darkMode: darkMode,
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections),

                  // Enhanced Important Notice
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(TSizes.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          TColors.warning.withOpacity(0.15),
                          TColors.warning.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                      border: Border.all(
                        color: TColors.warning.withOpacity(0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: TColors.warning.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: TColors.warning.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Iconsax.warning_2_bold,
                            color: TColors.warning,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: TSizes.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Important Notice',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge!
                                    .copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: TColors.warning,
                                ),
                              ),
                              const SizedBox(height: TSizes.xs),
                              Text(
                                'By continuing to use this app, you acknowledge that you have read, understood, and agreed to all the above Terms and Conditions.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .apply(
                                  color: darkMode
                                      ? TColors.darkGrey
                                      : TColors.textSecondary,
                                  heightFactor: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildSection({
    required BuildContext context,
    required String number,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    required bool darkMode,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: TSizes.md),
      decoration: BoxDecoration(
        color: darkMode ? TColors.darkContainer : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        border: Border.all(
          color: darkMode ? TColors.darkerGrey : TColors.borderPrimary,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: darkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient background
          Container(
            padding: const EdgeInsets.all(TSizes.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  iconColor.withOpacity(0.1),
                  iconColor.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(TSizes.cardRadiusLg),
                topRight: Radius.circular(TSizes.cardRadiusLg),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        iconColor,
                        iconColor.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      number,
                      style: TextStyle(
                        color: TColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: TSizes.md),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(TSizes.md),
            child: Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium!.apply(
                color: darkMode ? TColors.darkGrey : TColors.textSecondary,
                heightFactor: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}