import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/images/t_circular_image.dart';
import '../../../../common/widgets/texts/section_heading.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/constants/sizes.dart';
import '../../controllers/user_controller.dart';
import 'widgets/change_password_screen.dart';
import 'widgets/edit_basic_profile_screen.dart';
import 'widgets/edit_health_profile_screen.dart';
import 'widgets/profile_menu.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UserController());

    return Scaffold(
      appBar: const TAppBar(
        showBackArrow: true,
        title: Text('Profile'),
      ),

      /// -- Body
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            children: [
              /// -- Profile Picture
              SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    Obx(() {
                      final imageUrl = controller.user.value.profileImg;
                      return TCircularImage(
                        image: imageUrl.isNotEmpty ? imageUrl : TImages.user,
                        width: 100,
                        height: 100,
                        isNetworkImage: imageUrl.isNotEmpty,
                      );
                    }),
                    TextButton(
                      onPressed: () => controller.uploadUserProfilePicture(),
                      child: const Text('Change Profile Picture'),
                    ),
                  ],
                ),
              ),

              /// -- Details
              const SizedBox(height: TSizes.spaceBtwItems / 2),
              const Divider(),
              const SizedBox(height: TSizes.spaceBtwItems),

              /// -- Heading Basic Profile Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const TSectionHeading(title: 'Basic Information', showActionButton: false),
                  IconButton(
                    onPressed: () => Get.to(() => const EditBasicProfileScreen()),
                    icon: const Icon(Iconsax.edit_2_bold, size: 20),
                    tooltip: 'Edit Basic Info',
                  ),
                ],
              ),
              const SizedBox(height: TSizes.spaceBtwItems),

              Obx(() => TProfileMenu(
                title: 'Username',
                value: controller.user.value.username,
                onTap: () => Get.to(() => const EditBasicProfileScreen()),
                icon: Iconsax.arrow_right_3_outline,
              )),
              Obx(() => TProfileMenu(
                title: 'Email',
                value: controller.user.value.email,
                onTap: () {}, // Email cannot be edited
                // icon: Icons.lock_outline,
              )),
              Obx(() => TProfileMenu(
                title: 'Phone Number',
                value: controller.user.value.phoneNumber.isNotEmpty
                    ? controller.user.value.formattedPhoneNo
                    : 'Not set',
                onTap: () => Get.to(() => const EditBasicProfileScreen()),
                icon: Iconsax.arrow_right_3_outline,
              )),
              Obx(() {
                final joinDate = controller.user.value.joinDate;
                return TProfileMenu(
                  title: 'Join Date',
                  value: '${joinDate.day}/${joinDate.month}/${joinDate.year}',
                  onTap: () {}, // Cannot be edited
                  // icon: Icons.lock_outline,
                );
              }),

              const SizedBox(height: TSizes.spaceBtwItems),

              /// -- Change Password Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const TSectionHeading(title: 'Security', showActionButton: false),
                  IconButton(
                    onPressed: () => Get.to(() => const ChangePasswordScreen()),
                    icon: const Icon(Iconsax.key_bold, size: 20),
                    tooltip: 'Change Password',
                  ),
                ],
              ),
              const SizedBox(height: TSizes.spaceBtwItems),

              TProfileMenu(
                title: 'Password',
                value: '••••••••',
                onTap: () => Get.to(() => const ChangePasswordScreen()),
                icon: Iconsax.arrow_right_3_outline,
              ),

              const SizedBox(height: TSizes.spaceBtwItems),
              const Divider(),
              const SizedBox(height: TSizes.spaceBtwItems),

              /// -- Heading Health Profile Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const TSectionHeading(title: 'Health Profile', showActionButton: false),
                  IconButton(
                    onPressed: () => Get.to(() => const EditHealthProfileScreen()),
                    icon: const Icon(Iconsax.health_bold, size: 20),
                    tooltip: 'Edit Health Profile',
                  ),
                ],
              ),
              const SizedBox(height: TSizes.spaceBtwItems),

              Obx(() {
                final profile = controller.user.value.profile;
                return Column(
                  children: [
                    TProfileMenu(
                      title: 'Gender',
                      value: profile.gender.isNotEmpty
                          ? (profile.gender == 'M' ? 'Male' : 'Female')
                          : 'Not set',
                      onTap: () => Get.to(() => const EditHealthProfileScreen()),
                      icon: Iconsax.arrow_right_3_outline,
                    ),
                    TProfileMenu(
                      title: 'Date of Birth',
                      value: profile.dateOfBirth.year != 1970
                          ? '${profile.dateOfBirth.day}/${profile.dateOfBirth.month}/${profile.dateOfBirth.year}'
                          : 'Not set',
                      onTap: () => Get.to(() => const EditHealthProfileScreen()),
                      icon: Iconsax.arrow_right_3_outline,
                    ),
                    TProfileMenu(
                      title: 'Weight',
                      value: profile.weight > 0 ? '${profile.weight} kg' : 'Not set',
                      onTap: () => Get.to(() => const EditHealthProfileScreen()),
                      icon: Iconsax.arrow_right_3_outline,
                    ),
                    TProfileMenu(
                      title: 'Height',
                      value: profile.height > 0 ? '${profile.height} cm' : 'Not set',
                      onTap: () => Get.to(() => const EditHealthProfileScreen()),
                      icon: Iconsax.arrow_right_3_outline,
                    ),
                    TProfileMenu(
                      title: 'Diet Preference',
                      value: profile.dietPreference.isNotEmpty
                          ? profile.dietPreference
                          : 'Not set',
                      onTap: () => Get.to(() => const EditHealthProfileScreen()),
                      icon: Iconsax.arrow_right_3_outline,
                    ),
                  ],
                );
              }),

              const Divider(),
              const SizedBox(height: TSizes.spaceBtwItems),

              /// -- Delete Account Button
              Center(
                child: TextButton(
                  onPressed: () => controller.deleteAccountWarningPopup(),
                  child: const Text(
                    'Delete Account',
                    style: TextStyle(color: TColors.error),
                  ),
                ),
              ),

              const SizedBox(height: TSizes.spaceBtwItems),
            ],
          ),
        ),
      ),
    );
  }
}