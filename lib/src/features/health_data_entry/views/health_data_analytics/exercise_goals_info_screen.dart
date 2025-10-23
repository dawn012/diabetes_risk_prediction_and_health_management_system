import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';

class ExerciseGoalsInfoScreen extends StatelessWidget {
  const ExerciseGoalsInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: darkMode ? TColors.dark : TColors.light,
      appBar: AppBar(
        backgroundColor: TColors.primary,
        title: const Text(
          'Exercise Goals',
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
              'The World Health Organization recommends that adults aged 18 to 64 should do at least 150 minutes of moderate-intensity exercise every week. If your health conditions permit, you should try to do moderate-intensity exercises.',
              style: TextStyle(
                color: darkMode ? TColors.white : TColors.textPrimary,
                fontSize: TSizes.fontSizeMd,
                height: 1.5,
              ),
            ),

            const SizedBox(height: TSizes.lg),

            Text(
              'Determining Intensity Level',
              style: TextStyle(
                color: darkMode ? TColors.white : TColors.textPrimary,
                fontSize: TSizes.fontSizeLg,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: TSizes.md),

            _buildIntensityItem(
              icon: Icons.circle,
              iconColor: TColors.warning,
              title: 'Moderate-intensity',
              description: 'You can still talk without any difficulties after 10 minutes of exercise, but singing may be very difficult. You may feel a bit tired and have started sweating. Your breath and pulse will be a little faster than usual.',
              darkMode: darkMode,
            ),

            const SizedBox(height: TSizes.md),

            _buildIntensityItem(
              icon: Icons.circle,
              iconColor: TColors.error,
              title: 'High-intensity',
              description: 'After 10 minutes of exercise, trying to talk would cause you to pant.',
              darkMode: darkMode,
            ),

            const SizedBox(height: TSizes.lg),

            Text(
              'The Benefits of Exercise',
              style: TextStyle(
                color: darkMode ? TColors.white : TColors.textPrimary,
                fontSize: TSizes.fontSizeLg,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: TSizes.md),

            _buildBenefitItem(
              number: '1',
              text: 'Can accelerate insulin secretion and decrease HbA1c. Research has shown that regular exercise can extend insulin sensitivity up to 48 hours.',
              darkMode: darkMode,
            ),

            _buildBenefitItem(
              number: '2',
              text: 'Good for weight control and regulating blood lipids, reducing the risk of cardiovascular diseases.',
              darkMode: darkMode,
            ),

            _buildBenefitItem(
              number: '3',
              text: 'Resistance exercises can help raise your bone mineral density.',
              darkMode: darkMode,
            ),

            const SizedBox(height: TSizes.lg),

            Text(
              'Exercise Caveats',
              style: TextStyle(
                color: darkMode ? TColors.white : TColors.textPrimary,
                fontSize: TSizes.fontSizeLg,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: TSizes.md),

            _buildCaveatItem(
              number: '1',
              text: 'Avoid exercising when you haven\'t eaten for several hours or when your blood glucose is below 100 mg/dL (5.6 mmol/L). Make sure you have some food in your system before you exercise to prevent hypoglycemia.',
              darkMode: darkMode,
            ),

            _buildCaveatItem(
              number: '2',
              text: 'If your blood glucose is > 300 mg/dL (16.7 mmol/L) or blood pressure is > 200/110 mmHg, rest for a while before you exercise again to prevent further rise in your blood glucose.',
              darkMode: darkMode,
            ),

            _buildCaveatItem(
              number: '3',
              text: 'Pay attention to your blood glucose after exercise, and consume additional carbs if needed.',
              darkMode: darkMode,
            ),

            _buildCaveatItem(
              number: '4',
              text: 'Talk to you doctor or care team to find safe and suitable exercises for you.',
              darkMode: darkMode,
            ),

            const SizedBox(height: TSizes.lg),

            Text(
              'Source: WHO, American Diabetes Association, Blood Pressure UK',
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

  Widget _buildIntensityItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool darkMode,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: TSizes.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: darkMode ? TColors.white : TColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: TSizes.xs),
              Text(
                description,
                style: TextStyle(
                  color: darkMode ? TColors.white : TColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem({
    required String number,
    required String text,
    required bool darkMode,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: TColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: TSizes.sm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: darkMode ? TColors.white : TColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaveatItem({
    required String number,
    required String text,
    required bool darkMode,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: TColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: TSizes.sm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: darkMode ? TColors.white : TColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}