import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../common/widgets/appbar/appbar.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../controllers/meal_recommendation_controller.dart';

class MealRecommendationForm extends StatelessWidget {
  const MealRecommendationForm({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MealRecommendationController());
    final isDark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : TColors.light,
      appBar: TAppBar(
        title: const Text(
          'Meal Recommendations',
          style: TextStyle(fontWeight: FontWeight.bold, color: TColors.white),
        ),
        backgroundColor: TColors.primary,
        showBackArrow: true,
        iconTheme: IconThemeData(color: TColors.white),
      ),
      body: Obx(() {
        // Check subscription status
        if (!controller.hasActiveSubscription.value) {
          return _buildSubscriptionRequired(controller, isDark);
        }

        // Show form or navigate to preview if plan exists
        if (controller.generatedMealPlan.value == null) {
          return _buildPreferenceForm(controller, isDark, context);
        } else {
          // This shouldn't happen as we navigate away, but keep for safety
          return const SizedBox.shrink();
        }
      }),
    );
  }

  /// Build subscription required view
  Widget _buildSubscriptionRequired(
      MealRecommendationController controller,
      bool isDark,
      ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: TColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.lock_bold,
                size: 64,
                color: TColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Subscription Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? TColors.white : TColors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Subscribe to unlock personalized meal recommendations based on your health data and preferences',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? TColors.darkGrey : TColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.navigateToSubscription,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.primary,
                  foregroundColor: TColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'View Subscription Plans',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build preference form
  Widget _buildPreferenceForm(
      MealRecommendationController controller,
      bool isDark,
      BuildContext context,
      ) {
    return Form(
      key: controller.formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildSectionHeader(
              'Tell us your preferences',
              'Help us recommend the perfect meals for you',
              isDark,
            ),

            const SizedBox(height: 24),

            // Diabetes Prediction Warning
            Obx(() {
              final warning = controller.predictionWarningMessage;
              if (warning != null) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: controller.hasDiabetesPrediction.value
                        ? TColors.warning.withOpacity(0.1)
                        : TColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: controller.hasDiabetesPrediction.value
                          ? TColors.warning
                          : TColors.error,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        controller.hasDiabetesPrediction.value
                            ? Iconsax.info_circle_bold
                            : Iconsax.warning_2_bold,
                        color: controller.hasDiabetesPrediction.value
                            ? TColors.warning
                            : TColors.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              warning,
                              style: TextStyle(
                                color: isDark ? TColors.white : TColors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (!controller.hasDiabetesPrediction.value) ...[
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed:
                                controller.navigateToDiabetesPrediction,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Complete Prediction →',
                                  style: TextStyle(
                                    color: TColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),

            // Plan Type Selection
            _buildPlanTypeSection(controller, isDark),

            const SizedBox(height: 24),

            // Diet Preference Section
            _buildDietPreferenceSection(controller, isDark),

            const SizedBox(height: 24),

            // Allergens Section
            _buildAllergensSection(controller, isDark),

            const SizedBox(height: 24),

            // Cooking Methods Section
            _buildCookingMethodsSection(controller, isDark),

            const SizedBox(height: 24),

            // Preparation Time Section
            _buildPreparationTimeSection(controller, isDark, context),

            const SizedBox(height: 48),

            // Submit Button
            _buildSubmitButton(controller, isDark),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? TColors.white : TColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? TColors.darkGrey : TColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanTypeSection(
      MealRecommendationController controller,
      bool isDark,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Iconsax.calendar_bold,
              color: TColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Plan Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? TColors.white : TColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() => Row(
          children: [
            Expanded(
              child: _buildPlanTypeCard(
                controller,
                isDark,
                MealPlanType.daily,
                'Daily',
                'Meals for today',
                Icons.sunny,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPlanTypeCard(
                controller,
                isDark,
                MealPlanType.weekly,
                'Weekly',
                '7-day meal plan',
                Iconsax.calendar_1_bold,
              ),
            ),
          ],
        )),
      ],
    );
  }

  Widget _buildPlanTypeCard(
      MealRecommendationController controller,
      bool isDark,
      MealPlanType type,
      String title,
      String subtitle,
      IconData icon,
      ) {
    final isSelected = controller.selectedPlanType.value == type;

    return GestureDetector(
      onTap: () => controller.selectedPlanType.value = type,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? TColors.primary.withOpacity(0.1)
              : (isDark ? TColors.darkContainer : TColors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? TColors.primary
                : (isDark
                ? TColors.borderSecondary.withOpacity(0.2)
                : TColors.borderPrimary),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? TColors.primary
                  : (isDark ? TColors.darkGrey : TColors.textSecondary),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? TColors.primary
                    : (isDark ? TColors.white : TColors.textPrimary),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? TColors.darkGrey : TColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDietPreferenceSection(
      MealRecommendationController controller,
      bool isDark,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Iconsax.heart_bold,
              color: TColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Dietary Preference',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? TColors.white : TColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(Optional)',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? TColors.darkGrey : TColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() => Container(
          decoration: BoxDecoration(
            color: isDark ? TColors.darkContainer : TColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? TColors.borderSecondary.withOpacity(0.2)
                  : TColors.borderPrimary,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: controller.selectedDietPreference.value == null
                ? 'No Preference'
                : controller.selectedDietPreference.value!.displayName,
            decoration: InputDecoration(
              hintText: 'Select your dietary preference',
              hintStyle: TextStyle(
                color: isDark ? TColors.darkGrey : TColors.textSecondary,
              ),
              border: InputBorder.none,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            dropdownColor: isDark ? TColors.dark : TColors.white,
            style: TextStyle(
              color: isDark ? TColors.white : TColors.textPrimary,
              fontSize: 16,
            ),
            items: controller.dietPreferences.map((String preference) {
              return DropdownMenuItem<String>(
                value: preference,
                child: Text(preference),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue == 'No Preference') {
                controller.selectedDietPreference.value = null;
              } else {
                controller.selectedDietPreference.value =
                    DietPreference.values.firstWhere(
                          (e) => e.displayName == newValue,
                    );
              }
            },
          ),
        )),
      ],
    );
  }

  Widget _buildAllergensSection(
      MealRecommendationController controller,
      bool isDark,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Iconsax.warning_2_bold,
              color: TColors.warning,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Food Allergens',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? TColors.white : TColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Select any allergens you need to avoid',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? TColors.darkGrey : TColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Obx(() => Wrap(
          spacing: 12,
          runSpacing: 12,
          children: controller.commonAllergens.map((allergen) {
            final isSelected = controller.isAllergenSelected(allergen);
            return GestureDetector(
              onTap: () => controller.toggleAllergen(allergen),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? TColors.primary.withOpacity(0.1)
                      : (isDark ? TColors.darkContainer : TColors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? TColors.primary
                        : (isDark
                        ? TColors.borderSecondary.withOpacity(0.2)
                        : TColors.borderPrimary),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      Icon(
                        Iconsax.tick_circle_bold,
                        color: TColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      allergen,
                      style: TextStyle(
                        color: isSelected
                            ? TColors.primary
                            : (isDark
                            ? TColors.white
                            : TColors.textPrimary),
                        fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        )),
      ],
    );
  }

  Widget _buildPreparationTimeSection(
      MealRecommendationController controller,
      bool isDark,
      BuildContext context,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Iconsax.clock_bold,
              color: TColors.success,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Preparation Time',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? TColors.white : TColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? TColors.darkContainer : TColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? TColors.borderSecondary.withOpacity(0.2)
                  : TColors.borderPrimary,
            ),
          ),
          child: Column(
            children: [
              Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Maximum time you want to spend',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                      isDark ? TColors.darkGrey : TColors.textSecondary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: TColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${controller.preparationTime.value} min',
                      style: TextStyle(
                        color: TColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              )),
              const SizedBox(height: 16),
              Obx(() => SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 12),
                  overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 20),
                  activeTrackColor: TColors.primary,
                  inactiveTrackColor:
                  isDark ? TColors.darkGrey : TColors.grey,
                  thumbColor: TColors.primary,
                  overlayColor: TColors.primary.withOpacity(0.2),
                ),
                child: Slider(
                  value: controller.preparationTime.value.toDouble(),
                  min: 10,
                  max: 120,
                  divisions: 22,
                  onChanged: controller.updatePreparationTime,
                ),
              )),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '10 min',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? TColors.darkGrey : TColors.textSecondary,
                    ),
                  ),
                  Text(
                    '2 hours',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? TColors.darkGrey : TColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCookingMethodsSection(
      MealRecommendationController controller,
      bool isDark,
      ) {
    return Column(
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
              'Preferred Cooking Methods',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? TColors.white : TColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Select your preferred cooking methods (optional)',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? TColors.darkGrey : TColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Obx(() => Wrap(
          spacing: 12,
          runSpacing: 12,
          children: controller.cookingMethods.map((method) {
            final isSelected = controller.isCookingMethodSelected(method);
            return GestureDetector(
              onTap: () => controller.toggleCookingMethod(method),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? TColors.primary.withOpacity(0.1)
                      : (isDark ? TColors.darkContainer : TColors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? TColors.primary
                        : (isDark
                        ? TColors.borderSecondary.withOpacity(0.2)
                        : TColors.borderPrimary),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      Icon(
                        Iconsax.tick_circle_bold,
                        color: TColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      method,
                      style: TextStyle(
                        color: isSelected
                            ? TColors.primary
                            : (isDark
                            ? TColors.white
                            : TColors.textPrimary),
                        fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        )),
      ],
    );
  }

  Widget _buildSubmitButton(
      MealRecommendationController controller,
      bool isDark,
      ) {
    return Obx(() {
      final canGenerate = controller.canGenerateRecommendation;

      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: canGenerate && !controller.isGenerating.value
              ? controller.submitMealPreferences
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: TColors.primary,
            foregroundColor: TColors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            disabledBackgroundColor: TColors.buttonDisabled,
          ),
          child: controller.isGenerating.value
              ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(TColors.white),
            ),
          )
              : const Text(
            'Get My Meal Recommendations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    });
  }
}