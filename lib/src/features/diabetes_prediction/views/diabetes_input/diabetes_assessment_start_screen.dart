import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/diabetes_assessment_start_controller.dart';

class DiabetesAssessmentStartScreen extends StatelessWidget {
  const DiabetesAssessmentStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DiabetesAssessmentStartController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: darkMode ? TColors.black : TColors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.close,
              size: 28,
              color: darkMode ? TColors.white : TColors.black,
            ),
            onPressed: () => Get.back(),
            padding: EdgeInsets.only(right: 16),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView( // 添加滚动
          padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  kToolbarHeight, // 考虑AppBar和SafeArea高度
            ),
            child: Column(
              children: [
                // Header
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [TColors.primary, TColors.accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: TColors.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Iconsax.health_bold,
                        size: 60,
                        color: TColors.white,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title
                    Text(
                      'Diabetes Risk Assessment',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: darkMode ? TColors.white : TColors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    // Subtitle
                    Text(
                      'Get personalized insights about your diabetes risk in just 8 simple steps',
                      style: TextStyle(
                        fontSize: 16,
                        color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    // Features
                    _buildFeature(
                      icon: Icons.timer_outlined,
                      title: 'Quick & Easy',
                      subtitle: 'Takes only 5 minutes',
                      color: TColors.primary,
                      darkMode: darkMode,
                    ),

                    const SizedBox(height: 16),

                    _buildFeature(
                      icon: Icons.security_outlined,
                      title: 'Private & Secure',
                      subtitle: 'Your data is encrypted',
                      color: TColors.success,
                      darkMode: darkMode,
                    ),

                    const SizedBox(height: 16),

                    _buildFeature(
                      icon: Icons.psychology_outlined,
                      title: 'AI-Powered',
                      subtitle: 'Advanced prediction model',
                      color: TColors.warning,
                      darkMode: darkMode,
                    ),

                    const SizedBox(height: 16),
                  ],
                ),

                // Buttons
                Obx(() {
                  if (controller.isLoading.value) {
                    return Center(child: CircularProgressIndicator());
                  }

                  return Column(
                    children: [
                      // Continue button (if incomplete)
                      if (controller.hasIncomplete.value) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => controller.continueAssessment(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Continue Assessment',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: TColors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: () => controller.startNewAssessment(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: TColors.primary,
                              side: BorderSide(color: TColors.primary, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Start New',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => controller.startAssessment(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Let\'s Start',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: TColors.white,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Info text
                      Text(
                        'By continuing, you agree that this is not a medical diagnosis',
                        style: TextStyle(
                          fontSize: 12,
                          color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeature({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool darkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkMode ? TColors.darkerGrey.withOpacity(0.3) : TColors.softGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: darkMode ? TColors.white : TColors.black,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}