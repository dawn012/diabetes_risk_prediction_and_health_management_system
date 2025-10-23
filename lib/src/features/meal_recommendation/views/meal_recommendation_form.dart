import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../controllers/meal_recommendation_controller.dart';

class MealRecommendationForm extends StatelessWidget {
  const MealRecommendationForm({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MealRecommendationController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xff272727) : const Color(0xfff6f6f6),
      appBar: AppBar(
        title: const Text('Meal Preferences'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Iconsax.arrow_left_bold),
        ),
        actions: [
          TextButton(
            onPressed: controller.resetForm,
            child: Text(
              'Reset',
              style: TextStyle(
                color: isDark ? const Color(0xff017aff) : const Color(0xff017aff),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: Form(
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

              const SizedBox(height: 32),

              // Diet Preference Section
              _buildDietPreferenceSection(controller, isDark),

              const SizedBox(height: 32),

              // Allergens Section
              _buildAllergensSection(controller, isDark),

              const SizedBox(height: 32),

              // Preparation Time Section
              _buildPreparationTimeSection(controller, isDark, context),

              const SizedBox(height: 32),

              // Cooking Difficulty Section
              _buildCookingDifficultySection(controller, isDark),

              const SizedBox(height: 48),

              // Submit Button
              _buildSubmitButton(controller, isDark),

              const SizedBox(height: 24),
            ],
          ),
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
            color: isDark ? const Color(0xffffffff) : const Color(0xff333333),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? const Color(0xff6c757d) : const Color(0xff6c757d),
          ),
        ),
      ],
    );
  }

  Widget _buildDietPreferenceSection(MealRecommendationController controller, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Iconsax.heart_bold,
              color: const Color(0xff017aff),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Dietary Preference',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xffffffff) : const Color(0xff333333),
              ),
            ),
            Text(' *', style: TextStyle(color: const Color(0xFFEF4444))),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xfff6f6f6).withValues(alpha: 0.1) : const Color(0xffffffff),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xffe6e6e6).withValues(alpha: 0.2) : const Color(0xffd9d9d9),
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: controller.selectedDietPreference.value,
            decoration: InputDecoration(
              hintText: 'Select your dietary preference',
              hintStyle: TextStyle(
                color: isDark ? const Color(0xff6c757d) : const Color(0xff6c757d),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            dropdownColor: isDark ? const Color(0xff272727) : const Color(0xffffffff),
            style: TextStyle(
              color: isDark ? const Color(0xffffffff) : const Color(0xff333333),
              fontSize: 16,
            ),
            items: controller.dietPreferences.map((String preference) {
              return DropdownMenuItem<String>(
                value: preference,
                child: Text(preference),
              );
            }).toList(),
            onChanged: (String? newValue) {
              controller.selectedDietPreference.value = newValue;
            },
          ),
        )),
      ],
    );
  }

  Widget _buildAllergensSection(MealRecommendationController controller, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Iconsax.warning_2_bold,
              color: const Color(0xFFF59E0B),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Food Allergens',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xffffffff) : const Color(0xff333333),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Select any allergens you need to avoid',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? const Color(0xff6c757d) : const Color(0xff6c757d),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xff017aff).withValues(alpha: 0.1)
                      : (isDark ? const Color(0xfff6f6f6).withValues(alpha: 0.1) : const Color(0xffffffff)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xff017aff)
                        : (isDark ? const Color(0xffe6e6e6).withValues(alpha: 0.2) : const Color(0xffd9d9d9)),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      Icon(
                        Iconsax.tick_circle_bold,
                        color: const Color(0xff017aff),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      allergen,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xff017aff)
                            : (isDark ? const Color(0xffffffff) : const Color(0xff333333)),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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

  Widget _buildPreparationTimeSection(MealRecommendationController controller, bool isDark, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Iconsax.clock_bold,
              color: const Color(0xFF10B981),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Preparation Time',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xffffffff) : const Color(0xff333333),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xfff6f6f6).withValues(alpha: 0.1) : const Color(0xffffffff),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xffe6e6e6).withValues(alpha: 0.2) : const Color(0xffd9d9d9),
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
                      color: isDark ? const Color(0xff6c757d) : const Color(0xff6c757d),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xff017aff).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${controller.preparationTime.value} min',
                      style: const TextStyle(
                        color: Color(0xff017aff),
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
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                  activeTrackColor: const Color(0xff017aff),
                  inactiveTrackColor: isDark ? const Color(0xff6c757d) : const Color(0xffe0e0e0),
                  thumbColor: const Color(0xff017aff),
                  overlayColor: const Color(0xff017aff).withValues(alpha: 0.2),
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
                      color: isDark ? const Color(0xff6c757d) : const Color(0xff6c757d),
                    ),
                  ),
                  Text(
                    '2 hours',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xff6c757d) : const Color(0xff6c757d),
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

  Widget _buildCookingDifficultySection(MealRecommendationController controller, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Iconsax.star_bold,
              color: const Color(0xFFFFB300),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Cooking Difficulty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xffffffff) : const Color(0xff333333),
              ),
            ),
            Text(' *', style: TextStyle(color: const Color(0xFFEF4444))),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xfff6f6f6).withValues(alpha: 0.1) : const Color(0xffffffff),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xffe6e6e6).withValues(alpha: 0.2) : const Color(0xffd9d9d9),
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: controller.selectedCookingDifficulty.value,
            decoration: InputDecoration(
              hintText: 'Select cooking difficulty level',
              hintStyle: TextStyle(
                color: isDark ? const Color(0xff6c757d) : const Color(0xff6c757d),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            dropdownColor: isDark ? const Color(0xff272727) : const Color(0xffffffff),
            style: TextStyle(
              color: isDark ? const Color(0xffffffff) : const Color(0xff333333),
              fontSize: 16,
            ),
            items: controller.cookingDifficulties.map((String difficulty) {
              return DropdownMenuItem<String>(
                value: difficulty,
                child: Row(
                  children: [
                    Text(difficulty),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        controller.cookingDifficulties.indexOf(difficulty) + 1,
                            (index) => Icon(
                          Icons.star,
                          size: 16,
                          color: const Color(0xFFFFB300),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              controller.selectedCookingDifficulty.value = newValue;
            },
          ),
        )),
      ],
    );
  }

  Widget _buildSubmitButton(MealRecommendationController controller, bool isDark) {
    return Obx(() => SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: controller.isLoading.value ? null : controller.submitMealPreferences,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff017aff),
          foregroundColor: const Color(0xffffffff),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          disabledBackgroundColor: const Color(0xffc4c4c4),
        ),
        child: controller.isLoading.value
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xffffffff)),
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
    ));
  }
}