import 'package:diabetes_risk_prediction_and_health_management_system/src/common/loaders/loaders.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:intl/intl.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/dialogs/dialog.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../../utils/validators/user_profile_validator.dart';
import '../../../health_data_entry/views/health_data_entry/health_data_entry_screen.dart';
import '../../controllers/update_profile_controller.dart';
import '../../controllers/user_controller.dart';
import '../../models/user_profile_model.dart';
import '../profile/widgets/profile_image_section.dart';
import '../profile/widgets/profile_field_item.dart';
import '../profile/widgets/profile_section_header.dart';
import 'widgets/change_password_screen.dart';
import 'widgets/edit_single_field_screen.dart';
import 'widgets/profile_selection_dialog.dart';
import 'widgets/profile_constants.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = Get.put(UserController());
    final updateController = Get.put(UpdateProfileController());

    // 每次进入 screen 时刷新用户数据
    Future.microtask(() => userController.fetchUserRecord());

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop && updateController.hasPendingChanges.value) {
          final shouldDiscard = await TDialog.keepWriting(
            title: 'Unsaved Changes',
            message: 'You have unsaved changes. Do you want to discard them?',
          );
          if (shouldDiscard && context.mounted) {
            Get.back();
          }
        } else if (!didPop) {
          Get.back();
        }
      },
      child: Scaffold(
        appBar: TAppBar(
          showBackArrow: true,
          title: const Text('Profile'),
          customBackAction: () async {
            if (updateController.hasPendingChanges.value) {
              final shouldDiscard = await TDialog.keepWriting(
                title: 'Unsaved Changes',
                message: 'You have unsaved changes. Do you want to discard them?',
              );
              if (shouldDiscard) {
                Get.back();
              }
            } else {
              Get.back();
            }
          },
          actions: [
            Obx(() => IconButton(
              onPressed: updateController.hasPendingChanges.value
                  ? () => updateController.applyAllChanges()
                  : null,
              icon: Icon(
                Iconsax.tick_circle_bold,
                color: updateController.hasPendingChanges.value
                    ? TColors.success
                    : (THelperFunctions.isDarkMode(context)
                    ? TColors.darkGrey
                    : TColors.grey),
              ),
              tooltip: 'Save Changes',
            )),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            child: Column(
              children: [
                /// Profile Picture Section
                ProfileImageSection(),

                const SizedBox(height: TSizes.spaceBtwItems),
                const Divider(),
                const SizedBox(height: TSizes.spaceBtwItems),

                /// Basic Information Section
                ProfileSectionHeader(
                  title: 'Basic Information',
                  icon: Iconsax.user_bold,
                ),
                const SizedBox(height: TSizes.xs),

                Obx(() {
                  final user = userController.user.value;
                  final pendingChanges = updateController.pendingChanges;

                  // Get current or pending value
                  String getDisplayValue(String field, String currentValue) {
                    return pendingChanges.containsKey(field)
                        ? pendingChanges[field].toString()
                        : currentValue;
                  }

                  return Column(
                    children: [
                      ProfileFieldItem(
                        title: 'Username',
                        value: getDisplayValue('username', user.username),
                        onTap: () => _editUsername(context, updateController),
                        trailing: Icon(Iconsax.arrow_right_3_outline, size: 18),
                      ),
                      ProfileFieldItem(
                        title: 'Email',
                        value: user.email,
                        onTap: null,
                        trailing: SizedBox.shrink(),
                        maxLines: 2,
                      ),
                      ProfileFieldItem(
                        title: 'Phone Number',
                        value: pendingChanges.containsKey('phoneNumber')
                            ? TUserProfileValidator.convertToDisplayFormat(pendingChanges['phoneNumber'])
                            : (user.phoneNumber.isNotEmpty ? user.phoneNumberDisplay : 'Not set'),
                        onTap: () => _editPhoneNumber(context, updateController),
                        trailing: Icon(Iconsax.arrow_right_3_outline, size: 18),
                      ),
                      ProfileFieldItem(
                        title: 'Join Date',
                        value: DateFormat('dd/MM/yyyy').format(user.joinDate),
                        onTap: null,
                        trailing: SizedBox.shrink(),
                      ),
                    ],
                  );
                }),

                const SizedBox(height: TSizes.spaceBtwSections),

                /// Security Section
                ProfileSectionHeader(
                  title: 'Security',
                  icon: Iconsax.key_bold,
                  onActionTap: () => Get.to(() => const ChangePasswordScreen()),
                ),
                const SizedBox(height: TSizes.xs),

                ProfileFieldItem(
                  title: 'Password',
                  value: '••••••••',
                  onTap: () => Get.to(() => const ChangePasswordScreen()),
                  trailing: Icon(Iconsax.arrow_right_3_outline, size: 18),
                ),

                const SizedBox(height: TSizes.spaceBtwItems),
                const Divider(),
                const SizedBox(height: TSizes.spaceBtwItems),

                /// Health Profile Section
                ProfileSectionHeader(
                  title: 'Health Profile',
                  icon: Iconsax.health_bold,
                ),
                const SizedBox(height: TSizes.xs),

                Obx(() {
                  final profile = userController.user.value.profile;
                  final pendingChanges = updateController.pendingChanges;

                  return Column(
                    children: [
                      _buildGenderField(context, profile, updateController, pendingChanges),
                      _buildDateOfBirthField(context, profile, updateController, pendingChanges),
                      _buildWeightField(context, profile, userController),
                      _buildHeightField(context, profile, updateController, pendingChanges),
                      _buildBMIField(context, profile, pendingChanges),
                      // _buildDietPreferenceField(context, profile, updateController, pendingChanges),
                      // _buildAllergiesField(context, profile, updateController, pendingChanges),
                    ],
                  );
                }),

                const SizedBox(height: TSizes.spaceBtwItems),
                const Divider(),
                const SizedBox(height: TSizes.spaceBtwItems),

                /// Delete Account Button
                Center(
                  child: TextButton(
                    onPressed: () => userController.deleteAccountWarningPopup(),
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
      ),
    );
  }

  // === Field Builder Methods ===

  Widget _buildGenderField(
      BuildContext context,
      UserProfileModel profile,
      UpdateProfileController controller,
      Map<String, dynamic> pendingChanges,
      ) {
    String displayValue = profile.gender.isEmpty
        ? 'Not set'
        : (profile.gender == 'M' ? 'Male' : 'Female');

    if (pendingChanges.containsKey('gender')) {
      displayValue = pendingChanges['gender'] == 'M' ? 'Male' : 'Female';
    }

    return ProfileFieldItem(
      title: 'Gender',
      value: displayValue,
      onTap: () => _handleGenderEdit(profile, controller),
      trailing: profile.hasGender && profile.hasChangedGender
          ? _buildLockedBadge(context)
          : Icon(Iconsax.arrow_right_3_outline, size: 18),
      icon: profile.hasGender ? Iconsax.info_circle_outline : null,
      onInfoTap: profile.hasGender
          ? () => _showOneTimeChangeInfo(
        context,
        'Gender',
        'Gender can only be changed once after initial setup.',
      )
          : null,
    );
  }

  Widget _buildDateOfBirthField(
      BuildContext context,
      UserProfileModel profile,
      UpdateProfileController controller,
      Map<String, dynamic> pendingChanges,
      ) {
    DateTime displayDate = profile.dateOfBirth;

    if (pendingChanges.containsKey('dateOfBirth')) {
      displayDate = pendingChanges['dateOfBirth'] as DateTime;
    }

    return ProfileFieldItem(
      title: 'Date of Birth',
      value: displayDate.year != 1970
          ? DateFormat('dd/MM/yyyy').format(displayDate)
          : 'Not set',
      onTap: () => _handleDateOfBirthEdit(context, profile, controller),
      trailing: profile.hasDateOfBirth && profile.hasChangedDateOfBirth
          ? _buildLockedBadge(context)
          : Icon(Iconsax.arrow_right_3_outline, size: 18),
      icon: profile.hasDateOfBirth ? Iconsax.info_circle_outline : null,
      onInfoTap: profile.hasDateOfBirth
          ? () => _showOneTimeChangeInfo(
        context,
        'Date of Birth',
        'Date of birth can only be changed once after initial setup.',
      )
          : null,
    );
  }

  Widget _buildWeightField(BuildContext context, UserProfileModel profile, UserController userController) {
    return ProfileFieldItem(
      title: 'Weight',
      value: profile.weight > 0 ? '${profile.weight} kg' : 'Not set',
      onTap: () async {
        Get.to(() => HealthDataEntryScreen(initialSections: ['Weight & Body Fat'],));
        await userController.fetchUserRecord();
      },
      trailing: Icon(Iconsax.arrow_right_3_outline, size: 18),
    );
  }

  Widget _buildHeightField(
      BuildContext context,
      UserProfileModel profile,
      UpdateProfileController controller,
      Map<String, dynamic> pendingChanges,
      ) {
    double displayHeight = profile.height;

    if (pendingChanges.containsKey('height')) {
      displayHeight = (pendingChanges['height'] as num).toDouble();
    }

    return ProfileFieldItem(
      title: 'Height',
      value: displayHeight > 0 ? '${displayHeight} cm' : 'Not set',
      onTap: () => _editHeight(context, controller, profile.height),
      trailing: Icon(Iconsax.arrow_right_3_outline, size: 18),
    );
  }

  Widget _buildBMIField(BuildContext context, UserProfileModel profile, Map<String, dynamic> pendingChanges) {
    String bmiValue = '-';
    String bmiCategory = '';

    // Calculate BMI with pending changes if available
    double weight = profile.weight;
    double height = profile.height;

    if (pendingChanges.containsKey('height')) {
      height = (pendingChanges['height'] as num).toDouble();
    }

    if (weight > 0 && height > 0) {
      final bmi = weight / ((height / 100) * (height / 100));
      bmiValue = bmi.toStringAsFixed(1);

      // Get BMI category
      if (bmi < 18.5) {
        bmiCategory = 'Underweight';
      } else if (bmi < 25) {
        bmiCategory = 'Normal';
      } else if (bmi < 30) {
        bmiCategory = 'Overweight';
      } else {
        bmiCategory = 'Obese';
      }
    }

    return ProfileFieldItem(
      title: 'BMI',
      value: bmiValue,
      subtitle: bmiCategory.isNotEmpty ? bmiCategory : null,
      onTap: null,
      trailing: Icon(
        Iconsax.info_circle_outline,
        size: 18,
      ),
    );
  }

  // Widget _buildDietPreferenceField(
  //     BuildContext context,
  //     UserProfileModel profile,
  //     UpdateProfileController controller,
  //     Map<String, dynamic> pendingChanges,
  //     ) {
  //   String displayValue = profile.dietPreference.isNotEmpty ? profile.dietPreference : 'Not set';
  //
  //   if (pendingChanges.containsKey('dietPreference')) {
  //     displayValue = pendingChanges['dietPreference'];
  //   }
  //
  //   return ProfileFieldItem(
  //     title: 'Diet Preference',
  //     value: displayValue,
  //     onTap: () => _handleDietPreferenceEdit(profile, controller),
  //     trailing: Icon(Iconsax.arrow_right_3_outline, size: 18),
  //   );
  // }
  //
  // Widget _buildAllergiesField(
  //     BuildContext context,
  //     UserProfileModel profile,
  //     UpdateProfileController controller,
  //     Map<String, dynamic> pendingChanges,
  //     ) {
  //   List<String> displayAllergies = profile.allergies;
  //
  //   if (pendingChanges.containsKey('allergies')) {
  //     displayAllergies = List<String>.from(pendingChanges['allergies']);
  //   }
  //
  //   return ProfileFieldItem(
  //     title: 'Allergies',
  //     value: displayAllergies.isNotEmpty ? displayAllergies.join(', ') : 'None',
  //     onTap: () => _handleAllergiesEdit(profile, controller),
  //     trailing: Icon(Iconsax.arrow_right_3_outline, size: 18),
  //     maxLines: 2,
  //   );
  // }

  // === Edit Handler Methods ===

  Future<void> _handleGenderEdit(
      UserProfileModel profile,
      UpdateProfileController controller,
      ) async {
    if (profile.hasGender && profile.hasChangedGender) {
      TLoaders.errorSnackBar(
        title: 'Cannot Edit',
        message: 'Gender can only be changed once and has already been modified.',
      );
      return;
    }

    // 获取当前值（包含 pending changes）
    final currentGender = controller.getCurrentValueWithPending('gender', profile.gender);

    if (profile.hasDateOfBirth) {
      final proceed = await TDialog.confirmDialog(
        title: 'Change Gender',
        message: 'Gender can only be changed once after initial setup. '
            'Are you sure you want to change it? This action cannot be undone.',
        confirmText: 'Proceed',
        confirmButtonColor: TColors.warning,
      );

      if (proceed != true) return;
    }

    final result = await ProfileSelectionDialog.showGenderSelection(
      currentGender: currentGender,
      hasChangedBefore: profile.hasChangedGender,
    );

    if (result != null) {
      final genderCode = result == 'Male' ? 'M' : 'F';
      controller.updatePendingChange('gender', genderCode);
    }
  }

  Future<void> _handleDateOfBirthEdit(
      BuildContext context,
      UserProfileModel profile,
      UpdateProfileController controller,
      ) async {
    if (profile.hasDateOfBirth && profile.hasChangedDateOfBirth) {
      TLoaders.errorSnackBar(
        title: 'Cannot Edit',
        message: 'Date of birth can only be changed once and has already been modified.',
      );
      return;
    }

    // 获取当前值（包含 pending changes）
    DateTime currentDateOfBirth = controller.getCurrentValueWithPending('dateOfBirth', profile.dateOfBirth);

    if (profile.hasDateOfBirth) {
      final proceed = await TDialog.confirmDialog(
        title: 'Change Date of Birth',
        message: 'Date of birth can only be changed once after initial setup. '
            'Are you sure you want to change it? This action cannot be undone.',
        confirmText: 'Proceed',
        confirmButtonColor: TColors.warning,
      );

      if (proceed != true) return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDateOfBirth.year != 1970
          ? currentDateOfBirth
          : DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
    );

    if (picked != null) {
      controller.updatePendingChange('dateOfBirth', picked);
    }
  }

  // Future<void> _handleDietPreferenceEdit(
  //     UserProfileModel profile,
  //     UpdateProfileController controller,
  //     ) async {
  //   // 获取当前值（包含 pending changes）
  //   final currentDietPreference = controller.getCurrentValueWithPending('dietPreference', profile.dietPreference);
  //
  //   final result = await ProfileSelectionDialog.showSingleSelection(
  //     title: 'Diet Preference',
  //     options: ProfileConstants.dietPreferences,
  //     currentValue: currentDietPreference,
  //     icon: Iconsax.cake_bold,
  //   );
  //
  //   if (result != null) {
  //     controller.updatePendingChange('dietPreference', result);
  //   }
  // }
  //
  // Future<void> _handleAllergiesEdit(
  //     UserProfileModel profile,
  //     UpdateProfileController controller,
  //     ) async {
  //   // 获取当前值（包含 pending changes）
  //   final currentAllergies = controller.getCurrentValueWithPending('allergies', profile.allergies);
  //
  //   final result = await ProfileSelectionDialog.showMultiSelection(
  //     title: 'Allergies',
  //     options: ProfileConstants.commonAllergens,
  //     currentValues: currentAllergies,
  //     icon: Iconsax.warning_2_bold,
  //   );
  //
  //   if (result != null) {
  //     controller.updatePendingChange('allergies', result);
  //   }
  // }

  // === Helper Methods ===

  Widget _buildLockedBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: TColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: TColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.lock_bold, size: 10, color: TColors.warning),
          const SizedBox(width: 3),
          Text(
            'Locked',
            style: TextStyle(
              fontSize: 9,
              color: TColors.warning,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  void _showOneTimeChangeInfo(
      BuildContext context,
      String fieldName,
      String message,
      ) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Iconsax.info_circle_bold, color: TColors.info),
            const SizedBox(width: TSizes.sm),
            Text('$fieldName Policy'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _editUsername(BuildContext context, UpdateProfileController controller) async {
    // 获取当前值（包含 pending changes）
    final currentUsername = controller.getCurrentValueWithPending('username',
        controller.userController.user.value.username);

    final result = await Get.to<String?>(
          () => EditSingleFieldScreen(
        title: 'Username',
        fieldName: 'username',
        currentValue: currentUsername,
        validator: TUserProfileValidator.validateUsername,
        maxLength: 30,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_ ]')),
        ],
      ),
    );

    if (result != null) {
      controller.updatePendingChange('username', result);
    }
  }

  Future<void> _editPhoneNumber(BuildContext context, UpdateProfileController controller) async {
    // 获取当前值（包含 pending changes）
    final currentPhone = controller.getCurrentValueWithPending('phoneNumber',
        controller.userController.user.value.phoneNumber);

    final displayPhone = currentPhone.isNotEmpty
        ? TUserProfileValidator.convertToDisplayFormat(currentPhone)
        : '';

    final result = await Get.to<String?>(
          () => EditSingleFieldScreen(
        title: 'Phone Number',
        fieldName: 'phoneNumber',
        currentValue: displayPhone,
        keyboardType: TextInputType.phone,
        validator: TUserProfileValidator.validatePhone,
        maxLength: 11,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
      ),
    );

    if (result != null) {
      final storageFormat = TUserProfileValidator.convertToStorageFormat(result);
      controller.updatePendingChange('phoneNumber', storageFormat);
    }
  }

  Future<void> _editHeight(
      BuildContext context,
      UpdateProfileController controller,
      double currentHeight,
      ) async {
    // 获取当前值（包含 pending changes）
    final currentHeightWithPending = controller.getCurrentValueWithPending('height', currentHeight);

    final result = await Get.to<double?>(
          () => EditSingleFieldScreen(
        title: 'Height',
        fieldName: 'height',
        currentValue: currentHeightWithPending > 0 ? currentHeightWithPending.toString() : '',
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        suffix: 'cm',
        validator: (value) {
          return TUserProfileValidator.validateHeight(value);
        },
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
        ],
      ),
    );

    if (result != null) {
      controller.updatePendingChange('height', result);
    }
  }
}