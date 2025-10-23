import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/medication_adherence_controller.dart';
import 'widgets/diabetes_prediction_input_screen.dart';

class MedicationAdherenceInputScreen extends StatelessWidget {
  const MedicationAdherenceInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MedicationAdherenceController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return Obx(() => DiabetesPredictionInputScreen(
      title: 'Medication Adherence',
      progressValue: 0.875,
      showBackButton: true,
      canProceed: controller.canProceed,
      isLoading: controller.isLoading.value,
      continueButtonText: 'Continue',
      onContinue: () => controller.saveAndContinue(),
      content: SingleChildScrollView(
        child: Column(
          children: [
            SectionHeader(
              title: 'Diabetes Medication',
              subtitle: 'Tell us about your diabetes medication routine',
              questionNumber: 'Step 7 of 8',
              icon: Icons.medical_services,
              iconColor: Colors.deepPurple,
            ),

            const SizedBox(height: 40),

            // Medication Status Question
            InputContainer(
              darkMode: darkMode,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Do you take diabetes medication?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: darkMode ? TColors.white : TColors.black,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Yes/No buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildMedicationStatusButton(
                          'Yes',
                          true,
                          Icons.check_circle,
                          controller,
                          darkMode,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMedicationStatusButton(
                          'No',
                          false,
                          Icons.cancel,
                          controller,
                          darkMode,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Show medication adherence questions only if user takes medication
            Obx(() {
              if (controller.takesMedication.value == true) {
                return Column(
                  children: [
                    const SizedBox(height: 32),

                    // Medication Types
                    // InputContainer(
                    //   darkMode: darkMode,
                    //   child: Column(
                    //     crossAxisAlignment: CrossAxisAlignment.start,
                    //     children: [
                    //       Text(
                    //         'Type of diabetes medication',
                    //         style: TextStyle(
                    //           fontSize: 18,
                    //           fontWeight: FontWeight.w600,
                    //           color: darkMode ? TColors.white : TColors.black,
                    //         ),
                    //       ),
                    //       const SizedBox(height: 8),
                    //       Text(
                    //         'Select all that apply',
                    //         style: TextStyle(
                    //           fontSize: 14,
                    //           color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                    //         ),
                    //       ),
                    //
                    //       const SizedBox(height: 20),
                    //
                    //       // Medication type chips
                    //       Wrap(
                    //         spacing: 12,
                    //         runSpacing: 12,
                    //         children: [
                    //           _buildMedicationTypeChip('Metformin', Icons.medication, controller, darkMode),
                    //           _buildMedicationTypeChip('Insulin', Icons.colorize, controller, darkMode),
                    //           _buildMedicationTypeChip('Sulfonylureas', Icons.medication_liquid, controller, darkMode),
                    //           _buildMedicationTypeChip('DPP-4 inhibitors', Icons.medical_services, controller, darkMode),
                    //           _buildMedicationTypeChip('GLP-1 agonists', Icons.vaccines, controller, darkMode),
                    //           _buildMedicationTypeChip('Other', Icons.more_horiz, controller, darkMode),
                    //         ],
                    //       ),
                    //     ],
                    //   ),
                    // ),

                    // const SizedBox(height: 32),

                    // Adherence Frequency
                    InputContainer(
                      darkMode: darkMode,
                      child: Column(
                        children: [
                          Text(
                            'How often do you take your medication as prescribed?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: darkMode ? TColors.white : TColors.black,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Adherence Display
                          Obx(() => Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: controller.getAdherenceColor().withOpacity(0.1),
                              border: Border.all(
                                color: controller.getAdherenceColor(),
                                width: 4,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    controller.getAdherenceIcon(),
                                    size: 36,
                                    color: controller.getAdherenceColor(),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${controller.adherencePercentage.value}%',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: controller.getAdherenceColor(),
                                    ),
                                  ),
                                  Text(
                                    'adherence',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),

                          const SizedBox(height: 24),

                          // Adherence Status Description
                          Obx(() => Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: controller.getAdherenceColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                controller.getAdherenceDescription(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: controller.getAdherenceColor(),
                                ),
                              ),
                            ),
                          )),

                          const SizedBox(height: 32),

                          // Slider
                          Obx(() => CustomSlider(
                            value: controller.adherencePercentage.value.toDouble(),
                            min: 0,
                            max: 100,
                            divisions: 20, // 5% increments
                            onChanged: (value) => controller.setAdherencePercentage(value.toInt()),
                            activeColor: controller.getAdherenceColor(),
                            darkMode: darkMode,
                          )),

                          const SizedBox(height: 16),

                          // Scale indicators
                          RangeIndicators(
                            labels: ['0% (Never)', '80%+ (Good)', '100% (Always)'],
                            colors: [
                              Colors.red,
                              Colors.green,
                              Colors.blue,
                            ],
                            darkMode: darkMode,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Reasons for Missing Medication (if adherence < 100%)
                    Obx(() {
                      if (controller.adherencePercentage.value < 100) {
                        return InputContainer(
                          darkMode: darkMode,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Common reasons for missing medication',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: darkMode ? TColors.white : TColors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Select what applies to you (optional)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Reason chips
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  _buildReasonChip('Forgetfulness', Icons.psychology, controller, darkMode),
                                  _buildReasonChip('Side effects', Icons.warning, controller, darkMode),
                                  _buildReasonChip('Cost concerns', Icons.attach_money, controller, darkMode),
                                  _buildReasonChip('Busy schedule', Icons.schedule, controller, darkMode),
                                  _buildReasonChip('Feeling better', Icons.sentiment_satisfied, controller, darkMode),
                                  _buildReasonChip('Complex regimen', Icons.blur_on, controller, darkMode),
                                ],
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    ));
  }

  Widget _buildMedicationStatusButton(String label, bool value, IconData icon, MedicationAdherenceController controller, bool darkMode) {
    return Obx(() {
      final isSelected = controller.takesMedication.value == value;
      return GestureDetector(
        onTap: () => controller.setTakesMedication(value),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.deepPurple.withOpacity(0.1)
                : darkMode ? TColors.darkerGrey.withOpacity(0.5) : TColors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.deepPurple : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected
                    ? Colors.deepPurple
                    : darkMode ? TColors.white : TColors.black,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.deepPurple
                      : darkMode ? TColors.white : TColors.black,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildMedicationTypeChip(String label, IconData icon, MedicationAdherenceController controller, bool darkMode) {
    return Obx(() {
      final isSelected = controller.medicationTypes.contains(label);
      return GestureDetector(
        onTap: () => controller.toggleMedicationType(label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.deepPurple.withOpacity(0.1)
                : darkMode ? TColors.darkerGrey.withOpacity(0.5) : TColors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.deepPurple : Colors.transparent,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.deepPurple
                    : darkMode ? TColors.white : TColors.black,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.deepPurple
                      : darkMode ? TColors.white : TColors.black,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildReasonChip(String label, IconData icon, MedicationAdherenceController controller, bool darkMode) {
    return Obx(() {
      final isSelected = controller.missedReasons.contains(label);
      return GestureDetector(
        onTap: () => controller.toggleMissedReason(label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.orange.withOpacity(0.1)
                : darkMode ? TColors.darkerGrey.withOpacity(0.5) : TColors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.orange : Colors.transparent,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.orange
                    : darkMode ? TColors.white : TColors.black,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.orange
                      : darkMode ? TColors.white : TColors.black,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}