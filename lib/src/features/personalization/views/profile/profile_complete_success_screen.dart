import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:confetti/confetti.dart';

import '../../../../../navigation_menu.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';

class ProfileCompleteSuccessScreen extends StatefulWidget {
  const ProfileCompleteSuccessScreen({super.key});

  @override
  State<ProfileCompleteSuccessScreen> createState() => _ProfileCompleteSuccessScreenState();
}

class _ProfileCompleteSuccessScreenState extends State<ProfileCompleteSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    // Confetti Controller
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Scale Animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Fade Animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Start animations
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _fadeController.forward();
      _confettiController.play();
    });

    // 移除了自动跳转的代码
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    Get.offAll(
          () => const NavigationMenu(),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: darkMode ? TColors.dark : TColors.light,
        body: Stack(
          children: [
            // Main Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(TSizes.defaultSpace),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Success Icon with Animation
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                TColors.success,
                                TColors.success.withOpacity(0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: TColors.success.withOpacity(0.4),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 80,
                            color: TColors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: TSizes.spaceBtwSections),

                      // Success Text with Fade Animation
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            Text(
                              'All Set! 🎉',
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: darkMode ? TColors.white : TColors.black,
                                fontSize: 36,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: TSizes.md),

                            Text(
                              'Your profile is complete',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: TColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: TSizes.spaceBtwItems),

                            Text(
                              'We\'re excited to start your health journey with you!',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: darkMode ? TColors.darkGrey : TColors.textSecondary,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: TSizes.spaceBtwSections * 1.5),

                      // Features List
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(TSizes.lg),
                          decoration: BoxDecoration(
                            color: darkMode ? TColors.darkContainer : TColors.white,
                            borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                            border: Border.all(
                              color: TColors.success.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'What\'s Next?',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: darkMode ? TColors.white : TColors.black,
                                ),
                              ),

                              const SizedBox(height: TSizes.md),

                              Divider(
                                color: darkMode ? TColors.darkerGrey : TColors.grey,
                              ),

                              const SizedBox(height: TSizes.md),

                              _buildFeatureItem(
                                Iconsax.health_bold,
                                'Track Your Health',
                                'Monitor blood glucose, pressure & more',
                                darkMode,
                              ),

                              const SizedBox(height: TSizes.md),

                              _buildFeatureItem(
                                Iconsax.chart_bold,
                                'Get Insights',
                                'Receive personalized health recommendations',
                                darkMode,
                              ),

                              const SizedBox(height: TSizes.md),

                              _buildFeatureItem(
                                Iconsax.people_bold,
                                'Join Community',
                                'Connect with others on similar journeys',
                                darkMode,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: TSizes.spaceBtwSections),

                      // Continue Button
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _navigateToHome,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                              ),
                              elevation: 2,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Get Started',
                                  style: TextStyle(
                                    color: TColors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward,
                                  color: TColors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 移除了自动跳转的提示文本
                    ],
                  ),
                ),
              ),
            ),

            // Confetti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: 3.14 / 2, // Down
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                gravity: 0.3,
                colors: const [
                  TColors.primary,
                  TColors.success,
                  TColors.warning,
                  TColors.info,
                  TColors.secondary,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
      IconData icon,
      String title,
      String subtitle,
      bool darkMode,
      ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: TColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: TColors.success,
            size: 24,
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
        Icon(
          Icons.check_circle,
          color: TColors.success,
          size: 20,
        ),
      ],
    );
  }
}