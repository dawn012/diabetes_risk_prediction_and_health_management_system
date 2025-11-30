import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: darkMode ? TColors.dark : TColors.light,
      appBar: TAppBar(
        title: Text(
          TTexts.privacyPolicyTitle,
          style: TextStyle(color: TColors.white),
        ),
        showBackArrow: true,
        backgroundColor: TColors.primary,
        iconTheme: IconThemeData(color: TColors.white),
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
                    TColors.success.withOpacity(0.15),
                    TColors.primary.withOpacity(0.05),
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
                              TColors.success,
                              TColors.success.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: TColors.success.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Iconsax.shield_tick_bold,
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
                              TTexts.privacyPolicyTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium!
                                  .copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              TTexts.privacyPolicySubtitle,
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
                        color: TColors.success.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.calendar_bold,
                          size: 16,
                          color: TColors.success,
                        ),
                        const SizedBox(width: TSizes.xs),
                        Text(
                          '${TTexts.lastUpdated}: November 11, 2025',
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
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
                  // Introduction with special styling
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(TSizes.lg),
                    margin: const EdgeInsets.only(bottom: TSizes.md),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          TColors.primary.withOpacity(0.1),
                          TColors.secondary.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                      border: Border.all(
                        color: TColors.primary.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: TColors.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Iconsax.info_circle_bold,
                                color: TColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: TSizes.sm),
                            Text(
                              'Introduction',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge!
                                  .copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: TSizes.md),
                        Text(
                          'DiaTrack ("we" or "the app") values your privacy. This Privacy Policy explains how we collect, use, store, and protect your personal information.\n\nBy using this app, you agree to the data practices described in this Privacy Policy.',
                          style: Theme.of(context).textTheme.bodyMedium!.apply(
                                color: darkMode
                                    ? TColors.darkGrey
                                    : TColors.textSecondary,
                                heightFactor: 1.6,
                              ),
                        ),
                      ],
                    ),
                  ),

                  _buildSection(
                    context: context,
                    number: '1',
                    icon: Iconsax.document_text_bold,
                    iconColor: TColors.primary,
                    title: 'Information We Collect',
                    content:
                        'We may collect the following types of information:\n\nAccount Information:\n• Name, email address\n• Login credentials (securely encrypted)\n• Profile picture (optional)\n\nHealth Data:\n• Blood glucose, blood pressure, weight, and body fat\n• Height, age, gender\n• Daily activity duration and sleep records\n• Stress levels, water intake\n• Medication adherence and diet quality score\n\nUsage Data:\n• Frequency of app usage and feature access\n• Device information (model, OS)\n• IP address and log data\n\nCommunity Interactions:\n• Posts, comments, and likes\n• Achievements and leaderboard data',
                    darkMode: darkMode,
                  ),
                  _buildSection(
                    context: context,
                    number: '2',
                    icon: Iconsax.setting_2_bold,
                    iconColor: TColors.warning,
                    title: 'How We Use Your Information',
                    content:
                        'We use the collected information to:\n\n• Provide core services (data tracking, risk prediction, meal recommendations)\n• Deliver personalized health insights and content\n• Analyze app performance and improve user experience\n• Process subscription payments and manage accounts\n• Send important notifications (e.g., policy updates, feature changes)\n• Prevent fraud and abuse\n• Comply with legal obligations',
                    darkMode: darkMode,
                  ),
                  _buildSection(
                    context: context,
                    number: '3',
                    icon: Iconsax.security_bold,
                    iconColor: TColors.success,
                    title: 'Data Security',
                    content:
                        'We implement the following measures to protect your data:\n\n• All data transmission is secured with TLS/SSL encryption\n• Passwords are hashed using industry standards (bcrypt)\n• Data is stored securely in Firebase cloud servers\n• Regular security audits and vulnerability scans\n• Strict access control for employees\n• Automated backups and disaster recovery\n\nHowever, no system is completely secure. We encourage you to use a strong password and update it regularly.',
                    darkMode: darkMode,
                  ),
                  _buildSection(
                    context: context,
                    number: '4',
                    icon: Iconsax.people_bold,
                    iconColor: TColors.secondary,
                    title: 'Data Sharing',
                    content:
                        'We do not sell your personal information. Data sharing occurs only in the following cases:\n\nService Providers:\n• Firebase (data hosting)\n• Stripe (payment processing)\n• Google Analytics (anonymous usage analytics)\n\nAll providers comply with strict data protection standards.\n\nLegal Requirements:\n• When required by law or regulation\n• To protect our or others\' legal rights\n\nUser Consent:\n• With your explicit permission (e.g., sharing with medical institutions)',
                    darkMode: darkMode,
                  ),
                  _buildSection(
                    context: context,
                    number: '5',
                    icon: Iconsax.messages_3_bold,
                    iconColor: Color(0xFF8B5CF6),
                    title: 'Community Data',
                    content:
                        'Content you share in the community (posts, comments) may be visible to other users. Please avoid sharing sensitive health information in public posts.\n\nWe reserve the right to remove any content that violates community guidelines.',
                    darkMode: darkMode,
                  ),
                  _buildSection(
                    context: context,
                    number: '6',
                    icon: Iconsax.location_bold,
                    iconColor: Color(0xFFEC4899),
                    title: 'Location Data',
                    content:
                        'This app does not actively collect real-time location data. IP addresses are used only for essential service features, such as localized recommendations.',
                    darkMode: darkMode,
                  ),
                  _buildSection(
                    context: context,
                    number: '7',
                    icon: Iconsax.link_bold,
                    iconColor: Color(0xFF06B6D4),
                    title: 'Third-Party Links',
                    content:
                        'The app may contain external links (e.g., health articles or partner websites). We are not responsible for third-party privacy practices. Please review their privacy policies when visiting such sites.',
                    darkMode: darkMode,
                  ),
                  _buildSection(
                    context: context,
                    number: '8',
                    icon: Iconsax.user_tick_bold,
                    iconColor: TColors.primary,
                    title: 'Your Rights',
                    content:
                        'You have the following rights:\n\nAccess:\n• View the data we hold about you\n\nCorrection:\n• Update or correct inaccurate information\n\nDeletion:\n• Request deletion of your account and data\n\nRestriction:\n• Limit certain uses of your data\n\nPortability:\n• Export your data in a structured format\n\nWithdrawal of Consent:\n• Withdraw consent for data processing at any time\n\nTo exercise these rights, please contact us at ${TTexts.supportEmail}',
                    darkMode: darkMode,
                  ),
                  _buildSection(
                    context: context,
                    number: '9',
                    icon: Iconsax.timer_bold,
                    iconColor: TColors.warning,
                    title: 'Data Retention',
                    content:
                        'We retain your data until:\n\n• You delete your account\n• Your account remains inactive for 2 consecutive years\n• Legal retention periods expire\n\nOnce deleted, data will be permanently erased within 30 days (backups within 90 days).',
                    darkMode: darkMode,
                  ),
                  _buildSection(
                    context: context,
                    number: '10',
                    icon: Iconsax.smileys_bold,
                    iconColor: TColors.error,
                    title: 'Children\'s Privacy',
                    content:
                        'This app is not intended for children under 13 years old. If we learn that we have inadvertently collected such data, we will promptly delete it.',
                    darkMode: darkMode,
                  ),
                  _buildSection(
                    context: context,
                    number: '11',
                    icon: Iconsax.refresh_bold,
                    iconColor: TColors.info,
                    title: 'Policy Updates',
                    content:
                        'We may update this Privacy Policy from time to time. Significant changes will be notified via in-app message or email. Continued use of the app constitutes acceptance of the revised policy.',
                    darkMode: darkMode,
                  ),
                  _buildSection(
                    context: context,
                    number: '12',
                    icon: Iconsax.message_bold,
                    iconColor: TColors.success,
                    title: 'Contact Us',
                    content:
                        'If you have any questions or concerns about this Privacy Policy, please contact us:\n\n• Email: ${TTexts.supportEmail}\n• Phone: ${TTexts.supportPhone}\n• Address: DiaTrack Health Solutions\n  Penang, Malaysia',
                    darkMode: darkMode,
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections),

                  // Enhanced Privacy Commitment Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(TSizes.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          TColors.success.withOpacity(0.15),
                          TColors.primary.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                      border: Border.all(
                        color: TColors.success.withOpacity(0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: TColors.success.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                TColors.success,
                                TColors.success.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: TColors.success.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Iconsax.security_bold,
                            color: TColors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: TSizes.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Our Commitment',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge!
                                    .copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: TColors.success,
                                      fontSize: 20,
                                    ),
                              ),
                              const SizedBox(height: TSizes.sm),
                              Text(
                                'DiaTrack is committed to protecting your privacy. We adhere to the principle of data minimization, collecting only what is necessary and applying the highest security standards. Your trust is our most valuable asset.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .apply(
                                      color: darkMode
                                          ? TColors.darkGrey
                                          : TColors.textSecondary,
                                      heightFactor: 1.6,
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
