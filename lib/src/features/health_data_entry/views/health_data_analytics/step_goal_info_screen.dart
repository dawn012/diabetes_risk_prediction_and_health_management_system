import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';

class StepsGoalInfoScreen extends StatelessWidget {
  const StepsGoalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: darkMode ? TColors.dark : TColors.light,
      appBar: AppBar(
        backgroundColor: TColors.primary,
        title: const Text(
          'Steps Goal',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The World Health Organization characterizes lifestyle levels based on the daily steps ranges below:',
              style: TextStyle(
                color: darkMode ? TColors.white : TColors.textPrimary,
                fontSize: TSizes.fontSizeMd,
                height: 1.5,
              ),
            ),

            const SizedBox(height: TSizes.lg),

            _buildStepsRange('< 5000', 'Sedentary lifestyle', darkMode),
            _buildStepsRange('5000 - 7499', 'Low active', darkMode),
            _buildStepsRange('7500 - 9999', 'Somewhat active', darkMode),
            _buildStepsRange('≥ 10000', 'Active', darkMode),
            _buildStepsRange('≥ 12500', 'Highly active', darkMode),

            const SizedBox(height: TSizes.lg),

            Text(
              'You can discuss with your doctor or care team to set a goal suitable for you. You can use your spare time to increase your daily steps, such as taking the stairs instead of the elevator, walking for 10 minutes after meals, and walking rather than driving for short-distance commutes.',
              style: TextStyle(
                color: darkMode ? TColors.white : TColors.textPrimary,
                fontSize: TSizes.fontSizeMd,
                height: 1.5,
              ),
            ),

            const SizedBox(height: TSizes.lg),

            Text(
              'Source: WHO',
              style: TextStyle(
                color: TColors.textSecondary,
                fontSize: TSizes.fontSizeSm,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsRange(String range, String description, bool darkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.sm),
      child: Text(
        '$range $description',
        style: TextStyle(
          color: darkMode ? TColors.white : TColors.textPrimary,
          fontSize: TSizes.fontSizeMd,
          height: 1.4,
        ),
      ),
    );
  }
}