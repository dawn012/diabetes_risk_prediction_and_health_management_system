import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/height_weight_controller.dart';

class HeightWeightInputScreen extends StatelessWidget {
  const HeightWeightInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HeightWeightController());
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
          'Health Metrics',
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
                  widthFactor: 0.3,
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
                'Let\'s get your measurements',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: darkMode ? TColors.white : TColors.black,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'This helps us provide more accurate predictions',
                style: TextStyle(
                  fontSize: 16,
                  color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                ),
              ),

              const SizedBox(height: 48),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Height Section
                      _buildHeightSection(context, controller, darkMode),

                      const SizedBox(height: 48),

                      // Weight Section
                      _buildWeightSection(context, controller, darkMode),
                    ],
                  ),
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

  Widget _buildHeightSection(BuildContext context, HeightWeightController controller, bool darkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: darkMode ? TColors.darkerGrey.withOpacity(0.3) : TColors.softGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: darkMode ? TColors.darkerGrey : TColors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.height,
                  color: TColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Height',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: darkMode ? TColors.white : TColors.black,
                    ),
                  ),
                  Text(
                    'Drag the ruler to set your height',
                    style: TextStyle(
                      fontSize: 14,
                      color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Height Display
          Center(
            child: Obx(() => Column(
              children: [
                Text(
                  '${controller.height.value.toInt()}',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: TColors.primary,
                  ),
                ),
                Text(
                  'cm',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                  ),
                ),
              ],
            )),
          ),

          const SizedBox(height: 24),

          // Custom Height Slider with Ruler Design
          SizedBox(
            height: 80,
            child: Obx(() => SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: TColors.primary,
                inactiveTrackColor: darkMode ? TColors.darkerGrey : TColors.grey,
                thumbColor: TColors.primary,
                overlayColor: TColors.primary.withOpacity(0.2),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                trackHeight: 6,
              ),
              child: Slider(
                value: controller.height.value,
                min: 100,
                max: 250,
                divisions: 150,
                onChanged: (value) => controller.updateHeight(value),
              ),
            )),
          ),

          // Ruler markings
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('100cm', style: TextStyle(
                  fontSize: 12,
                  color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                )),
                Text('175cm', style: TextStyle(
                  fontSize: 12,
                  color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                )),
                Text('250cm', style: TextStyle(
                  fontSize: 12,
                  color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightSection(BuildContext context, HeightWeightController controller, bool darkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: darkMode ? TColors.darkerGrey.withOpacity(0.3) : TColors.softGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: darkMode ? TColors.darkerGrey : TColors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.monitor_weight_outlined,
                  color: TColors.secondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weight',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: darkMode ? TColors.white : TColors.black,
                    ),
                  ),
                  Text(
                    'Use the dial to set your weight',
                    style: TextStyle(
                      fontSize: 14,
                      color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Weight Display with Circular Dial Design
          Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Circular Background
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: darkMode ? TColors.darkerGrey : TColors.grey,
                        width: 2,
                      ),
                    ),
                  ),

                  // Weight Value
                  Obx(() => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${controller.weight.value.toInt()}',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: TColors.secondary,
                        ),
                      ),
                      Text(
                        'kg',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                        ),
                      ),
                    ],
                  )),

                  // Circular Slider
                  Obx(() => Transform.rotate(
                    angle: (controller.weight.value - 30) / 120 * 3.14159 * 1.5,
                    child: Container(
                      width: 180,
                      height: 180,
                      child: CircularProgressIndicator(
                        value: (controller.weight.value - 30) / 120,
                        strokeWidth: 8,
                        backgroundColor: darkMode ? TColors.darkerGrey : TColors.grey,
                        valueColor: AlwaysStoppedAnimation<Color>(TColors.secondary),
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Weight Control Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildWeightButton(
                context,
                Icons.remove,
                    () => controller.decreaseWeight(),
                darkMode,
              ),
              _buildWeightButton(
                context,
                Icons.add,
                    () => controller.increaseWeight(),
                darkMode,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Fine adjustment slider
          Obx(() => SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: TColors.secondary,
              inactiveTrackColor: darkMode ? TColors.darkerGrey : TColors.grey,
              thumbColor: TColors.secondary,
              overlayColor: TColors.secondary.withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              trackHeight: 4,
            ),
            child: Slider(
              value: controller.weight.value,
              min: 30,
              max: 150,
              divisions: 240, // 0.5kg increments
              onChanged: (value) => controller.updateWeight(value),
            ),
          )),

          // Weight range indicators
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('30kg', style: TextStyle(
                  fontSize: 12,
                  color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                )),
                Text('90kg', style: TextStyle(
                  fontSize: 12,
                  color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                )),
                Text('150kg', style: TextStyle(
                  fontSize: 12,
                  color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightButton(BuildContext context, IconData icon, VoidCallback onPressed, bool darkMode) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: TColors.secondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: TColors.secondary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: TColors.secondary,
          size: 24,
        ),
      ),
    );
  }
}