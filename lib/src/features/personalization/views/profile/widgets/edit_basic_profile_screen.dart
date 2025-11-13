// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:icons_plus/icons_plus.dart';
//
// import '../../../../../common/widgets/appbar/appbar.dart';
// import '../../../../../utils/constants/sizes.dart';
// import '../../../../../utils/validators/user_profile_validator.dart';
// import '../../../controllers/update_profile_controller.dart';
//
// class EditBasicProfileScreen extends StatelessWidget {
//   const EditBasicProfileScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.put(UpdateProfileController());
//
//     return Scaffold(
//       appBar: const TAppBar(
//         showBackArrow: true,
//         title: Text('Edit Basic Information'),
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(TSizes.defaultSpace),
//           child: Form(
//             key: controller.basicProfileFormKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 /// Instructions
//                 Text(
//                   'Update your basic profile information',
//                   style: Theme.of(context).textTheme.bodyMedium,
//                 ),
//                 const SizedBox(height: TSizes.spaceBtwSections),
//
//                 /// Username Field
//                 TextFormField(
//                   controller: controller.username,
//                   validator: TUserProfileValidator.validateUsername,
//                   decoration: const InputDecoration(
//                     labelText: 'Username',
//                     prefixIcon: Icon(Iconsax.user_bold),
//                   ),
//                   inputFormatters: [
//                     LengthLimitingTextInputFormatter(30),
//                   ],
//                 ),
//                 const SizedBox(height: TSizes.spaceBtwInputFields),
//
//                 /// Email Field (Read-only)
//                 TextFormField(
//                   controller: controller.email,
//                   enabled: false,
//                   decoration: const InputDecoration(
//                     labelText: 'Email',
//                     prefixIcon: Icon(Iconsax.sms_bold),
//                     suffixIcon: Icon(Iconsax.lock_bold),
//                   ),
//                 ),
//                 const SizedBox(height: TSizes.spaceBtwInputFields),
//
//                 /// Phone Number Field
//                 TextFormField(
//                   controller: controller.phoneNumber,
//                   validator: TUserProfileValidator.validatePhone,
//                   keyboardType: TextInputType.phone,
//                   decoration: const InputDecoration(
//                     labelText: 'Phone Number',
//                     prefixIcon: Icon(Iconsax.call_bold),
//                     hintText: '01XXXXXXXXX',
//                   ),
//                   inputFormatters: [
//                     FilteringTextInputFormatter.digitsOnly,
//                     LengthLimitingTextInputFormatter(11),
//                   ],
//                 ),
//                 const SizedBox(height: TSizes.spaceBtwSections),
//
//                 /// Save Button
//                 Obx(() => SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: controller.isBasicProfileLoading.value
//                         ? null
//                         : () => controller.updateBasicProfile(),
//                     child: controller.isBasicProfileLoading.value
//                         ? const SizedBox(
//                       height: 20,
//                       width: 20,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                       ),
//                     )
//                         : const Text('Save Changes'),
//                   ),
//                 )),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }