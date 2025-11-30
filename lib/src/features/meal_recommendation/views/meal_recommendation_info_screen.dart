import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../common/widgets/appbar/appbar.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/helpers/helper_functions.dart';

class MealRecommendationInfoScreen extends StatelessWidget {
  const MealRecommendationInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : TColors.light,
      appBar: TAppBar(
        backgroundColor: isDark ? TColors.dark : TColors.white,
        showBackArrow: true,
        title: Text(
          'Recommendation Strategy',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? TColors.white : TColors.dark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            _buildHeaderSection(isDark),

            // Overview Section
            _buildOverviewSection(isDark),

            // Risk Levels Section
            _buildRiskLevelSection('High Risk', _getHighRiskData(), TColors.error, isDark),
            _buildRiskLevelSection('Medium Risk', _getMediumRiskData(), TColors.warning, isDark),
            _buildRiskLevelSection('Low Risk', _getLowRiskData(), TColors.success, isDark),

            // Nutrient Guidelines
            _buildNutrientGuidelinesSection(isDark),

            // Source Section
            _buildSourceSection(isDark),

            const SizedBox(height: TSizes.spaceBtwSections),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(TSizes.defaultSpace),
      padding: const EdgeInsets.all(TSizes.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [TColors.primary, TColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: TColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Iconsax.health_bold,
            size: 64,
            color: TColors.white,
          ),
          const SizedBox(height: TSizes.md),
          Text(
            'Personalized Meal Recommendations',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: TColors.white,
            ),
          ),
          const SizedBox(height: TSizes.sm),
          Text(
            'Evidence-based nutrition strategy for diabetes prevention',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: TColors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
      padding: const EdgeInsets.all(TSizes.lg),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkContainer : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.info_circle_bold,
                color: TColors.info,
                size: 24,
              ),
              const SizedBox(width: TSizes.sm),
              Text(
                'Our Approach',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? TColors.white : TColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: TSizes.md),
          Text(
            'Following dietitian recommendations, all individuals should maintain a high-fiber diet with low added sugars and unhealthy fats. The key difference across risk levels is how strictly these guidelines must be followed.',
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: isDark ? TColors.darkGrey : TColors.textSecondary,
            ),
          ),
          const SizedBox(height: TSizes.md),
          _buildKeyPrinciple(
            Iconsax.heart_bold,
            'High-fiber diet (≥16g/day minimum)',
            TColors.success,
            isDark,
          ),
          _buildKeyPrinciple(
            Iconsax.close_circle_bold,
            'Low added sugars (<10% of energy)',
            TColors.error,
            isDark,
          ),
          _buildKeyPrinciple(
            Iconsax.shield_tick_bold,
            'Controlled fats (20-35% energy)',
            TColors.warning,
            isDark,
          ),
          _buildKeyPrinciple(
            Iconsax.chart_bold,
            'Balanced protein (10-20% energy)',
            TColors.info,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildKeyPrinciple(IconData icon, String text, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.sm),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: TSizes.sm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? TColors.white : TColors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskLevelSection(String title, Map<String, dynamic> data, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        TSizes.defaultSpace,
        TSizes.md,
        TSizes.defaultSpace,
        0,
      ),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkContainer : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(TSizes.md),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(TSizes.cardRadiusLg),
                topRight: Radius.circular(TSizes.cardRadiusLg),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    data['icon'] as IconData,
                    color: TColors.white,
                    size: 24,
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        data['subtitle'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? TColors.darkGrey : TColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(TSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Text(
                  data['description'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? TColors.white : TColors.black,
                  ),
                ),
                const SizedBox(height: TSizes.md),

                // Daily Calories
                _buildInfoRow(
                  Iconsax.flash_bold,
                  'Daily Calories',
                  data['calories'] as String,
                  TColors.warning,
                  isDark,
                ),

                // Meal Plan
                _buildInfoRow(
                  Iconsax.calendar_1_bold,
                  'Meal Plan',
                  data['mealPlan'] as String,
                  TColors.info,
                  isDark,
                ),

                // Key Focus
                const SizedBox(height: TSizes.sm),
                Text(
                  'Key Focus:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? TColors.white : TColors.black,
                  ),
                ),
                const SizedBox(height: TSizes.xs),
                ...(data['keyFocus'] as List<String>).map((focus) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            focus,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: isDark ? TColors.darkGrey : TColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.sm),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: TSizes.sm),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? TColors.darkGrey : TColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? TColors.white : TColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientGuidelinesSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        TSizes.defaultSpace,
        TSizes.md,
        TSizes.defaultSpace,
        0,
      ),
      padding: const EdgeInsets.all(TSizes.lg),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkContainer : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.book_bold,
                color: TColors.primary,
                size: 24,
              ),
              const SizedBox(width: TSizes.sm),
              Expanded(
                child: Text(
                  'Evidence-Based Guidelines',
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
          Text(
            'According to Reynolds & Mitri (2024), synthesizing ADA, EASD, and WHO recommendations:',
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: isDark ? TColors.darkGrey : TColors.textSecondary,
            ),
          ),
          const SizedBox(height: TSizes.md),

          _buildNutrientGuideline(
            'Carbohydrates',
            '40-60% of total energy',
            'Dietary fiber ≥16 g/day',
            Iconsax.coffee_bold,
            TColors.info,
            isDark,
          ),
          _buildNutrientGuideline(
            'Added Sugars',
            '<10% of total energy',
            'Fructose <12% if used',
            Iconsax.cake_bold,
            Colors.pink,
            isDark,
          ),
          _buildNutrientGuideline(
            'Total Fat',
            '20-35% of total energy',
            'Saturated fats <10%, avoid trans fats',
            Iconsax.drop_bold,
            TColors.warningDark,
            isDark,
          ),
          _buildNutrientGuideline(
            'Protein',
            '1-1.5 g/kg body weight/day',
            'Approximately 10-20% of energy',
            Iconsax.medal_star_bold,
            TColors.error,
            isDark,
          ),
          _buildNutrientGuideline(
            'Sodium',
            '≤2,300 mg/day',
            'Lower for high-risk individuals (≤2,000 mg)',
            Iconsax.filter_bold,
            Colors.purple,
            isDark,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientGuideline(
      String nutrient,
      String range,
      String note,
      IconData icon,
      Color color,
      bool isDark, {
        bool isLast = false,
      }) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: TSizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nutrient,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? TColors.white : TColors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    range,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    note,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? TColors.darkGrey : TColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: TSizes.md),
          Divider(
            color: isDark
                ? TColors.borderSecondary.withOpacity(0.2)
                : TColors.borderPrimary,
            height: 1,
          ),
          const SizedBox(height: TSizes.md),
        ],
      ],
    );
  }

  Widget _buildSourceSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        TSizes.defaultSpace,
        TSizes.md,
        TSizes.defaultSpace,
        0,
      ),
      padding: const EdgeInsets.all(TSizes.lg),
      decoration: BoxDecoration(
        color: TColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        border: Border.all(color: TColors.info.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.document_text_bold,
                color: TColors.info,
                size: 20,
              ),
              const SizedBox(width: TSizes.sm),
              Text(
                'Scientific Reference',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? TColors.white : TColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: TSizes.sm),
          Text(
            'Based on recommendations from:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? TColors.darkGrey : TColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          _buildSourceBadge('American Diabetes Association (ADA)', isDark),
          _buildSourceBadge('European Association for the Study of Diabetes (EASD)', isDark),
          _buildSourceBadge('World Health Organization (WHO)', isDark),
        ],
      ),
    );
  }

  Widget _buildSourceBadge(String text, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: TColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TColors.info.withOpacity(0.3)),
      ),
      child: Text(
        '• $text',
        style: TextStyle(
          fontSize: 12,
          color: isDark ? TColors.white : TColors.black,
        ),
      ),
    );
  }

  Map<String, dynamic> _getHighRiskData() {
    return {
      'icon': Iconsax.danger_bold,
      'subtitle': 'Strict dietary control required',
      'description': 'High-risk patients require strict adherence to dietary guidelines to manage blood glucose levels and avoid complications. Focus on very low sugar and saturated fat intake.',
      'calories': 'Men: 1,500-1,800 kcal\nWomen: 1,200-1,500 kcal',
      'mealPlan': '4 meals/day (includes snack)',
      'keyFocus': [
        'Very strict sugar control (<5% of energy)',
        'Higher fiber requirement (≥20g/day)',
        'Lower saturated fat (<7% of energy)',
        'Sodium limit: ≤2,000 mg/day',
        'No foods with high sugar/fat content',
      ],
    };
  }

  Map<String, dynamic> _getMediumRiskData() {
    return {
      'icon': Iconsax.warning_2_bold,
      'subtitle': 'Moderate dietary control',
      'description': 'Medium-risk individuals need moderate control. Sugar and fat consumption can be slightly increased over high-risk but must still be controlled to support glycemic and cardiovascular health.',
      'calories': 'Men: ~1,870 kcal\nWomen: ~1,530 kcal',
      'mealPlan': '3 meals/day',
      'keyFocus': [
        'Moderate sugar control (<8% of energy)',
        'Moderate fiber (≥18g/day)',
        'Saturated fat <9% of energy',
        'Sodium limit: ≤2,300 mg/day',
        'Balanced, controlled portions',
      ],
    };
  }

  Map<String, dynamic> _getLowRiskData() {
    return {
      'icon': Iconsax.shield_tick_bold,
      'subtitle': 'Lenient but healthy approach',
      'description': 'Low-risk individuals follow more lenient guidelines. Focus on maintaining good consumption of vegetables and fruits while avoiding consistently sugar and fat-rich meals.',
      'calories': 'Men: ~2,090 kcal\nWomen: ~1,710 kcal',
      'mealPlan': '3 meals/day',
      'keyFocus': [
        'Added sugar up to 10% (WHO limit)',
        'Minimum fiber (≥16g/day)',
        'Saturated fat <10% of energy',
        'Sodium limit: ≤2,300 mg/day',
        'Emphasis on variety and balance',
      ],
    };
  }
}