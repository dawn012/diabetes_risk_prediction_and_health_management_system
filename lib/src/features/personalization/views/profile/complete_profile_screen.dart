import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../common/loaders/loaders.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../../utils/validators/user_profile_validator.dart';
import '../../../personalization/controllers/update_profile_controller.dart';
import '../../../personalization/controllers/user_controller.dart';
import 'profile_complete_success_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> with TickerProviderStateMixin {
  final controller = Get.put(UpdateProfileController());
  final userController = Get.put(UserController());
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _heightController = TextEditingController();

  // Selected values
  String? _selectedGender;
  DateTime? _selectedDateOfBirth;

  // Current step (-1: welcome, 0: gender, 1: DOB, 2: height)
  int _currentStep = -1;

  // Error messages
  String? _genderError;
  String? _dobError;

  // Animations
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Slide animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _animateToNextStep() {
    setState(() {
      _slideController.reset();
      _fadeController.reset();
      _currentStep++;
    });
    _slideController.forward();
    _fadeController.forward();
  }

  void _animateToPreviousStep() {
    setState(() {
      _slideController.reset();
      _fadeController.reset();
      _currentStep--;
    });
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: darkMode ? TColors.dark : TColors.light,
        body: SafeArea(
          child: Column(
            children: [
              // Progress Indicator (only show after welcome screen)
              if (_currentStep >= 0) _buildProgressIndicator(darkMode),

              // Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildStepContent(darkMode),
                  ),
                ),
              ),

              // Bottom Buttons
              _buildBottomButtons(darkMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(bool darkMode) {
    return Container(
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: darkMode ? TColors.black : TColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(3, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted || isCurrent
                          ? TColors.primary
                          : (darkMode ? TColors.darkerGrey : TColors.grey),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < 2) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(bool darkMode) {
    switch (_currentStep) {
      case -1:
        return _buildWelcomeScreen(darkMode);
      case 0:
        return _buildGenderStep(darkMode);
      case 1:
        return _buildDateOfBirthStep(darkMode);
      case 2:
        return _buildHeightStep(darkMode);
      default:
        return const SizedBox();
    }
  }

  Widget _buildWelcomeScreen(bool darkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Animated Wave Icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        TColors.primary,
                        TColors.primary.withOpacity(0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: TColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.waving_hand,
                    size: 80,
                    color: TColors.white,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: TSizes.spaceBtwSections),

          // Welcome Text
          Obx(() {
            final username = userController.user.value.username;
            return Text(
              'Hi, ${username.isEmpty ? 'there' : username}! 👋',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: darkMode ? TColors.white : TColors.black,
                fontSize: 32,
              ),
              textAlign: TextAlign.center,
            );
          }),

          const SizedBox(height: TSizes.md),

          Text(
            'Welcome to your health journey!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: TColors.primary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: TSizes.spaceBtwSections),

          // Info Card
          Container(
            padding: const EdgeInsets.all(TSizes.lg),
            decoration: BoxDecoration(
              color: darkMode ? TColors.darkContainer : TColors.white,
              borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
              border: Border.all(
                color: TColors.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Before we start...',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: darkMode ? TColors.white : TColors.black,
                  ),
                ),

                const SizedBox(height: TSizes.md),

                Text(
                  'We need to collect some basic information to personalize your health recommendations and provide accurate health insights.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: darkMode ? TColors.darkGrey : TColors.textSecondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: TSizes.spaceBtwItems),

                Divider(
                  color: darkMode ? TColors.darkerGrey : TColors.grey,
                ),

                const SizedBox(height: TSizes.spaceBtwItems),

                _buildInfoItem(
                  Iconsax.profile_2user_bold,
                  'Your Gender',
                  'Helps personalize recommendations',
                  darkMode,
                ),

                const SizedBox(height: TSizes.md),

                _buildInfoItem(
                  Iconsax.calendar_bold,
                  'Date of Birth',
                  'Calculates your age for better insights',
                  darkMode,
                ),

                const SizedBox(height: TSizes.md),

                _buildInfoItem(
                  Iconsax.ruler_bold,
                  'Your Height',
                  'Essential for BMI and health tracking',
                  darkMode,
                ),
              ],
            ),
          ),

          const SizedBox(height: TSizes.spaceBtwSections),

          // Privacy Note
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.shield_tick_bold,
                size: 16,
                color: TColors.success,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Your data is secure and private',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: TColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String subtitle, bool darkMode) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: TColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: TColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: TSizes.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: darkMode ? TColors.white : TColors.black,
                ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: darkMode ? TColors.darkGrey : TColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenderStep(bool darkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Icon
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: TColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Iconsax.profile_2user_bold,
                      size: 64,
                      color: TColors.primary,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: TSizes.spaceBtwSections),

          // Title & Subtitle
          Text(
            'What\'s your gender?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: darkMode ? TColors.white : TColors.black,
            ),
          ),
          const SizedBox(height: TSizes.sm),
          Text(
            'Help us personalize your health recommendations',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: darkMode ? TColors.darkGrey : TColors.textSecondary,
            ),
          ),

          const SizedBox(height: TSizes.spaceBtwSections),

          // Gender Options
          _buildGenderOption('Male', 'M', Iconsax.man_bold, darkMode),
          const SizedBox(height: TSizes.md),
          _buildGenderOption('Female', 'F', Iconsax.woman_bold, darkMode),

          // Error Message
          if (_genderError != null) ...[
            const SizedBox(height: TSizes.md),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(TSizes.md),
              decoration: BoxDecoration(
                color: TColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                border: Border.all(
                  color: TColors.error.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Iconsax.info_circle_bold,
                    color: TColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: TSizes.sm),
                  Expanded(
                    child: Text(
                      _genderError!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: TColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGenderOption(String label, String value, IconData icon, bool darkMode) {
    final isSelected = _selectedGender == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedGender = value;
          _genderError = null; // Clear error when selection is made
        });
      },
      borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(TSizes.lg),
        decoration: BoxDecoration(
          color: isSelected
              ? TColors.primary.withOpacity(0.1)
              : (darkMode ? TColors.darkContainer : TColors.white),
          border: Border.all(
            color: isSelected
                ? TColors.primary
                : (darkMode ? TColors.darkerGrey : TColors.grey),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? TColors.primary
                    : (darkMode ? TColors.darkerGrey : TColors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? TColors.white
                    : (darkMode ? TColors.darkGrey : TColors.textSecondary),
                size: 28,
              ),
            ),
            const SizedBox(width: TSizes.md),
            Text(
              label,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? TColors.primary
                    : (darkMode ? TColors.white : TColors.black),
              ),
            ),
            const Spacer(),
            if (isSelected)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 300),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: TColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: TColors.white,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateOfBirthStep(bool darkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Icon
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: TColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Iconsax.calendar_bold,
                      size: 64,
                      color: TColors.primary,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: TSizes.spaceBtwSections),

          // Title & Subtitle
          Text(
            'When were you born?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: darkMode ? TColors.white : TColors.black,
            ),
          ),
          const SizedBox(height: TSizes.sm),
          Text(
            'We use this to calculate your age and provide better health insights',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: darkMode ? TColors.darkGrey : TColors.textSecondary,
            ),
          ),

          const SizedBox(height: TSizes.spaceBtwSections),

          // Date Picker
          InkWell(
            onTap: () => _selectDateOfBirth(context),
            borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(TSizes.lg),
              decoration: BoxDecoration(
                color: darkMode ? TColors.darkContainer : TColors.white,
                border: Border.all(
                  color: _dobError != null
                      ? TColors.error
                      : (_selectedDateOfBirth != null
                      ? TColors.primary
                      : (darkMode ? TColors.darkerGrey : TColors.grey)),
                  width: _selectedDateOfBirth != null || _dobError != null ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _selectedDateOfBirth != null
                          ? TColors.primary.withOpacity(0.1)
                          : (darkMode ? TColors.darkerGrey : TColors.grey.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Iconsax.calendar_bold,
                      color: _selectedDateOfBirth != null
                          ? TColors.primary
                          : (darkMode ? TColors.darkGrey : TColors.textSecondary),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: TSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date of Birth',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: darkMode ? TColors.darkGrey : TColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedDateOfBirth != null
                              ? THelperFunctions.getFormattedDate(_selectedDateOfBirth!, format: 'dd MMM yyyy')
                              : 'Select your birth date',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: _selectedDateOfBirth != null ? FontWeight.w600 : FontWeight.normal,
                            color: _selectedDateOfBirth != null
                                ? (darkMode ? TColors.white : TColors.black)
                                : (darkMode ? TColors.darkGrey : TColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Iconsax.arrow_right_3_bold,
                    color: darkMode ? TColors.darkGrey : TColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Error Message
          if (_dobError != null) ...[
            const SizedBox(height: TSizes.md),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(TSizes.md),
              decoration: BoxDecoration(
                color: TColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                border: Border.all(
                  color: TColors.error.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Iconsax.info_circle_bold,
                    color: TColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: TSizes.sm),
                  Expanded(
                    child: Text(
                      _dobError!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: TColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeightStep(bool darkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Icon
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: TColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Iconsax.ruler_bold,
                        size: 64,
                        color: TColors.primary,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Title & Subtitle
            Text(
              'What\'s your height?',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: darkMode ? TColors.white : TColors.black,
              ),
            ),
            const SizedBox(height: TSizes.sm),
            Text(
              'Your height helps us calculate your BMI and track your health',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: darkMode ? TColors.darkGrey : TColors.textSecondary,
              ),
            ),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Height Input
            TextFormField(
              controller: _heightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                color: darkMode ? TColors.white : TColors.black,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                labelText: 'Height',
                hintText: 'Enter your height',
                prefixIcon: const Icon(
                  Iconsax.ruler_bold,
                  color: TColors.primary,
                ),
                suffixText: 'cm',
                suffixStyle: TextStyle(
                  color: darkMode ? TColors.darkGrey : TColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: darkMode ? TColors.darkContainer : TColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                  borderSide: BorderSide(
                    color: darkMode ? TColors.darkerGrey : TColors.grey,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                  borderSide: BorderSide(
                    color: darkMode ? TColors.darkerGrey : TColors.grey,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                  borderSide: const BorderSide(
                    color: TColors.primary,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                  borderSide: const BorderSide(
                    color: TColors.error,
                    width: 2,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                  borderSide: const BorderSide(
                    color: TColors.error,
                    width: 2,
                  ),
                ),
                errorStyle: const TextStyle(
                  color: TColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              validator: TUserProfileValidator.validateHeight,
            ),

            const SizedBox(height: TSizes.md),

            // Height Info Card
            Container(
              padding: const EdgeInsets.all(TSizes.md),
              decoration: BoxDecoration(
                color: TColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                border: Border.all(
                  color: TColors.info.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Iconsax.info_circle_bold,
                    color: TColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: TSizes.sm),
                  Expanded(
                    child: Text(
                      'Your height will be used to calculate your BMI and provide personalized health recommendations.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: darkMode ? TColors.white : TColors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons(bool darkMode) {
    return Container(
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: darkMode ? TColors.black : TColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _animateToPreviousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                    color: darkMode ? TColors.darkerGrey : TColors.grey,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                  ),
                ),
                child: Text(
                  'Back',
                  style: TextStyle(
                    color: darkMode ? TColors.white : TColors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: TSizes.md),
          Expanded(
            flex: _currentStep == -1 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentStep == -1 ? 'Let\'s Start' : (_currentStep == 2 ? 'Complete' : 'Continue'),
                    style: const TextStyle(
                      color: TColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward,
                    color: TColors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNext() async {
    // Clear previous errors
    setState(() {
      _genderError = null;
      _dobError = null;
    });

    // Validate current step
    if (!_validateCurrentStep()) {
      return;
    }

    if (_currentStep < 2) {
      // Move to next step with animation
      _animateToNextStep();
    } else {
      // Complete profile
      await _completeProfile();
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case -1:
      // Welcome screen, just proceed
        return true;
      case 0:
      // Gender validation
        if (_selectedGender == null) {
          setState(() {
            _genderError = 'Please select your gender to continue';
          });
          return false;
        }
        return true;
      case 1:
      // Date of birth validation
        if (_selectedDateOfBirth == null) {
          setState(() {
            _dobError = 'Please select your date of birth to continue';
          });
          return false;
        }

        // Validate age
        final validationError = TUserProfileValidator.validateDateOfBirth(_selectedDateOfBirth);
        if (validationError != null) {
          setState(() {
            _dobError = validationError;
          });
          return false;
        }
        return true;
      case 2:
      // Height validation
        if (!_formKey.currentState!.validate()) {
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _completeProfile() async {
    try {
      // Show loading state
      setState(() {
        // You can add a loading indicator here if needed
      });

      // Update pending changes in controller
      controller.updatePendingChange('gender', _selectedGender!);
      controller.updatePendingChange('dateOfBirth', _selectedDateOfBirth!);
      controller.updatePendingChange('height', double.parse(_heightController.text.trim()));

      // Apply all changes
      await controller.applyAllChanges();

      // Navigate to main app (this will be handled by AuthenticationRepository.screenRedirect())
      // The success message is already shown in applyAllChanges()
      Get.to(() => ProfileCompleteSuccessScreen());
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Error',
          message: 'Failed to complete profile. Please try again.');
    }
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final now = DateTime.now();
    final minDate = DateTime(now.year - 120, now.month, now.day); // 120 years ago
    final maxDate = DateTime(now.year - 13, now.month, now.day); // 13 years ago

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? maxDate,
      firstDate: minDate,
      lastDate: maxDate,
      helpText: 'Select your date of birth',
      cancelText: 'Cancel',
      confirmText: 'Confirm',
      builder: (context, child) {
        final darkMode = THelperFunctions.isDarkMode(context);
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: TColors.primary,
              onPrimary: TColors.white,
              surface: darkMode ? TColors.darkContainer : TColors.white,
              onSurface: darkMode ? TColors.white : TColors.black,
            ),
            dialogBackgroundColor: darkMode ? TColors.darkContainer : TColors.white,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDateOfBirth = pickedDate;
        _dobError = null; // Clear error when date is selected
      });
    }
  }
}