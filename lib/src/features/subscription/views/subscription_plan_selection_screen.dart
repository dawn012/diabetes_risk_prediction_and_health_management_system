import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../common/widgets/appbar/appbar.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../controllers/subscription_controller.dart';
import '../models/subscription_plan_model.dart';
import '../models/user_subscription_model.dart';
import 'payment_method_selection_screen.dart';

class SubscriptionPlanScreen extends StatelessWidget {
  const SubscriptionPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SubscriptionController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: darkMode ? TColors.black : TColors.white,
      appBar: TAppBar(
        backgroundColor: TColors.primary,
        title: Text(
          'Premium',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        showBackArrow: true,
        iconTheme: IconThemeData(color: TColors.white),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: TColors.primary),
          );
        }

        // Check if user has active subscription
        final hasActiveSubscription =
            controller.activeSubscription.value != null;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Text(
                hasActiveSubscription
                    ? 'Manage Your Premium\nSubscription'
                    : 'Choose the Right Plan\nfor You',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                  color: darkMode ? TColors.white : TColors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                hasActiveSubscription
                    ? 'You are currently enjoying premium features.\nYour subscription details are shown below.'
                    : 'With lots of unique and useful features,\nyou can easily manage your diabetes\neasily without any problem.',
                style: TextStyle(
                  fontSize: 16,
                  color: darkMode ? Colors.grey[400] : Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Active Subscription Banner (if exists)
              if (hasActiveSubscription) ...[
                _buildActiveSubscriptionBanner(
                  controller.activeSubscription.value!,
                  darkMode,
                ),
                const SizedBox(height: 24),
              ],

              // Single Premium Plan
              if (controller.subscriptionPlans.isNotEmpty)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: _PlanCard(
                    plan: controller.subscriptionPlans.first,
                    isSelected: true,
                    darkMode: darkMode,
                    onTap: () {},
                  ),
                ),

              const SizedBox(height: 24),

              // Non-Refundable Notice
              _buildNonRefundableNotice(darkMode),

              const SizedBox(height: 32),

              // Check for pending subscription notice
              if (controller.hasPendingSubscription.value) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: TColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: TColors.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Iconsax.clock_bold,
                        color: TColors.warning,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pending Subscription',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: TColors.warning,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'You have a pending subscription that is being processed. Please wait for it to complete before creating a new subscription.',
                              style: TextStyle(
                                fontSize: 13,
                                color: darkMode ? Colors.grey[400] : Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Action Button
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: 56,
                child: hasActiveSubscription
                    ? OutlinedButton.icon(
                  onPressed: () => controller.showCancelSubscriptionDialog(context),
                  icon: Icon(Iconsax.close_circle_bold),
                  label: const Text('Cancel Subscription'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TColors.error,
                    side: BorderSide(color: TColors.error, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                )
                    : ElevatedButton(
                  onPressed: controller.hasPendingSubscription.value
                      ? null
                      : () => Get.to(() => const PaymentMethodScreen()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    disabledBackgroundColor: darkMode ? Colors.grey[800] : Colors.grey[300],
                    disabledForegroundColor: darkMode ? Colors.grey[600] : Colors.grey[500],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    controller.hasPendingSubscription.value
                        ? 'Processing Subscription...'
                        : 'Get the premium',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildActiveSubscriptionBanner(
      UserSubscriptionModel subscription,
      bool darkMode,
      ) {
    final daysRemaining =
        subscription.endDateTime.difference(DateTime.now()).inDays;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            TColors.success.withOpacity(0.1),
            TColors.primary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TColors.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TColors.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.crown_1_bold,
              color: TColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Premium',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkMode ? TColors.white : TColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$daysRemaining days remaining',
                  style: TextStyle(
                    fontSize: 14,
                    color: darkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Iconsax.tick_circle_bold,
            color: TColors.success,
            size: 32,
          ),
        ],
      ),
    );
  }

  Widget _buildNonRefundableNotice(bool darkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: TColors.warning.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Iconsax.info_circle_bold,
            color: TColors.warning,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Non-Refundable Purchase',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: TColors.warning,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This is a digital product. All subscription purchases are final and non-refundable once activated.',
                  style: TextStyle(
                    fontSize: 13,
                    color: darkMode ? Colors.grey[400] : Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(
      BuildContext context,
      SubscriptionController controller,
      bool darkMode,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkMode ? TColors.dark : TColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Iconsax.warning_2_bold,
              color: TColors.error,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Cancel Subscription?',
              style: TextStyle(
                color: darkMode ? TColors.white : TColors.black,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to cancel your premium subscription? You will lose access to all premium features immediately.',
          style: TextStyle(
            color: darkMode ? Colors.grey[400] : Colors.grey[700],
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Keep Premium',
              style: TextStyle(
                color: darkMode ? TColors.white : TColors.black,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _cancelSubscription(controller);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TColors.error,
              foregroundColor: TColors.white,
            ),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );
  }

  void _cancelSubscription(SubscriptionController controller) async {
    try {
      final activeSubscription = controller.activeSubscription.value;
      if (activeSubscription != null) {
        await controller.subscriptionRepo.cancelSubscription(
          activeSubscription.subscriptionId,
        );

        Get.snackbar(
          'Success',
          'Your subscription has been cancelled',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: TColors.success,
          colorText: TColors.white,
          icon: Icon(Iconsax.tick_circle_bold, color: TColors.white),
        );

        // Refresh subscription status
        await controller.refreshSubscriptionStatus();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to cancel subscription: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: TColors.error,
        colorText: TColors.white,
        icon: Icon(Iconsax.close_circle_bold, color: TColors.white),
      );
    }
  }
}

class _PlanCard extends StatefulWidget {
  final SubscriptionPlanModel plan;
  final bool isSelected;
  final bool darkMode;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.darkMode,
    required this.onTap,
  });

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) {
        _animationController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _animationController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? TColors.primary.withOpacity(0.1)
                    : (widget.darkMode ? Colors.grey[900] : Colors.grey[50]),
                border: Border.all(
                  color: widget.isSelected
                      ? TColors.primary
                      : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: widget.isSelected
                    ? [
                  BoxShadow(
                    color: TColors.primary.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
                    : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'PREMIUM PLAN',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: TColors.primary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: TColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'POPULAR',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: SubscriptionController.instance
                                      .getFormattedPrice(widget.plan.price),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: widget.darkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                TextSpan(
                                  text: ' / ${widget.plan.durationDays} days',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: widget.darkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: TColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ...widget.plan.features.map((feature) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: TColors.primary.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: TColors.primary,
                              size: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              feature,
                              style: TextStyle(
                                fontSize: 14,
                                color: widget.darkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}