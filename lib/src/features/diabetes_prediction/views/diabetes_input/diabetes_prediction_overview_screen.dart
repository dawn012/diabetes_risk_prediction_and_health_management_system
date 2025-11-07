import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/diabetes_prediction_overview_controller.dart';

class DiabetesPredictionOverviewScreen extends StatelessWidget {
  const DiabetesPredictionOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DiabetesPredictionOverviewController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: darkMode ? TColors.black : TColors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Diabetes Risk Assessment',
          style: TextStyle(
            color: darkMode ? TColors.white : TColors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.close,
              size: 28,
              color: darkMode ? TColors.white : TColors.black,
            ),
            onPressed: () {
              // Use Get.until to go back to main screen
              // Assumes main screen route name is something like '/home' or first route
              Get.until((route) => route.isFirst);
            },
            padding: EdgeInsets.only(right: 16),
          ),
        ],
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        return SafeArea(
          child: Column(
            children: [
              // Progress Summary Card
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: _buildProgressCard(controller, darkMode),
              ),

              // Steps List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  children: [
                    _buildStepTile(
                      context: context,
                      controller: controller,
                      darkMode: darkMode,
                      stepNumber: 1,
                      title: 'Height & Weight',
                      icon: Icons.straighten,
                      color: TColors.primary,
                      isCompleted: controller.isStepCompleted(1),
                      value: controller.getStepValue(1),
                      onTap: () => controller.navigateToStep(1),
                      showSync: controller.shouldShowSync(1),
                      onSync: () => controller.syncStep(1),
                    ),
                    _buildStepTile(
                      context: context,
                      controller: controller,
                      darkMode: darkMode,
                      stepNumber: 2,
                      title: 'Blood Glucose',
                      icon: Icons.bloodtype,
                      color: TColors.error,
                      isCompleted: controller.isStepCompleted(2),
                      value: controller.getStepValue(2),
                      onTap: () => controller.navigateToStep(2),
                      showSync: controller.shouldShowSync(2),
                      onSync: () => controller.syncStep(2),
                    ),
                    _buildStepTile(
                      context: context,
                      controller: controller,
                      darkMode: darkMode,
                      stepNumber: 3,
                      title: 'Physical Activity',
                      icon: Icons.directions_run,
                      color: TColors.secondary,
                      isCompleted: controller.isStepCompleted(3),
                      value: controller.getStepValue(3),
                      onTap: () => controller.navigateToStep(3),
                      showSync: controller.shouldShowSync(3),
                      onSync: () => controller.syncStep(3),
                    ),
                    _buildStepTile(
                      context: context,
                      controller: controller,
                      darkMode: darkMode,
                      stepNumber: 4,
                      title: 'Stress Level',
                      icon: Icons.psychology,
                      color: TColors.warning,
                      isCompleted: controller.isStepCompleted(4),
                      value: controller.getStepValue(4),
                      onTap: () => controller.navigateToStep(4),
                    ),
                    _buildStepTile(
                      context: context,
                      controller: controller,
                      darkMode: darkMode,
                      stepNumber: 5,
                      title: 'Sleep Duration',
                      icon: Icons.bedtime,
                      color: TColors.info,
                      isCompleted: controller.isStepCompleted(5),
                      value: controller.getStepValue(5),
                      onTap: () => controller.navigateToStep(5),
                    ),
                    _buildStepTile(
                      context: context,
                      controller: controller,
                      darkMode: darkMode,
                      stepNumber: 6,
                      title: 'Daily Water Intake',
                      icon: Icons.water_drop,
                      color: Colors.blue,
                      isCompleted: controller.isStepCompleted(6),
                      value: controller.getStepValue(6),
                      onTap: () => controller.navigateToStep(6),
                    ),
                    _buildStepTile(
                      context: context,
                      controller: controller,
                      darkMode: darkMode,
                      stepNumber: 7,
                      title: 'Medicine Prescribed',
                      icon: Icons.medication,
                      color: Colors.purple,
                      isCompleted: controller.isStepCompleted(7),
                      value: controller.getStepValue(7),
                      onTap: () => controller.navigateToStep(7),
                    ),
                    _buildStepTile(
                      context: context,
                      controller: controller,
                      darkMode: darkMode,
                      stepNumber: 8,
                      title: 'Diet Quality',
                      icon: Icons.restaurant,
                      color: Colors.green,
                      isCompleted: controller.isStepCompleted(8),
                      value: controller.getStepValue(8),
                      onTap: () => controller.navigateToStep(8),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
      bottomNavigationBar: Obx(() => Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: darkMode ? TColors.black : TColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: controller.allStepsCompleted.value
                ? () => controller.startPrediction()
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: TColors.primary,
              disabledBackgroundColor: darkMode ? TColors.darkerGrey : TColors.grey,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Start Prediction',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: controller.allStepsCompleted.value
                    ? TColors.white
                    : darkMode ? TColors.darkGrey : TColors.darkerGrey,
              ),
            ),
          ),
        ),
      )),
    );
  }

  Widget _buildProgressCard(DiabetesPredictionOverviewController controller, bool darkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [TColors.primary, TColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: TColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Assessment Progress',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: TColors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: TColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Obx(() => Text(
                  '${controller.completedSteps.value}/8',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: TColors.white,
                  ),
                )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Obx(() => LinearProgressIndicator(
              value: controller.completedSteps.value / 8,
              minHeight: 8,
              backgroundColor: TColors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(TColors.white),
            )),
          ),
          const SizedBox(height: 12),
          Obx(() => Text(
            controller.allStepsCompleted.value
                ? 'All steps completed! Ready to predict.'
                : '${8 - controller.completedSteps.value} steps remaining',
            style: TextStyle(
              fontSize: 14,
              color: TColors.white.withOpacity(0.9),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildStepTile({
    required BuildContext context,
    required DiabetesPredictionOverviewController controller,
    required bool darkMode,
    required int stepNumber,
    required String title,
    required IconData icon,
    required Color color,
    required bool isCompleted,
    String? value,
    required VoidCallback onTap,
    bool showSync = false,
    VoidCallback? onSync,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: darkMode ? TColors.darkerGrey.withOpacity(0.3) : TColors.softGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? color.withOpacity(0.5) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Step Number Circle
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isCompleted ? color : color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(Icons.check, color: TColors.white, size: 24)
                        : Text(
                      '$stepNumber',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Step Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, color: color, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: darkMode ? TColors.white : TColors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (value != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 14,
                            color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                          ),
                        ),
                      ] else if (!isCompleted) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Not completed',
                          style: TextStyle(
                            fontSize: 14,
                            color: TColors.warning,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Sync Button or Arrow
                if (showSync && onSync != null)
                  IconButton(
                    onPressed: onSync,
                    icon: Icon(Icons.sync, color: color),
                    tooltip: 'Sync from health logs',
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}