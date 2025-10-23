import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/custom_shapes/containers/primary_header_container.dart';
import '../../../../common/widgets/list_tiles/settings_menu_tile.dart';
import '../../../../common/widgets/list_tiles/user_profile_tile.dart';
import '../../../../common/widgets/texts/section_heading.dart';
import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../subscription/views/subscription_plan_selection_screen.dart';
import '../profile/profile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// -- Header
            TPrimaryHeaderContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TAppBar(
                    title: Text(
                      'Account',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium!
                          .apply(color: TColors.white),
                    ),
                  ),

                  /// -- User Profile Card
                  TUserProfileTile(
                    onPressed: () => Get.to(() => const ProfileScreen()),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                ],
              ),
            ),

            /// - Body
            Padding(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              child: Column(
                children: [
                  /// - Account Settings
                  const TSectionHeading(
                    title: 'Account Settings',
                  ),
                  const SizedBox(
                    height: TSizes.spaceBtwItems,
                  ),

                  const TSettingsMenuTile(
                    icon: Iconsax.safe_home_bold,
                    title: 'My Addresses',
                    subTitle: 'Set your address',
                  ),
                  const TSettingsMenuTile(
                    icon: Iconsax.safe_home_bold,
                    title: 'My Addresses',
                    subTitle: 'Set your address',
                  ),
                  const TSettingsMenuTile(
                    icon: Iconsax.safe_home_bold,
                    title: 'My Addresses',
                    subTitle: 'Set your address',
                  ),
                  const TSettingsMenuTile(
                    icon: Iconsax.safe_home_bold,
                    title: 'My Addresses',
                    subTitle: 'Set your address',
                  ),
                  TSettingsMenuTile(
                    icon: Iconsax.safe_home_bold,
                    title: 'Subscription',
                    subTitle: 'Subscribe the premium plan',
                    onTap: () => Get.to(() => const SubscriptionPlanScreen()),
                  ),
                  const TSettingsMenuTile(
                    icon: Iconsax.safe_home_bold,
                    title: 'Notifications',
                    subTitle: 'Set any kind of notification message',
                  ),
                  const TSettingsMenuTile(
                    icon: Iconsax.safe_home_bold,
                    title: 'Account Privacy',
                    subTitle: 'Manage data usage and connected accounts',
                  ),

                  /// - App Settings
                  const SizedBox(
                    height: TSizes.spaceBtwSections,
                  ),
                  const TSectionHeading(
                    title: 'App Settings',
                    showActionButton: false,
                  ),
                  const SizedBox(
                    height: TSizes.spaceBtwItems,
                  ),
                  const TSettingsMenuTile(
                      icon: Iconsax.document_upload_bold,
                      title: 'Load Data',
                      subTitle: 'Upload data to your cloud firebase'),
                  TSettingsMenuTile(
                      icon: Iconsax.location_bold,
                      title: 'Geolocation',
                      subTitle: 'Set recommendation based on location',
                      trailing: Switch(value: true, onChanged: (value) {})),
                  TSettingsMenuTile(
                      icon: Iconsax.security_user_bold,
                      title: 'Safe Mode',
                      subTitle: 'Search result is safe for all ages',
                      trailing: Switch(value: false, onChanged: (value) {})),
                  TSettingsMenuTile(
                      icon: Iconsax.image_bold,
                      title: 'HD Image Quality',
                      subTitle: 'Set image quality to be seen',
                      trailing: Switch(value: false, onChanged: (value) {})),

                  /// - Logout Button
                  const SizedBox(
                    height: TSizes.spaceBtwSections,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        AuthenticationRepository.instance.logout();
                      },
                      child: const Text('Logout'),
                    ),
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections * 2.5),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
