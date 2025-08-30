import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

import '../../../../utils/constants/colors.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/blood_glucose_controller.dart';

class BloodGlucoseInputScreen extends StatelessWidget {
  const BloodGlucoseInputScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BloodGlucoseController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: darkMode ? TColors.black : TColors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: darkMode ? TColors.white : TColors.black,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Blood Glucose',
          style: TextStyle(
            color: darkMode ? TColors.white : TColors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              Container(
                width: double.infinity,
                height: 6,
                decoration: BoxDecoration(
                  color: darkMode ? TColors.darkerGrey : TColors.grey,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.6,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [TColors.primary, TColors.accent],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Your Blood Glucose Level',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: darkMode ? TColors.white : TColors.black,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Enter your latest blood glucose reading',
                style: TextStyle(
                  fontSize: 16,
                  color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                ),
              ),

              const SizedBox(height: 48),

              Expanded(
                child: Column(
                  children: [
                    // Measurement Type Selector
                    _buildMeasurementTypeSelector(context, controller, darkMode),

                    const SizedBox(height: 40),

                    // Glucose Meter Design
                    _buildGlucoseMeter(context, controller, darkMode),

                    const SizedBox(height: 40),

                    // Quick Input Buttons
                    _buildQuickInputButtons(context, controller, darkMode),
                  ],
                ),
              ),

              // Continue Button
              Obx(() => Container(
                width: double.infinity,
                height: 56,
                margin: const EdgeInsets.only(top: 24),
                child: ElevatedButton(
                  onPressed: controller.canProceed.value
                      ? () => controller.saveAndContinue()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary,
                    disabledBackgroundColor: darkMode
                        ? TColors.darkerGrey
                        : TColors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: controller.canProceed.value
                          ? TColors.white
                          : darkMode
                          ? TColors.darkGrey
                          : TColors.darkerGrey,
                    ),
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeasurementTypeSelector(BuildContext context, BloodGlucoseController controller, bool darkMode) {
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

  Widget _buildGlucoseMeter(BuildContext context, BloodGlucoseController controller, bool darkMode) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: darkMode
              ? [TColors.darkerGrey.withOpacity(0.4), TColors.darkerGrey.withOpacity(0.2)]
              : [TColors.lightBlueColor, TColors.softGrey],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: darkMode ? TColors.darkerGrey : TColors.grey.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: darkMode ? Colors.black26 : TColors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
          Obx(() => SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: controller.getGlucoseColor(),
              inactiveTrackColor: darkMode ? TColors.darkerGrey : TColors.grey,
              thumbColor: controller.getGlucoseColor(),
              overlayColor: controller.getGlucoseColor().withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              trackHeight: 6,
            ),
            child: Slider(
              value: controller.currentValue.value,
              min: controller.measurementType.value == 'mg/dL' ? 50.0 : 3.0,
              max: controller.measurementType.value == 'mg/dL' ? 400.0 : 22.0,
              divisions: controller.measurementType.value == 'mg/dL' ? 350 : 190,
              onChanged: (value) => controller.updateGlucoseValue(value),
            ),
          )),

          // Range Indicators
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: controller.measurementType.value == 'mg/dL'
                  ? [
                _buildRangeText('50', TColors.third, darkMode),
                _buildRangeText('100', Colors.green, darkMode),
                _buildRangeText('200', Colors.orange, darkMode),
                _buildRangeText('400', Colors.red, darkMode),
              ]
                  : [
                _buildRangeText('3.0', TColors.third, darkMode),
                _buildRangeText('5.5', Colors.green, darkMode),
                _buildRangeText('11.0', Colors.orange, darkMode),
                _buildRangeText('22.0', Colors.red, darkMode),
              ],
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeText(String text, Color color, bool darkMode) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  Widget _buildQuickInputButtons(BuildContext context, BloodGlucoseController controller, bool darkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Select',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: darkMode ? TColors.white : TColors.black,
          ),
        ),

        const SizedBox(height: 16),

        Obx(() => Wrap(
          spacing: 12,
          runSpacing: 12,
          children: controller.getQuickSelectValues().map((value) {
            final isSelected = controller.currentValue.value == value['value'];
            return GestureDetector(
              onTap: () => controller.updateGlucoseValue(value['value']),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? controller.getGlucoseColor().withOpacity(0.1)
                      : darkMode
                      ? TColors.darkerGrey.withOpacity(0.3)
                      : TColors.softGrey,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? controller.getGlucoseColor()
                        : darkMode ? TColors.darkerGrey : TColors.grey,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '${value['value'].toStringAsFixed(controller.measurementType.value == 'mmol/L' ? 1 : 0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? controller.getGlucoseColor()
                            : darkMode ? TColors.white : TColors.black,
                      ),
                    ),
                    Text(
                      value['label'],
                      style: TextStyle(
                        fontSize: 10,
                        color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
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
}