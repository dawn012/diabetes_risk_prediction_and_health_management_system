// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:icons_plus/icons_plus.dart';
// import 'package:intl/intl.dart';
//
// import '../../../../../common/widgets/appbar/appbar.dart';
// import '../../../../../utils/constants/sizes.dart';
// import '../../../../../utils/validators/user_profile_validator.dart';
// import '../../../controllers/update_profile_controller.dart';
//
// class EditHealthProfileScreen extends StatelessWidget {
//   const EditHealthProfileScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.put(UpdateProfileController());
//
//     return Scaffold(
//       appBar: const TAppBar(
//         showBackArrow: true,
//         title: Text('Edit Health Profile'),
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(TSizes.defaultSpace),
//           child: Form(
//             key: controller.healthProfileFormKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 /// Instructions
//                 Text(
//                   'Update your health information for better recommendations',
//                   style: Theme.of(context).textTheme.bodyMedium,
//                 ),
//                 const SizedBox(height: TSizes.spaceBtwSections),
//
//                 /// Gender Selection
//                 Obx(() => DropdownButtonFormField<String>(
//                   value: controller.selectedGender.value.isEmpty
//                       ? null
//                       : controller.selectedGender.value,
//                   decoration: const InputDecoration(
//                     labelText: 'Gender',
//                     prefixIcon: Icon(Iconsax.user_bold),
//                   ),
//                   items: const [
//                     DropdownMenuItem(value: 'M', child: Text('Male')),
//                     DropdownMenuItem(value: 'F', child: Text('Female')),
//                   ],
//                   onChanged: (value) {
//                     if (value != null) {
//                       controller.selectedGender.value = value;
//                       controller.update();
//                     }
//                   },
//                   validator: TUserProfileValidator.validateGender,
//                 )),
//                 const SizedBox(height: TSizes.spaceBtwInputFields),
//
//                 /// Date of Birth
//                 Obx(() => TextFormField(
//                   readOnly: true,
//                   decoration: InputDecoration(
//                     labelText: 'Date of Birth',
//                     prefixIcon: const Icon(Iconsax.calendar_bold),
//                     hintText: 'Select your date of birth',
//                     suffixIcon: IconButton(
//                       icon: const Icon(Iconsax.calendar_1_bold),
//                       onPressed: () => _selectDateOfBirth(context, controller),
//                     ),
//                   ),
//                   controller: TextEditingController(
//                     text: controller.selectedDateOfBirth.value != null
//                         ? DateFormat('dd/MM/yyyy')
//                         .format(controller.selectedDateOfBirth.value!)
//                         : '',
//                   ),
//                   validator: (value) =>
//                       TUserProfileValidator.validateDateOfBirth(
//                           controller.selectedDateOfBirth.value),
//                   onTap: () => _selectDateOfBirth(context, controller),
//                 )),
//                 const SizedBox(height: TSizes.spaceBtwInputFields),
//
//                 /// Weight
//                 TextFormField(
//                   controller: controller.weight,
//                   validator: TUserProfileValidator.validateWeight,
//                   keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                   decoration: const InputDecoration(
//                     labelText: 'Weight (kg)',
//                     prefixIcon: Icon(Iconsax.weight_bold),
//                     hintText: 'e.g., 70.5',
//                   ),
//                   inputFormatters: [
//                     FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
//                   ],
//                 ),
//                 const SizedBox(height: TSizes.spaceBtwInputFields),
//
//                 /// Height
//                 TextFormField(
//                   controller: controller.height,
//                   validator: TUserProfileValidator.validateHeight,
//                   keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                   decoration: const InputDecoration(
//                     labelText: 'Height (cm)',
//                     prefixIcon: Icon(Iconsax.arrow_up_3_bold),
//                     hintText: 'e.g., 170.5',
//                   ),
//                   inputFormatters: [
//                     FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
//                   ],
//                 ),
//                 const SizedBox(height: TSizes.spaceBtwInputFields),
//
//                 /// Diet Preference
//                 TextFormField(
//                   controller: controller.dietPreference,
//                   decoration: const InputDecoration(
//                     labelText: 'Diet Preference',
//                     prefixIcon: Icon(Iconsax.cake_bold),
//                     hintText: 'e.g., Vegetarian, Halal',
//                   ),
//                 ),
//                 const SizedBox(height: TSizes.spaceBtwInputFields),
//
//                 /// Allergies (Multi-line)
//                 TextFormField(
//                   controller: controller.allergies,
//                   maxLines: 3,
//                   decoration: const InputDecoration(
//                     labelText: 'Allergies',
//                     prefixIcon: Icon(Iconsax.warning_2_bold),
//                     hintText: 'Separate with commas (e.g., Peanuts, Seafood)',
//                     alignLabelWithHint: true,
//                   ),
//                 ),
//                 const SizedBox(height: TSizes.spaceBtwInputFields),
//
//                 /// Save Button
//                 Obx(() => SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: controller.isHealthProfileLoading.value
//                         ? null
//                         : () => controller.updateHealthProfile(),
//                     child: controller.isHealthProfileLoading.value
//                         ? const SizedBox(
//                       height: 20,
//                       width: 20,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                       ),
//                     )
//                         : const Text('Save Health Profile'),
//                   ),
//                 )),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<void> _selectDateOfBirth(
//       BuildContext context, UpdateProfileController controller) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: controller.selectedDateOfBirth.value ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
//       firstDate: DateTime(1900),
//       lastDate: DateTime.now(),
//       helpText: 'Select Date of Birth',
//     );
//
//     if (picked != null) {
//       controller.selectedDateOfBirth.value = picked;
//       controller.update();
//     }
//   }
// }