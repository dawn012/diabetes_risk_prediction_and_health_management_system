import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../../utils/validators/user_profile_validator.dart';
import '../../../personalization/controllers/update_profile_controller.dart';
import 'connect_exercise_apps_screen.dart';

class SetGoalsScreen extends StatelessWidget {
  const SetGoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UpdateProfileController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: darkMode ? TColors.dark : TColors.light,
      appBar: AppBar(
        backgroundColor: TColors.primary,
        title: const Text(
          'Set Goals',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Form(
          key: controller.goalsFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exercise Section Header
              Text(
                'Exercise',
                style: TextStyle(
                  color: TColors.textSecondary,
                  fontSize: TSizes.fontSizeMd,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: TSizes.spaceBtwItems),

              // Daily Steps Goal Card
              _buildGoalCard(
                context: context,
                darkMode: darkMode,
                title: 'Daily Steps',
                controller: controller.dailyStepsGoal,
                onTap: () => _showStepsGoalDialog(context, controller),
              ),

              const SizedBox(height: TSizes.md),

              // Weekly Exercise Time Goal Card
              _buildGoalCard(
                context: context,
                darkMode: darkMode,
                title: 'Weekly Exercise Time',
                controller: controller.weeklyExerciseTime,
                onTap: () => _showExerciseGoalDialog(context, controller),
              ),

              const SizedBox(height: TSizes.spaceBtwSections),

              // Connect Section Header
              Text(
                'Connect',
                style: TextStyle(
                  color: TColors.textSecondary,
                  fontSize: TSizes.fontSizeMd,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: TSizes.spaceBtwItems),

              // Connect to Exercise Apps Card
              _buildConnectCard(context: context, darkMode: darkMode),

              const SizedBox(height: TSizes.spaceBtwSections),

              // Save Button
              Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isGoalsLoading.value
                      ? null
                      : () => controller.updateGoals(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TSizes.buttonRadius),
                    ),
                  ),
                  child: controller.isGoalsLoading.value
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('Save Changes'),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalCard({
    required BuildContext context,
    required bool darkMode,
    required String title,
    required TextEditingController controller,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: darkMode ? TColors.darkContainer : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TSizes.md,
          vertical: TSizes.xs,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: darkMode ? TColors.white : TColors.textPrimary,
            fontSize: TSizes.fontSizeMd,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => Text(
              title.contains('Steps')
                  ? '${controller.text} Steps'
                  : '${controller.text} Minutes',
              style: TextStyle(
                color: TColors.primary,
                fontSize: TSizes.fontSizeMd,
                fontWeight: FontWeight.bold,
              ),
            )),
            const SizedBox(width: TSizes.xs),
            Icon(
              Icons.chevron_right,
              color: darkMode ? TColors.white : TColors.textSecondary,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildConnectCard({
    required BuildContext context,
    required bool darkMode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: darkMode ? TColors.darkContainer : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TSizes.md,
          vertical: TSizes.xs,
        ),
        title: Text(
          'Connect to Exercise Apps',
          style: TextStyle(
            color: darkMode ? TColors.white : TColors.textPrimary,
            fontSize: TSizes.fontSizeMd,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Manage',
              style: TextStyle(
                color: TColors.primary,
                fontSize: TSizes.fontSizeMd,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: TSizes.xs),
            Icon(
              Icons.chevron_right,
              color: darkMode ? TColors.white : TColors.textSecondary,
            ),
          ],
        ),
        onTap: () => Get.to(() => const ConnectExerciseAppsScreen()),
      ),
    );
  }

  void _showStepsGoalDialog(BuildContext context, UpdateProfileController controller) {
    final darkMode = THelperFunctions.isDarkMode(context);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: darkMode ? TColors.darkContainer : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
          ),
          title: Text(
            'Daily Steps Goal',
            style: TextStyle(
              color: darkMode ? TColors.white : TColors.textPrimary,
              fontSize: TSizes.fontSizeLg,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set your daily steps target (1,000 - 50,000 steps)',
                  style: TextStyle(
                    color: TColors.textSecondary,
                    fontSize: TSizes.fontSizeSm,
                  ),
                ),
                const SizedBox(height: TSizes.md),
                TextFormField(
                  controller: controller.dailyStepsGoal,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(5),
                  ],
                  validator: TUserProfileValidator.validateDailyStepsGoal,
                  style: TextStyle(
                    color: darkMode ? TColors.white : TColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Steps per day',
                    labelStyle: TextStyle(color: TColors.textSecondary),
                    suffixText: 'steps',
                    suffixStyle: TextStyle(color: TColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
                      borderSide: BorderSide(color: TColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: TColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TSizes.buttonRadius),
                ),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showExerciseGoalDialog(BuildContext context, UpdateProfileController controller) {
    final darkMode = THelperFunctions.isDarkMode(context);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: darkMode ? TColors.darkContainer : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
          ),
          title: Text(
            'Weekly Exercise Goal',
            style: TextStyle(
              color: darkMode ? TColors.white : TColors.textPrimary,
              fontSize: TSizes.fontSizeLg,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set your weekly exercise time target (0 - 1,000 minutes)',
                  style: TextStyle(
                    color: TColors.textSecondary,
                    fontSize: TSizes.fontSizeSm,
                  ),
                ),
                const SizedBox(height: TSizes.md),
                TextFormField(
                  controller: controller.weeklyExerciseTime,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: TUserProfileValidator.validateWeeklyExerciseTime,
                  style: TextStyle(
                    color: darkMode ? TColors.white : TColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Minutes per week',
                    labelStyle: TextStyle(color: TColors.textSecondary),
                    suffixText: 'min',
                    suffixStyle: TextStyle(color: TColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
                      borderSide: BorderSide(color: TColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: TColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TSizes.buttonRadius),
                ),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}