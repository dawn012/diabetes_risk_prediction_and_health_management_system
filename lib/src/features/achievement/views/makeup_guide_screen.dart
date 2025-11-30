// makeup_guide_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/widgets/appbar/appbar.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/helpers/helper_functions.dart';

class MakeupGuideScreen extends StatelessWidget {
  const MakeupGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : TColors.white,
      appBar: TAppBar(
        backgroundColor: TColors.primary,
        showBackArrow: true,
        title: const Text(
          'Makeup System Guide',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: TColors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(TSizes.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    TColors.primary,
                    TColors.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(TSizes.md),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.event_repeat,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: TSizes.md),
                  const Text(
                    'Never Miss a Day!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: TSizes.sm),
                  Text(
                    'The makeup system helps you backfill missed health logs',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: TSizes.lg),

            // What is Makeup Section
            _buildSection(
              isDark: isDark,
              icon: Icons.help_outline,
              iconColor: TColors.info,
              title: 'What is a Makeup?',
              children: [
                _buildInfoCard(
                  isDark: isDark,
                  text: 'A makeup lets you add health logs for past days you missed, within a 7-day window.',
                ),
                const SizedBox(height: TSizes.sm),
                _buildHighlightBox(
                  isDark: isDark,
                  icon: Icons.lightbulb_outline,
                  color: TColors.warning,
                  title: 'Key Point',
                  description: 'Only periodic health achievements (blood glucose, blood pressure, weight and physical activity) support makeup.',
                ),
              ],
            ),

            // How It Works Section
            _buildSection(
              isDark: isDark,
              icon: Icons.settings_suggest,
              iconColor: TColors.success,
              title: 'How It Works',
              children: [
                _buildStepCard(
                  isDark: isDark,
                  step: '1',
                  title: '7-Day Window',
                  description: 'You can only makeup logs from 1-7 days ago, not today or future dates.',
                  icon: Icons.calendar_today,
                ),
                const SizedBox(height: TSizes.sm),
                _buildStepCard(
                  isDark: isDark,
                  step: '2',
                  title: 'No Existing Data',
                  description: 'That day must have no previous logs of the same health type.',
                  icon: Icons.check_circle_outline,
                ),
                const SizedBox(height: TSizes.sm),
                _buildStepCard(
                  isDark: isDark,
                  step: '3',
                  title: 'Limited Chances',
                  description: 'Each achievement has a makeup limit (usually 3 per month).',
                  icon: Icons.repeat,
                ),
              ],
            ),

            // Example Section
            _buildSection(
              isDark: isDark,
              icon: Icons.lightbulb,
              iconColor: TColors.accent,
              title: 'Example: Blood Glucose',
              children: [
                _buildExampleCard(
                  isDark: isDark,
                  achievement: 'Blood Glucose Achievement',
                  requirement: 'Track: 5 days (Bronze), 15 days (Silver), 30 days (Gold)',
                  makeupLimit: 'Max makeup: 3 per month',
                ),
                const SizedBox(height: TSizes.md),
                _buildTimelineExample(isDark: isDark),
              ],
            ),

            // Important Notes Section
            _buildSection(
              isDark: isDark,
              icon: Icons.info,
              iconColor: TColors.error,
              title: 'Important Notes',
              children: [
                _buildNoteCard(
                  isDark: isDark,
                  icon: Icons.edit,
                  title: 'Change value (same day)',
                  description:
                  'If you only change the value of a makeup log but keep the same date, it does NOT use an extra makeup.',
                ),
                const SizedBox(height: TSizes.sm),
                _buildNoteCard(
                  isDark: isDark,
                  icon: Icons.date_range,
                  title: 'Change date (still within 1–7 days)',
                  description:
                  'If you move a makeup log to another day that is also within the 1–7 day window and has no data yet, it is still counted as the SAME makeup. You do not lose an extra makeup chance.',
                ),
                const SizedBox(height: TSizes.sm),
                _buildNoteCard(
                  isDark: isDark,
                  icon: Icons.history_toggle_off,
                  title: 'Change date (more than 7 days ago)',
                  description:
                  'If you move a makeup log to a date more than 7 days ago, that log is no longer treated as a makeup. This means your makeup chance is effectively returned.',
                ),
              ],
            ),

            // // Visual Difference Section
            // _buildSection(
            //   isDark: isDark,
            //   icon: Icons.compare,
            //   iconColor: TColors.primary,
            //   title: 'Understanding the Difference',
            //   children: [
            //     _buildComparisonCard(
            //       isDark: isDark,
            //       title1: 'Makeup Count',
            //       desc1: 'How many past days you rescued',
            //       example1: 'Example: 2/3 makeups used',
            //       color1: TColors.warning,
            //       title2: 'Current Count',
            //       desc2: 'Total days with logs this month',
            //       example2: 'Example: 8 days logged',
            //       color2: TColors.success,
            //     ),
            //   ],
            // ),

            // const SizedBox(height: TSizes.lg),

            // Bottom CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(TSizes.lg, 0, TSizes.lg, TSizes.lg),
              child: Container(
                padding: const EdgeInsets.all(TSizes.md),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      TColors.primary.withOpacity(0.1),
                      TColors.primary.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: TColors.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: TColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.tips_and_updates,
                        color: TColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: TSizes.md),
                    Expanded(
                      child: Text(
                        'Use makeups wisely to maintain your achievement streaks!',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? TColors.white : TColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: TSizes.sm),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? TColors.white : TColors.black,
                  ),
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: TSizes.md),
          ...children,
          const SizedBox(height: TSizes.lg),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required bool isDark,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkContainer : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? TColors.borderPrimary.withOpacity(0.2) : TColors.borderPrimary,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: isDark ? TColors.lightGrey : TColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildHighlightBox({
    required bool isDark,
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: TSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? TColors.white : TColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? TColors.lightGrey : TColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required bool isDark,
    required String step,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkContainer : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? TColors.borderPrimary.withOpacity(0.2) : TColors.borderPrimary,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [TColors.primary, TColors.primary.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: TSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: TColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? TColors.white : TColors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? TColors.lightGrey : TColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard({
    required bool isDark,
    required String achievement,
    required String requirement,
    required String makeupLimit,
  }) {
    return Container(
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: TColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: TColors.accent.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: TColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: TColors.accent,
                  size: 16,
                ),
              ),
              const SizedBox(width: TSizes.sm),
              Expanded(
                child: Text(
                  achievement,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? TColors.white : TColors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TSizes.sm),
          _buildExampleRow(isDark, Icons.track_changes, requirement),
          const SizedBox(height: 4),
          _buildExampleRow(isDark, Icons.repeat, makeupLimit),
        ],
      ),
    );
  }

  Widget _buildExampleRow(bool isDark, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? TColors.darkGrey : TColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? TColors.lightGrey : TColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineExample({required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkContainer : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? TColors.borderPrimary.withOpacity(0.2) : TColors.borderPrimary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scenario Timeline',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? TColors.white : TColors.black,
            ),
          ),
          const SizedBox(height: TSizes.md),
          _buildTimelineItem(
            isDark: isDark,
            date: 'Today: Nov 10',
            action: 'User logs blood glucose',
            result: 'Normal log, no makeup used',
            color: TColors.success,
            isFirst: true,
          ),
          _buildTimelineItem(
            isDark: isDark,
            date: 'Nov 6 (4 days ago)',
            action: 'User adds missed log',
            result: 'Makeup used: 1/3',
            color: TColors.warning,
          ),
          _buildTimelineItem(
            isDark: isDark,
            date: 'Progress Updated',
            action: 'Progress jumps when a makeup fills a missed day',
            result: 'Current count: 4 → 5 days (Bronze)',
            color: TColors.bronze,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required bool isDark,
    required String date,
    required String action,
    required String result,
    required Color color,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            if (!isFirst)
              Container(
                width: 2,
                height: 16,
                color: isDark ? TColors.darkGrey : TColors.borderPrimary,
              ),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 24,
                color: isDark ? TColors.darkGrey : TColors.borderPrimary,
              ),
          ],
        ),
        const SizedBox(width: TSizes.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? TColors.white : TColors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                action,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? TColors.lightGrey : TColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  result,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
              if (!isLast) const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoteCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkContainer : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? TColors.borderPrimary.withOpacity(0.2) : TColors.borderPrimary,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: TColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: TColors.info,
              size: 18,
            ),
          ),
          const SizedBox(width: TSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? TColors.white : TColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? TColors.lightGrey : TColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard({
    required bool isDark,
    required String title1,
    required String desc1,
    required String example1,
    required Color color1,
    required String title2,
    required String desc2,
    required String example2,
    required Color color2,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? TColors.darkContainer : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? TColors.borderPrimary.withOpacity(0.2) : TColors.borderPrimary,
        ),
      ),
      child: Column(
        children: [
          _buildComparisonItem(
            isDark: isDark,
            title: title1,
            description: desc1,
            example: example1,
            color: color1,
            showDivider: true,
          ),
          _buildComparisonItem(
            isDark: isDark,
            title: title2,
            description: desc2,
            example: example2,
            color: color2,
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonItem({
    required bool isDark,
    required String title,
    required String description,
    required String example,
    required Color color,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(TSizes.md),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: TSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? TColors.white : TColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? TColors.lightGrey : TColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        example,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: isDark ? TColors.borderPrimary.withOpacity(0.2) : TColors.borderPrimary,
          ),
      ],
    );
  }
}