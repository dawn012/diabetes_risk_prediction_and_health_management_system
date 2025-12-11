import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:intl/intl.dart';

import '../../../common/widgets/appbar/appbar.dart';
import '../../../common/widgets/bottom_sheets/sort_bottom_sheet_widget.dart';
import '../../../common/widgets/dialogs/dialog.dart';
import '../../../common/widgets/filter_chip/filter_chips_widget.dart';
import '../../../common/widgets/search_bar/search_bar_widget.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/meal_time_constants.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../controllers/meal_plan_controller.dart';
import '../models/meal_plan_meal_model.dart';
import '../models/meal_plan_model.dart';
import 'meal_details_screen.dart';
import 'meal_plan_detail_screen.dart';
import 'meal_plan_preview_screen.dart';
import 'meal_recommendation_form.dart';
import 'meal_recommendation_info_screen.dart';
import 'meal_reminder_settings_screen.dart';

class MealHomeScreen extends StatelessWidget {
  const MealHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MealPlanController());
    final isDark = THelperFunctions.isDarkMode(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? TColors.dark : TColors.light,
        appBar: TAppBar(
          title: Text(
            'My Meal Plans',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? TColors.white : TColors.dark,
            ),
          ),
          backgroundColor: isDark ? TColors.dark : TColors.white,
          showBackArrow: false,
          isCenter: false,
          actions: [
            IconButton(
              icon: Icon(
                Iconsax.notification_bold,
                color: isDark ? TColors.white : TColors.dark,
              ),
              onPressed: () {
                Get.to(() => const MealReminderSettingsScreen());
              },
            ),
            IconButton(
              icon: Icon(
                Icons.info_outline_rounded,
                color: isDark ? TColors.white : TColors.dark,
              ),
              onPressed: () {
                Get.to(() => const MealRecommendationInfoScreen());
              },
            ),
          ],
          bottom: TabBar(
            indicatorColor: TColors.primary,
            labelColor: TColors.primary,
            unselectedLabelColor: isDark ? TColors.grey : TColors.darkGrey,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'Active Plan'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildActivePlanTab(context, isDark, controller),
            _buildHistoryTab(context, isDark, controller),
          ],
        ),
      ),
    );
  }

  // Active Plan Tab - Following MealPlanView Design
  Widget _buildActivePlanTab(
      BuildContext context,
      bool isDark,
      MealPlanController controller,
      ) {

    return Obx(() {
      if (controller.isLoadingActive.value) {
        return Center(
          child: CircularProgressIndicator(color: TColors.primary),
        );
      }

      final activePlan = controller.activeMealPlan.value;

      if (activePlan == null) {
        return _buildNoActivePlan(context, isDark);
      }

      return RefreshIndicator(
        onRefresh: controller.loadActiveMealPlan,
        color: TColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Plan Header (same as MealPlanView)
              _buildActivePlanHeader(controller, activePlan, isDark),

              // Meals List
              activePlan.planType == MealPlanType.daily
                  ? _buildDailyMealsList(controller, activePlan, isDark)
                  : _buildWeeklyMealsList(controller, activePlan, isDark),

              const SizedBox(height: 100),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildNoActivePlan(BuildContext context, bool isDark) {
    final controller = Get.find<MealPlanController>();

    return Obx(() {
      // 检查 Hive 中是否有未确认的临时计划
      final hasTempPlan = controller.hasTempMealPlan.value;

      if (hasTempPlan) {
        // 显示继续上次计划的选项
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(TSizes.xl),
                  decoration: BoxDecoration(
                    color: TColors.warning.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Iconsax.clock_bold,
                    size: 80,
                    color: TColors.warning,
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwSections),
                Text(
                  'Continue Your Meal Plan',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? TColors.white : TColors.dark,
                  ),
                ),
                const SizedBox(height: TSizes.md),
                Text(
                  'You have an unconfirmed meal plan from your last session.\nWould you like to continue where you left off?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? TColors.darkGrey : TColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwSections),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      child: OutlinedButton(
                        onPressed: () => _handleCancel(controller),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                          side: BorderSide(color: TColors.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(TSizes.buttonRadius),
                          ),
                        ),
                        child: Text(
                          'Discard',
                          style: TextStyle(
                            color: TColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: TSizes.md),
                    SizedBox(
                      width: 140,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // 跳转到预览页面继续编辑
                          Get.to(() => const MealPlanPreviewScreen());
                        },
                        icon: const Icon(Iconsax.eye_bold, size: 20),
                        label: const Text('Continue'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TColors.primary,
                          foregroundColor: TColors.white,
                          padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(TSizes.buttonRadius),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      } else {
        // 显示创建新计划的选项
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(TSizes.xl),
                  decoration: BoxDecoration(
                    color: TColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Iconsax.calendar_1_bold,
                    size: 80,
                    color: TColors.primary,
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwSections),
                Text(
                  'No Active Meal Plan',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? TColors.white : TColors.dark,
                  ),
                ),
                const SizedBox(height: TSizes.md),
                Text(
                  'Create your personalized meal plan to start\ntracking your healthy eating journey!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? TColors.darkGrey : TColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwSections),
                SizedBox(
                  width: 220,
                  child: ElevatedButton.icon(
                    onPressed: () => Get.to(() => const MealRecommendationForm()),
                    icon: const Icon(Iconsax.add_circle_bold, size: 20),
                    label: const Text('Create Meal Plan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColors.primary,
                      foregroundColor: TColors.white,
                      padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(TSizes.buttonRadius),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });
  }

  Widget _buildActivePlanHeader(
      MealPlanController controller,
      MealPlanModel plan,
      bool isDark,
      ) {
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
        children: [
          Row(
            children: [
              Icon(
                plan.planType == MealPlanType.daily
                    ? Icons.sunny
                    : Iconsax.calendar_1_bold,
                color: TColors.white,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.planType == MealPlanType.daily
                          ? "Today's Meal Plan"
                          : 'Weekly Meal Plan',
                      style: const TextStyle(
                        color: TColors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat('MMM dd').format(plan.startDateTime)} - ${DateFormat('MMM dd, yyyy').format(plan.endDateTime)}',
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
          const SizedBox(height: 16),

          // Adherence Progress
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Adherence',
                      style: TextStyle(
                        color: TColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${plan.adherence}%',
                      style: TextStyle(
                        color: TColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: plan.adherence / 100,
                    backgroundColor: TColors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      controller.getAdherenceColor(plan.adherence),
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Cancel Plan Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: controller.showCancelMealPlanDialog,
              icon: const Icon(Iconsax.close_circle_bold, size: 18),
              label: const Text('Cancel Plan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: TColors.white,
                side: BorderSide(color: TColors.white.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyMealsList(
      MealPlanController controller,
      MealPlanModel plan,
      bool isDark,
      ) {
    // 不再 filter 今天，也不再 sort，完全跟 scheduledMeals 数组顺序
    final mealsInOrder = plan.scheduledMeals;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: mealsInOrder
            .map((meal) => _buildMealCard(controller, plan, meal, isDark))
            .toList(),
      ),
    );
  }


  Widget _buildWeeklyMealsList(
      MealPlanController controller,
      MealPlanModel plan,
      bool isDark,
      ) {
    final dates = controller.getUniqueDates();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: dates.map((date) {
          final mealsForDate = controller.getMealsForDate(date);
          final isToday = date.year == DateTime.now().year &&
              date.month == DateTime.now().month &&
              date.day == DateTime.now().day;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Header
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            horizontal: 8, vertical: 4),
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
                    if (isToday) const SizedBox(width: 12),
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
              ...mealsForDate.map((meal) {
                return _buildMealCard(controller, plan, meal, isDark);
              }),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMealCard(
      MealPlanController controller,
      MealPlanModel plan,
      MealPlanMealModel meal,
      bool isDark,
      ) {
    final nextMeal = controller.getNextUpcomingMeal();
    final isNextMeal = nextMeal != null &&
        nextMeal.mealPlanMealId == meal.mealPlanMealId;
    final isCurrent = controller.isCurrentMeal(meal);
    final canConsume = controller.canConsumeMeal(meal);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkContainer : TColors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrent ? Border.all(color: TColors.primary, width: 2) : null,
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
          // Meal Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCurrent
                  ? TColors.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  controller.getMealStatusIcon(meal.status),
                  color: controller.getMealStatusColor(meal.status),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        MealTimeConstants.getMealDisplayName(meal.mealTimeSlot),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isCurrent
                              ? TColors.primary
                              : (isDark ? TColors.white : TColors.black),
                        ),
                      ),
                      Text(
                        MealTimeConstants.getMealTimeWindow(meal.mealTimeSlot),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? TColors.darkGrey : TColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isNextMeal)
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: TColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      controller.getTimeRemaining(meal),
                      style: TextStyle(
                        fontSize: 10,
                        color: TColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Meal Content
          InkWell(
            onTap: () {
              Get.to(() => MealDetailScreen(
                meal: meal.meal,
                showActions: canConsume,
                mealPlanId: plan.mealPlanId,
                mealPlanMealId: meal.mealPlanMealId,
                onConsume: () {
                  Get.back();
                  controller.markMealAsConsumed(
                    plan.mealPlanId,
                    meal.mealPlanMealId,
                  );
                },
                onSkip: () {
                  TDialog.confirmDialog(title: 'Skip this meal?', message: 'Are you sure you want to mark this meal as skipped?', confirmText: 'Skip', confirmButtonColor: TColors.error, onConfirm: () {
                    Get.back();
                    controller.markMealAsSkipped(
                      plan.mealPlanId,
                      meal.mealPlanMealId,
                    );
                  });
                },
              ));
            },
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                  const SizedBox(width: 16),

                  // Meal Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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

                  const SizedBox(width: 8),

                  // Status Badge
                  _buildStatusBadge(meal.status, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(MealConsumptionStatus status, bool isDark) {
    String text;
    Color color;

    switch (status) {
      case MealConsumptionStatus.consumed:
        text = 'Done';
        color = TColors.success;
        break;
      case MealConsumptionStatus.skipped:
        text = 'Skipped';
        color = TColors.error;
        break;
      case MealConsumptionStatus.pending:
        text = 'Pending';
        color = TColors.warning;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // History Tab
  Widget _buildHistoryTab(
      BuildContext context,
      bool isDark,
      MealPlanController controller,
      ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, TSizes.sm, TSizes.md, TSizes.sm),
          child: Row(
            children: [
              Expanded(
                child: Obx(() => SearchBarWidget(
                  controller: controller.searchController,
                  onChanged: controller.onSearchChanged,
                  onClear: controller.clearSearch,
                  hintText: 'Search meal plans...',
                  hasText: controller.searchQuery.value.isNotEmpty,
                )),
              ),
              const SizedBox(width: TSizes.sm),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(TSizes.buttonRadius),
                  border: Border.all(
                    color: TColors.primary,
                    width: 1,
                  ),
                ),
                child: IconButton(
                  onPressed: () => SortBottomSheetWidget.show(
                    context,
                    sortOptions: controller.sortOptions,
                    selectedSortOption: controller.selectedSortOption,
                    onSortOptionChanged: controller.onSortOptionChanged,
                    getSortOptionLabel: controller.getSortOptionLabel,
                    darkMode: isDark,
                  ),
                  icon: Icon(
                    Icons.sort_outlined,
                    color: TColors.primary,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(12),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),

        FilterChipsWidget(
          filters: controller.statusFilters,
          selectedFilter: controller.selectedStatus,
          onFilterSelected: controller.onStatusFilterChanged,
          getFilterLabel: controller.getStatusLabel,
          spaceBetweenChips: 20,
        ),

        Expanded(
          child: Obx(() {
            if (controller.isLoadingPast.value) {
              return Center(
                child: CircularProgressIndicator(color: TColors.primary),
              );
            }

            final historyList = controller.filteredMealPlans;

            if (historyList.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(TSizes.defaultSpace),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.document_text_bold,
                        size: 80,
                        color: isDark ? TColors.darkGrey : TColors.grey,
                      ),
                      const SizedBox(height: TSizes.md),
                      Text(
                        'No History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? TColors.white : TColors.dark,
                        ),
                      ),
                      const SizedBox(height: TSizes.sm),
                      Text(
                        'Your meal plan history will appear here',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark
                              ? TColors.darkGrey
                              : TColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => controller.refreshAllData(),
              color: TColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.all(TSizes.md),
                itemCount: historyList.length,
                itemBuilder: (context, index) {
                  final plan = historyList[index];
                  return _buildHistoryCard(context, plan, isDark, controller);
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(
      BuildContext context,
      MealPlanModel plan,
      bool isDark,
      MealPlanController controller,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: TSizes.sm),
      decoration: BoxDecoration(
        color: isDark ? TColors.black : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: isDark
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
          borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
          onTap: () {
            print("Plan: ${plan.status}");
            Get.to(() => MealPlanDetailScreen(mealPlan: plan,));
          },
          child: Padding(
            padding: const EdgeInsets.all(TSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getStatusColor(plan.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        plan.planType == MealPlanType.daily
                            ? Icons.sunny
                            : Iconsax.calendar_1_bold,
                        color: _getStatusColor(plan.status),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: TSizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.planTypeDisplay,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: isDark ? TColors.white : TColors.dark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${plan.totalMeals} meals',
                            style: TextStyle(
                              color: isDark
                                  ? TColors.darkGrey
                                  : TColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(plan.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        plan.statusDisplay,
                        style: TextStyle(
                          color: _getStatusColor(plan.status),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TSizes.sm),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        (isDark ? TColors.darkGrey : TColors.grey)
                            .withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: TSizes.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Period',
                          style: TextStyle(
                            color: isDark ? TColors.grey : TColors.darkGrey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('MMM dd, yyyy').format(plan.startDateTime),
                          style: TextStyle(
                            color: isDark ? TColors.white : TColors.dark,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Adherence',
                          style: TextStyle(
                            color: isDark ? TColors.grey : TColors.darkGrey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${plan.adherence}%',
                          style: TextStyle(
                            color: controller.getAdherenceColor(plan.adherence),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleCancel(MealPlanController controller) async {
    final shouldCancel = await TDialog.confirmDialog(
      title: 'Cancel Meal Plan?',
      message: 'Are you sure you want to cancel? Your generated meal plan will be discarded.',
      confirmText: 'Cancel Plan',
      cancelText: 'Keep Editing',
      confirmButtonColor: TColors.error,
      icon: Iconsax.warning_2_bold,
      iconColor: TColors.error,
    );

    if (shouldCancel == true) {
      await controller.discardTempPlan();
      // Get.back();
    }
  }

  Color _getStatusColor(MealPlanStatus status) {
    switch (status) {
      case MealPlanStatus.confirmed:
        return TColors.success;
      case MealPlanStatus.completed:
        return TColors.success;
      case MealPlanStatus.cancelled:
        return TColors.error;
      case MealPlanStatus.expired:
        return TColors.warning;
    }
  }
}