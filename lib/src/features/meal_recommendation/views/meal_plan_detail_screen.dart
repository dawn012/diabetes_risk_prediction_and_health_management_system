import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:intl/intl.dart';

import '../../../common/widgets/appbar/appbar.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/meal_time_constants.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../models/meal_plan_meal_model.dart';
import '../models/meal_plan_model.dart';
import 'meal_details_screen.dart';

class MealPlanDetailScreen extends StatelessWidget {
  final MealPlanModel mealPlan;

  const MealPlanDetailScreen({
    super.key,
    required this.mealPlan,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : TColors.light,
      appBar: TAppBar(
        title: Text(
          'Plan Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? TColors.white : TColors.dark,
          ),
        ),
        showBackArrow: true,
        backgroundColor: isDark ? TColors.dark : TColors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan Header
            _buildPlanHeader(isDark),

            // Statistics Cards
            _buildStatisticsSection(isDark),

            // Meals by Date
            _buildMealsSection(isDark),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanHeader(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(TSizes.md),
      padding: const EdgeInsets.all(TSizes.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor(mealPlan.status),
            _getStatusColor(mealPlan.status).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor(mealPlan.status).withOpacity(0.3),
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
              Container(
                padding: const EdgeInsets.all(TSizes.sm),
                decoration: BoxDecoration(
                  color: TColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  mealPlan.planType == MealPlanType.daily
                      ? Icons.sunny
                      : Iconsax.calendar_1_bold,
                  color: TColors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: TSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mealPlan.planTypeDisplay,
                      style: const TextStyle(
                        color: TColors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat('MMM dd').format(mealPlan.startDateTime)} - ${DateFormat('MMM dd, yyyy').format(mealPlan.endDateTime)}',
                      style: TextStyle(
                        color: TColors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TSizes.sm,
                  vertical: TSizes.xs,
                ),
                decoration: BoxDecoration(
                  color: TColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  mealPlan.statusDisplay,
                  style: const TextStyle(
                    color: TColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TSizes.md),

          // Adherence Progress
          Container(
            padding: const EdgeInsets.all(TSizes.md),
            decoration: BoxDecoration(
              color: TColors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Plan Adherence',
                      style: TextStyle(
                        color: TColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${mealPlan.adherence}%',
                      style: const TextStyle(
                        color: TColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TSizes.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: mealPlan.adherence / 100,
                    backgroundColor: TColors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getAdherenceColor(mealPlan.adherence),
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(bool isDark) {
    final totalMeals = mealPlan.totalMeals;
    final consumedMeals = mealPlan.scheduledMeals
        .where((m) => m.status == MealConsumptionStatus.consumed)
        .length;
    final skippedMeals = mealPlan.scheduledMeals
        .where((m) => m.status == MealConsumptionStatus.skipped)
        .length;
    final pendingMeals = mealPlan.scheduledMeals
        .where((m) => m.status == MealConsumptionStatus.pending)
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? TColors.white : TColors.dark,
            ),
          ),
          const SizedBox(height: TSizes.sm),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Iconsax.calendar_bold,
                  label: 'Total',
                  value: totalMeals.toString(),
                  color: TColors.info,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: TSizes.sm),
              Expanded(
                child: _buildStatCard(
                  icon: Iconsax.tick_circle_bold,
                  label: 'Consumed',
                  value: consumedMeals.toString(),
                  color: TColors.success,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: TSizes.sm),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Iconsax.close_circle_bold,
                  label: 'Skipped',
                  value: skippedMeals.toString(),
                  color: TColors.error,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: TSizes.sm),
              Expanded(
                child: _buildStatCard(
                  icon: Iconsax.clock_bold,
                  label: 'Pending',
                  value: pendingMeals.toString(),
                  color: TColors.warning,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkContainer : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(TSizes.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: TSizes.sm),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? TColors.white : TColors.dark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? TColors.darkGrey : TColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsSection(bool isDark) {
    // Group meals by date
    final mealsByDate = <DateTime, List<MealPlanMealModel>>{};

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

    return Padding(
      padding: const EdgeInsets.all(TSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meals',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? TColors.white : TColors.dark,
            ),
          ),
          const SizedBox(height: TSizes.sm),

          ...sortedDates.map((date) {
            final mealsForDate = mealsByDate[date]!;
            final isToday = date.year == DateTime.now().year &&
                date.month == DateTime.now().month &&
                date.day == DateTime.now().day;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Header
                Container(
                  margin: const EdgeInsets.symmetric(vertical: TSizes.sm),
                  padding: const EdgeInsets.symmetric(
                    horizontal: TSizes.md,
                    vertical: TSizes.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isToday
                        ? TColors.primary.withOpacity(0.1)
                        : (isDark ? TColors.darkContainer : TColors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: isToday ? Border.all(color: TColors.primary) : null,
                  ),
                  child: Row(
                    children: [
                      if (isToday)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: TColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'TODAY',
                            style: TextStyle(
                              color: TColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (isToday) const SizedBox(width: TSizes.sm),
                      Text(
                        DateFormat('EEEE, MMM dd').format(date),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isToday
                              ? TColors.primary
                              : (isDark ? TColors.white : TColors.black),
                        ),
                      ),
                    ],
                  ),
                ),

                // Meals for this date
                ...mealsForDate.map((meal) => _buildMealCard(meal, isDark)),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMealCard(MealPlanMealModel meal, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: TSizes.sm),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
          onTap: () {
            Get.to(() => MealDetailScreen(
              meal: meal.meal,
              showActions: false,
            ));
          },
          child: Padding(
            padding: const EdgeInsets.all(TSizes.md),
            child: Row(
              children: [
                // Meal Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    meal.meal.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: TColors.grey,
                        child: const Icon(
                          Iconsax.gallery_bold,
                          size: 32,
                          color: TColors.darkGrey,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: TSizes.md),

                // Meal Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Meal Time Slot
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: TColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          MealTimeConstants.getMealDisplayName(
                            meal.mealTimeSlot,
                          ),
                          style: const TextStyle(
                            color: TColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: TSizes.xs),

                      // Meal Name
                      Text(
                        meal.meal.mealName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? TColors.white : TColors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Meal Details
                      Text(
                        '${meal.meal.preparationTime + meal.meal.cookingTime} min · ${meal.meal.nutrient.calories.toInt()} cal',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                          isDark ? TColors.darkGrey : TColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: TSizes.sm),

                // Status Badge
                _buildStatusBadge(meal.status, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(MealConsumptionStatus status, bool isDark) {
    String text;
    Color color;
    IconData icon;

    switch (status) {
      case MealConsumptionStatus.consumed:
        text = 'Done';
        color = TColors.success;
        icon = Iconsax.tick_circle_bold;
        break;
      case MealConsumptionStatus.skipped:
        text = 'Skipped';
        color = TColors.error;
        icon = Iconsax.close_circle_bold;
        break;
      case MealConsumptionStatus.pending:
        text = 'Pending';
        color = TColors.warning;
        icon = Iconsax.clock_bold;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(MealPlanStatus status) {
    switch (status) {
      case MealPlanStatus.confirmed:
        return TColors.info;
      case MealPlanStatus.completed:
        return TColors.success;
      case MealPlanStatus.cancelled:
        return TColors.error;
      case MealPlanStatus.expired:
        return TColors.warning;
    }
  }

  Color _getAdherenceColor(int adherence) {
    if (adherence >= 80) return TColors.success;
    if (adherence >= 60) return TColors.warning;
    return TColors.error;
  }
}