import 'package:get/get.dart';
import '../models/subscription_plan_model.dart';

class SubscriptionController extends GetxController {
  static SubscriptionController get instance => Get.find();

  // Observable variables
  final RxList<SubscriptionPlanModel> subscriptionPlans = <SubscriptionPlanModel>[].obs;
  final Rx<SubscriptionPlanModel> selectedPlan = SubscriptionPlanModel.empty().obs;
  final RxString selectedPaymentMethod = ''.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadSubscriptionPlans();
  }

  /// Load subscription plans (static data for now)
  void loadSubscriptionPlans() {
    try {
      isLoading.value = true;

      // Only one premium plan - Basic is free by default
      final plans = [
        SubscriptionPlanModel(
          subscriptionPlanId: 'premium_monthly',
          planName: 'Premium',
          price: 49.0,
          durationDays: 30,
          features: [
            'Generate Meal Plan',
            'Unlimited Diabetes Prediction',
            'Dedicated Why sir and what',
            'Why sir and what delicate'
          ],
          isActive: true,
        ),
      ];

      subscriptionPlans.assignAll(plans);

      // Set premium as default selected
      if (plans.isNotEmpty) {
        selectedPlan.value = plans.first; // Premium plan
      }

    } finally {
      isLoading.value = false;
    }
  }

  /// Select a subscription plan
  void selectPlan(SubscriptionPlanModel plan) {
    selectedPlan.value = plan;
  }

  /// Select payment method
  void selectPaymentMethod(String method) {
    selectedPaymentMethod.value = method;
  }

  /// Get formatted price
  String getFormattedPrice(double price) {
    return 'RM${price.toStringAsFixed(0)}';
  }

  /// Check if plan is selected
  bool isPlanSelected(SubscriptionPlanModel plan) {
    return selectedPlan.value.subscriptionPlanId == plan.subscriptionPlanId;
  }

  /// Confirm payment
  void confirmPayment() {
    if (selectedPaymentMethod.value.isNotEmpty) {
      // TODO: Process payment
      Get.snackbar('Success', 'Payment processing initiated');
    }
  }
}