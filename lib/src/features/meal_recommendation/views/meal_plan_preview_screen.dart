import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:intl/intl.dart';

import '../../../common/widgets/dialogs/dialog.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/meal_time_constants.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../controllers/meal_recommendation_controller.dart';
import '../models/meal_plan_meal_model.dart';
import 'meal_details_screen.dart';

class MealPlanPreviewScreen extends StatelessWidget {
  const MealPlanPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MealRecommendationController>();
    final isDark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : TColors.light,
      appBar: AppBar(
        title: const Text('Review Your Meal Plan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => _handleBack(controller),
          icon: const Icon(Iconsax.arrow_left_bold),
        ),
      ),
      body: Obx(() {
        final mealPlan = controller.generatedMealPlan.value;

        if (mealPlan == null) {
          return Center(
            child: Text(
              'No meal plan available',
              style: TextStyle(
                color: isDark ? TColors.white : TColors.black,
              ),
            ),
          );
        }

        return Column(
          children: [
            // Plan Info Header
            _buildPlanInfoHeader(mealPlan, isDark),

            // Meal List
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: mealPlan.planType == MealPlanType.daily
                    ? _buildDailyMealList(controller, mealPlan, isDark)
                    : _buildWeeklyMealList(controller, mealPlan, isDark),
              ),
            ),

            // Bottom Actions
            _buildBottomActions(controller, isDark),
          ],
        );
      }),
    );
  }

  Widget _buildPlanInfoHeader(dynamic mealPlan, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [TColors.primary, TColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: TColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                mealPlan.planType == MealPlanType.daily
                    ? Iconsax.sun_1_bold
                    : Iconsax.calendar_1_bold,
                color: TColors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mealPlan.planType == MealPlanType.daily
                          ? 'Daily Meal Plan'
                          : 'Weekly Meal Plan',
                      style: const TextStyle(
                        color: TColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${mealPlan.scheduledMeals.length} meals planned',
                      style: TextStyle(
                        color: TColors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: TColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Iconsax.calendar_bold,
                  color: TColors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('MMM dd').format(mealPlan.startDateTime)} - ${DateFormat('MMM dd').format(mealPlan.endDateTime)}',
                  style: const TextStyle(
                    color: TColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyMealList(
      MealRecommendationController controller,
      dynamic mealPlan,
      bool isDark,
      ) {
    return Column(
      children: mealPlan.scheduledMeals.map<Widget>((meal) {
        return _buildMealCard(controller, meal, isDark);
      }).toList(),
    );
  }

  Widget _buildWeeklyMealList(
      MealRecommendationController controller,
      dynamic mealPlan,
      bool isDark,
      ) {
    // Group meals by date
    final Map<DateTime, List<MealPlanMealModel>> mealsByDate = {};

    for (var meal in mealPlan.scheduledMeals) {
      final date = DateTime(
        meal.scheduledDate.year,
        meal.scheduledDate.month,
        meal.scheduledDate.day,
      );

      if (!mealsByDate.containsKey(date)) {
        mealsByDate[date] = [];
      }
      mealsByDate[date]!.add(meal);
    }

    // Sort dates
    final sortedDates = mealsByDate.keys.toList()..sort();

    return Column(
      children: sortedDates.map((date) {
        final mealsForDate = mealsByDate[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: TColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('EEEE, MMM dd').format(date),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? TColors.white : TColors.black,
                    ),
                  ),
                ],
              ),
            ),

            // Meals for this date
            ...mealsForDate.map((meal) => _buildMealCard(controller, meal, isDark)),

            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMealCard(
      MealRecommendationController controller,
      MealPlanMealModel meal,
      bool isDark,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Meal Image with Time Slot Badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Image.network(
                  meal.meal.imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 200,
                      color: TColors.grey,
                      child: const Icon(
                        Iconsax.gallery_bold,
                        size: 48,
                        color: TColors.darkGrey,
                      ),
                    );
                  },
                ),
              ),

              // Time Slot Badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: TColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Iconsax.clock_bold,
                        color: TColors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        MealTimeConstants.getMealDisplayName(meal.mealTimeSlot),
                        style: const TextStyle(
                          color: TColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Replace Button
              Positioned(
                top: 12,
                right: 12,
                child: Obx(() => Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: controller.isReplacingMeal.value
                        ? null
                        : () => controller.replaceMeal(meal.mealPlanMealId),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: TColors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: controller.isReplacingMeal.value
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(TColors.primary),
                        ),
                      )
                          : const Icon(
                        Iconsax.refresh_bold,
                        color: TColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                )),
              ),
            ],
          ),

          // Meal Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Meal Name
                Text(
                  meal.meal.mealName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? TColors.white : TColors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Meal Description
                Text(
                  meal.meal.mealDescription,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? TColors.darkGrey : TColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Meal Info Row
                Row(
                  children: [
                    _buildInfoChip(
                      Iconsax.clock_bold,
                      '${meal.meal.preparationTime + meal.meal.cookingTime} min',
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      Iconsax.people_bold,
                      '${meal.meal.serves} serves',
                      isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Nutrition Info
                Row(
                  children: [
                    _buildNutritionInfo(
                      'Calories',
                      '${meal.meal.nutrient.calories.toInt()}',
                      isDark,
                    ),
                    const SizedBox(width: 16),
                    _buildNutritionInfo(
                      'Protein',
                      '${meal.meal.nutrient.protein.toInt()}g',
                      isDark,
                    ),
                    const SizedBox(width: 16),
                    _buildNutritionInfo(
                      'Carbs',
                      '${meal.meal.nutrient.carbohydrates.toInt()}g',
                      isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // View Details Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Get.to(() => MealDetailScreen(
                        meal: meal.meal,
                        showActions: false,
                      ));
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: TColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'View Details',
                      style: TextStyle(
                        color: TColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? TColors.dark : TColors.lightGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark ? TColors.darkGrey : TColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? TColors.darkGrey : TColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionInfo(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? TColors.darkGrey : TColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? TColors.white : TColors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(
      MealRecommendationController controller,
      bool isDark,
      ) {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Regenerate Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _handleRegenerate(controller),
                icon: const Icon(Iconsax.refresh_2_bold),
                label: const Text('Regenerate Meal Plan'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: TColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Confirm Button
            Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: controller.isLoading.value
                    ? null
                    : () => _handleConfirm(controller),
                icon: controller.isLoading.value
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(TColors.white),
                  ),
                )
                    : const Icon(Iconsax.tick_circle_bold),
                label: const Text('Confirm Meal Plan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.primary,
                  foregroundColor: TColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _handleBack(MealRecommendationController controller) async {
    final shouldDiscard = await TDialog.confirmDialog(
      title: 'Discard Meal Plan?',
      message: 'Are you sure you want to go back? Your generated meal plan will be discarded.',
      confirmText: 'Discard',
      cancelText: 'Keep Editing',
      confirmButtonColor: TColors.error,
      icon: Iconsax.warning_2_bold,
      iconColor: TColors.error,
    );

    if (shouldDiscard == true) {
      await controller.discardMealPlan();
      Get.back();
    }
  }

  void _handleRegenerate(MealRecommendationController controller) async {
    final shouldRegenerate = await TDialog.confirmDialog(
      title: 'Regenerate Meal Plan?',
      message: 'This will create a new meal plan with different meals. Continue?',
      confirmText: 'Regenerate',
      cancelText: 'Cancel',
      icon: Iconsax.refresh_2_bold,
      iconColor: TColors.primary,
    );

    if (shouldRegenerate == true) {
      await controller.regenerateMealPlan();
    }
  }

  void _handleConfirm(MealRecommendationController controller) async {
    final shouldConfirm = await TDialog.confirmDialog(
      title: 'Confirm Meal Plan?',
      message: 'Once confirmed, this meal plan will be activated and you can start tracking your meals.',
      confirmText: 'Confirm',
      cancelText: 'Cancel',
      icon: Iconsax.tick_circle_bold,
      iconColor: TColors.success,
      confirmButtonColor: TColors.success,
    );

    if (shouldConfirm == true) {
      await controller.confirmMealPlan();
    }
  }
}