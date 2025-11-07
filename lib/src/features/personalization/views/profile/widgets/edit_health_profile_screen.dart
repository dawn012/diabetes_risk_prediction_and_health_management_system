import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:intl/intl.dart';

import '../../../../../common/widgets/appbar/appbar.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/validators/user_profile_validator.dart';
import '../../../controllers/update_profile_controller.dart';

class EditHealthProfileScreen extends StatelessWidget {
  const EditHealthProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UpdateProfileController());

    return Scaffold(
      appBar: const TAppBar(
        showBackArrow: true,
        title: Text('Edit Health Profile'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Form(
            key: controller.healthProfileFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Instructions
                Text(
                  'Update your health information for better recommendations',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: TSizes.spaceBtwSections),

                /// Gender Selection
                Obx(() => DropdownButtonFormField<String>(
                  value: controller.selectedGender.value.isEmpty
                      ? null
                      : controller.selectedGender.value,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: Icon(Iconsax.user_bold),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'M', child: Text('Male')),
                    DropdownMenuItem(value: 'F', child: Text('Female')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectedGender.value = value;
                      controller.update();
                    }
                  },
                  validator: TUserProfileValidator.validateGender,
                )),
                const SizedBox(height: TSizes.spaceBtwInputFields),

                /// Date of Birth
                Obx(() => TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Date of Birth',
                    prefixIcon: const Icon(Iconsax.calendar_bold),
                    hintText: 'Select your date of birth',
                    suffixIcon: IconButton(
                      icon: const Icon(Iconsax.calendar_1_bold),
                      onPressed: () => _selectDateOfBirth(context, controller),
                    ),
                  ),
                  controller: TextEditingController(
                    text: controller.selectedDateOfBirth.value != null
                        ? DateFormat('dd/MM/yyyy')
                        .format(controller.selectedDateOfBirth.value!)
                        : '',
                  ),
                  validator: (value) =>
                      TUserProfileValidator.validateDateOfBirth(
                          controller.selectedDateOfBirth.value),
                  onTap: () => _selectDateOfBirth(context, controller),
                )),
                const SizedBox(height: TSizes.spaceBtwInputFields),

                /// Weight
                TextFormField(
                  controller: controller.weight,
                  validator: TUserProfileValidator.validateWeight,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    prefixIcon: Icon(Iconsax.weight_bold),
                    hintText: 'e.g., 70.5',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                  ],
                ),
                const SizedBox(height: TSizes.spaceBtwInputFields),

                /// Height
                TextFormField(
                  controller: controller.height,
                  validator: TUserProfileValidator.validateHeight,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Height (cm)',
                    prefixIcon: Icon(Iconsax.arrow_up_3_bold),
                    hintText: 'e.g., 170.5',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                  ],
                ),
                const SizedBox(height: TSizes.spaceBtwInputFields),

                /// Diet Preference
                TextFormField(
                  controller: controller.dietPreference,
                  decoration: const InputDecoration(
                    labelText: 'Diet Preference',
                    prefixIcon: Icon(Iconsax.cake_bold),
                    hintText: 'e.g., Vegetarian, Halal',
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwInputFields),

                /// Allergies (Multi-line)
                TextFormField(
                  controller: controller.allergies,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Allergies',
                    prefixIcon: Icon(Iconsax.warning_2_bold),
                    hintText: 'Separate with commas (e.g., Peanuts, Seafood)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwInputFields),

                // /// Is Taking Medication
                // Obx(() => SwitchListTile(
                //   title: const Text('Taking Diabetes Medication'),
                //   subtitle: const Text('Are you currently on medication?'),
                //   value: controller.isTakeMedication.value,
                //   onChanged: (value) {
                //     controller.isTakeMedication.value = value;
                //     controller.update();
                //   },
                //   contentPadding: EdgeInsets.zero,
                // )),
                // const SizedBox(height: TSizes.spaceBtwInputFields),
                //
                // /// Prescribed Frequency (Only show if taking medication)
                // Obx(() {
                //   if (!controller.isTakeMedication.value) {
                //     return const SizedBox.shrink();
                //   }
                //   return TextFormField(
                //     controller: controller.medicationAdherence,
                //     validator: controller.isTakeMedication.value
                //         ? TUserProfileValidator.validatePrescribedFrequency
                //         : null,
                //     keyboardType: TextInputType.number,
                //     decoration: const InputDecoration(
                //       labelText: 'Medication Frequency (times/day)',
                //       prefixIcon: Icon(Iconsax.timer_bold),
                //       hintText: 'e.g., 2',
                //     ),
                //     inputFormatters: [
                //       FilteringTextInputFormatter.digitsOnly,
                //       LengthLimitingTextInputFormatter(2),
                //     ],
                //   );
                // }),
                // if (controller.isTakeMedication.value)
                //   const SizedBox(height: TSizes.spaceBtwInputFields),
                //
                // /// Sleep Duration
                // TextFormField(
                //   controller: controller.sleepDuration,
                //   validator: TUserProfileValidator.validateSleepDuration,
                //   keyboardType: const TextInputType.numberWithOptions(decimal: true),
                //   decoration: const InputDecoration(
                //     labelText: 'Average Sleep Duration (hours)',
                //     prefixIcon: Icon(Iconsax.moon_bold),
                //     hintText: 'e.g., 7.5',
                //   ),
                //   inputFormatters: [
                //     FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                //   ],
                // ),
                // const SizedBox(height: TSizes.spaceBtwInputFields),
                //
                // /// Stress Level
                // Obx(() => DropdownButtonFormField<int>(
                //   value: controller.selectedStressLevel.value == 0
                //       ? null
                //       : controller.selectedStressLevel.value,
                //   decoration: const InputDecoration(
                //     labelText: 'Stress Level',
                //     prefixIcon: Icon(Iconsax.heart_bold),
                //   ),
                //   items: const [
                //     DropdownMenuItem(value: 1, child: Text('Low')),
                //     DropdownMenuItem(value: 2, child: Text('Medium')),
                //     DropdownMenuItem(value: 3, child: Text('High')),
                //   ],
                //   onChanged: (value) {
                //     if (value != null) {
                //       controller.selectedStressLevel.value = value;
                //       controller.update();
                //     }
                //   },
                //   validator: TUserProfileValidator.validateStressLevel,
                // )),
                // const SizedBox(height: TSizes.spaceBtwInputFields),
                //
                // /// Water Intake
                // TextFormField(
                //   controller: controller.waterIntake,
                //   validator: TUserProfileValidator.validateWaterIntake,
                //   keyboardType: TextInputType.number,
                //   decoration: const InputDecoration(
                //     labelText: 'Daily Water Intake (ml)',
                //     prefixIcon: Icon(Iconsax.drop_bold),
                //     hintText: 'e.g., 2000',
                //   ),
                //   inputFormatters: [
                //     FilteringTextInputFormatter.digitsOnly,
                //     LengthLimitingTextInputFormatter(5),
                //   ],
                // ),
                // const SizedBox(height: TSizes.spaceBtwSections),

                /// Save Button
                Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.isHealthProfileLoading.value
                        ? null
                        : () => controller.updateHealthProfile(),
                    child: controller.isHealthProfileLoading.value
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text('Save Health Profile'),
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateOfBirth(
      BuildContext context, UpdateProfileController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDateOfBirth.value ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
    );

    if (picked != null) {
      controller.selectedDateOfBirth.value = picked;
      controller.update();
    }
  }
}