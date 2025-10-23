import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

import '../../../../utils/constants/colors.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/diabetes_blood_glucose_controller.dart';
import 'widgets/diabetes_prediction_input_screen.dart';

class BloodGlucoseInputScreen extends StatelessWidget {
  const BloodGlucoseInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DiabetesBloodGlucoseController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return Obx(() => DiabetesPredictionInputScreen(
      title: 'Blood Glucose',
      progressValue: 0.25, // 2/8 steps completed
      showBackButton: true,
      canProceed: controller.canProceed.value,
      isLoading: controller.isLoading.value,
      onContinue: () => controller.saveAndContinue(),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Your Blood Glucose Level',
              subtitle: 'Enter your latest blood glucose reading',
              questionNumber: 'Step 2 of 8',
              icon: Icons.bloodtype,
              iconColor: TColors.primary,
            ),
        
            const SizedBox(height: 48),
        
            // Measurement Type Selector
            _buildMeasurementTypeSelector(context, controller, darkMode),
        
            const SizedBox(height: 40),
        
            // Glucose Meter Design
            _buildGlucoseMeter(context, controller, darkMode),
          ],
        ),
      ),
    ));
  }

  Widget _buildMeasurementTypeSelector(BuildContext context, DiabetesBloodGlucoseController controller, bool darkMode) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: darkMode ? TColors.darkerGrey.withOpacity(0.3) : TColors.softGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Obx(() => Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => controller.setMeasurementType('mg/dL'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: controller.measurementType.value == 'mg/dL'
                      ? TColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'mg/dL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: controller.measurementType.value == 'mg/dL'
                        ? TColors.white
                        : darkMode ? TColors.darkGrey : TColors.darkerGrey,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => controller.setMeasurementType('mmol/L'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: controller.measurementType.value == 'mmol/L'
                      ? TColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'mmol/L',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: controller.measurementType.value == 'mmol/L'
                        ? TColors.white
                        : darkMode ? TColors.darkGrey : TColors.darkerGrey,
                  ),
                ),
              ),
            ),
          ),
        ],
      )),
    );
  }

  Widget _buildGlucoseMeter(BuildContext context, DiabetesBloodGlucoseController controller, bool darkMode) {
    return InputContainer(
      darkMode: darkMode,
      child: Column(
        children: [
          // Glucose Meter Display
          Container(
            width: 280,
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Ring with Gradient
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [TColors.primary, TColors.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),

                // Inner Background
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: darkMode ? TColors.black : TColors.white,
                  ),
                ),

                // Gauge Markings
                ...List.generate(12, (index) {
                  final angle = (index * 30) * math.pi / 180;
                  final isMainMark = index % 3 == 0;
                  return Transform.rotate(
                    angle: angle,
                    child: Container(
                      width: 4,
                      height: isMainMark ? 30 : 15,
                      margin: EdgeInsets.only(top: isMainMark ? 10 : 17.5),
                      decoration: BoxDecoration(
                        color: TColors.primary.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),

                // Glucose Value Display
                Obx(() => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      controller.currentValue.value.toStringAsFixed(
                          controller.measurementType.value == 'mmol/L' ? 1 : 0
                      ),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: controller.getGlucoseColor(),
                      ),
                    ),
                    Text(
                      controller.measurementType.value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: controller.getGlucoseColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        controller.getGlucoseStatus(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: controller.getGlucoseColor(),
                        ),
                      ),
                    ),
                  ],
                )),

                // Interactive Needle/Pointer
                Obx(() => Transform.rotate(
                  angle: controller.getNeedleAngle(),
                  child: Container(
                    width: 4,
                    height: 80,
                    decoration: BoxDecoration(
                      color: controller.getGlucoseColor(),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),

                // Center Dot
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: TColors.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Fine Adjustment Slider
          Obx(() => CustomSlider(
            value: controller.currentValue.value,
            min: controller.measurementType.value == 'mg/dL' ? 50.0 : 2.8,
            max: controller.measurementType.value == 'mg/dL' ? 400.0 : 22.0,
            divisions: controller.measurementType.value == 'mg/dL' ? 350 : 190,
            onChanged: (value) => controller.updateGlucoseValue(value),
            activeColor: controller.getGlucoseColor(),
            darkMode: darkMode,
          )),

          const SizedBox(height: 16),

          // Range Indicators
          Obx(() => RangeIndicators(
            labels: controller.measurementType.value == 'mg/dL'
                ? ['50', '100', '200', '400']
                : ['3.0', '5.5', '11.0', '22.0'],
            colors: controller.measurementType.value == 'mg/dL'
                ? [TColors.third, Colors.green, Colors.orange, Colors.red]
                : [TColors.third, Colors.green, Colors.orange, Colors.red],
            darkMode: darkMode,
          )),
        ],
      ),
    );
  }
}