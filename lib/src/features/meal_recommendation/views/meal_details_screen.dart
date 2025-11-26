import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../models/meal_model.dart';

class MealDetailScreen extends StatelessWidget {
  final MealModel meal;
  final bool showActions; // Show consume/skip buttons
  final String? mealPlanId;
  final String? mealPlanMealId;
  final VoidCallback? onConsume;
  final VoidCallback? onSkip;

  const MealDetailScreen({
    super.key,
    required this.meal,
    this.showActions = false,
    this.mealPlanId,
    this.mealPlanMealId,
    this.onConsume,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : TColors.light,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          _buildSliverAppBar(isDark),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Meal Name and Description
                _buildHeaderSection(isDark),

                // Quick Info
                _buildQuickInfoSection(isDark),

                // Nutrition Facts
                _buildNutritionSection(isDark),

                // Ingredients
                _buildIngredientsSection(isDark),

                // Instructions
                _buildInstructionsSection(isDark),

                // Cooking Methods
                _buildCookingMethodsSection(isDark),

                // Diet & Dietary Restrictions
                _buildDietaryInfoSection(isDark),

                // Notes
                if (meal.notes != null && meal.notes!.isNotEmpty)
                  _buildNotesSection(isDark),

                // Source
                _buildSourceSection(isDark),

                const SizedBox(height: 100), // Space for bottom buttons
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: showActions ? _buildBottomActions(isDark) : null,
    );
  }

  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: isDark ? TColors.dark : TColors.white,
      leading: IconButton(
        onPressed: () => Get.back(),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Iconsax.arrow_left_bold,
            color: TColors.white,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Image.network(
          meal.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: TColors.grey,
              child: const Icon(
                Iconsax.gallery_bold,
                size: 64,
                color: TColors.darkGrey,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            meal.mealName,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? TColors.white : TColors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            meal.mealDescription,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? TColors.darkGrey : TColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'by ${meal.authorName}',
            style: TextStyle(
              fontSize: 14,
              color: TColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfoSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkContainer : TColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickInfoItem(
            Iconsax.clock_bold,
            'Prep',
            '${meal.preparationTime} min',
            isDark,
          ),
          _buildQuickInfoItem(
            Iconsax.timer_bold,
            'Cook',
            '${meal.cookingTime} min',
            isDark,
          ),
          _buildQuickInfoItem(
            Iconsax.people_bold,
            'Serves',
            '${meal.serves}',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfoItem(
      IconData icon,
      String label,
      String value,
      bool isDark,
      ) {
    return Column(
      children: [
        Icon(
          icon,
          color: TColors.primary,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? TColors.darkGrey : TColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? TColors.white : TColors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkContainer : TColors.white,
        borderRadius: BorderRadius.circular(16),
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
                Iconsax.health_bold,
                color: TColors.success,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Nutrition Facts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? TColors.white : TColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildNutritionRow(
            'Calories',
            '${meal.nutrient.calories.toInt()} kcal',
            isDark,
          ),
          _buildNutritionRow(
            'Protein',
            '${meal.nutrient.protein.toInt()} g',
            isDark,
          ),
          _buildNutritionRow(
            'Carbohydrates',
            '${meal.nutrient.carbohydrates.toInt()} g',
            isDark,
          ),
          _buildNutritionRow(
            'Fat',
            '${meal.nutrient.fat.toInt()} g',
            isDark,
          ),
          _buildNutritionRow(
            'Saturated Fat',
            '${meal.nutrient.saturatedFat.toInt()} g',
            isDark,
          ),
          _buildNutritionRow(
            'Fiber',
            '${meal.nutrient.fiber.toInt()} g',
            isDark,
          ),
          _buildNutritionRow(
            'Sugar',
            '${meal.nutrient.sugar.toInt()} g',
            isDark,
          ),
          _buildNutritionRow(
            'Sodium',
            '${meal.nutrient.sodium.toInt()} mg',
            isDark,
          ),
          _buildNutritionRow(
            'Cholesterol',
            '${meal.nutrient.cholesterol.toInt()} mg',
            isDark,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionRow(
      String label,
      String value,
      bool isDark, {
        bool isLast = false,
      }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? TColors.darkGrey : TColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? TColors.white : TColors.black,
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 8),
          Divider(
            color: isDark ? TColors.borderSecondary.withOpacity(0.2) : TColors.borderPrimary,
            height: 1,
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildIngredientsSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkContainer : TColors.white,
        borderRadius: BorderRadius.circular(16),
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
                Iconsax.note_2_bold,
                color: TColors.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Ingredients',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? TColors.white : TColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...meal.ingredients.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: TColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? TColors.white : TColors.black,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildInstructionsSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkContainer : TColors.white,
        borderRadius: BorderRadius.circular(16),
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
                Iconsax.clipboard_text_bold,
                color: TColors.info,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Instructions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? TColors.white : TColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...meal.instructions.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: TColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(
                          color: TColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? TColors.white : TColors.black,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCookingMethodsSection(bool isDark) {
    if (meal.cookingMethod.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkContainer : TColors.white,
        borderRadius: BorderRadius.circular(16),
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
                Iconsax.setting_2_bold,
                color: TColors.info,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Cooking Methods',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? TColors.white : TColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: meal.cookingMethod.map((method) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: TColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: TColors.info),
                ),
                child: Text(
                  method.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: TColors.info,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDietaryInfoSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkContainer : TColors.white,
        borderRadius: BorderRadius.circular(16),
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
                Iconsax.heart_bold,
                color: TColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Dietary Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? TColors.white : TColors.black,
                ),
              ),
            ],
          ),

          if (meal.dishType.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Dish Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? TColors.darkGrey : TColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: meal.dishType.map((type) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: TColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      fontSize: 12,
                      color: TColors.primary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          if (meal.dietType.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Diet Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? TColors.darkGrey : TColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: meal.dietType.map((type) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: TColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      fontSize: 12,
                      color: TColors.success,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          if (meal.dietaryRestrictions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Dietary Restrictions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? TColors.darkGrey : TColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: meal.dietaryRestrictions.map((restriction) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: TColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    restriction,
                    style: TextStyle(
                      fontSize: 12,
                      color: TColors.warning,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TColors.warning),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.info_circle_bold,
                color: TColors.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Notes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? TColors.white : TColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...meal.notes!.map((note) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: TColors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      note,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? TColors.white : TColors.black,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSourceSection(bool isDark) {
    if (meal.sourceUrl.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(24),
      child: OutlinedButton.icon(
        onPressed: () async {
          if (await canLaunchUrlString(meal.sourceUrl)) {
            await launchUrlString(meal.sourceUrl);
          }
        },
        icon: Icon(Iconsax.link_bold, size: 20),
        label: const Text('View Original Recipe'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: TColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkContainer : TColors.white,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Skip Button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onSkip,
                icon: const Icon(Iconsax.close_circle_bold),
                label: const Text('Skip'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: TColors.error),
                  foregroundColor: TColors.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Consume Button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onConsume,
                icon: const Icon(Iconsax.tick_circle_bold),
                label: const Text('Consumed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.success,
                  foregroundColor: TColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}