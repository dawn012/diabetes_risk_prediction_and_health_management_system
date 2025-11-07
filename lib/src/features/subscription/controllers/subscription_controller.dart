import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../common/loaders/loaders.dart';
import '../../../common/widgets/dialogs/dialog.dart';
import '../../../data/repositories/subscription/subscription_repository.dart';
import '../../../utils/constants/enums.dart';
import '../models/subscription_plan_model.dart';
import '../models/user_subscription_model.dart';

class SubscriptionController extends GetxController {
  static SubscriptionController get instance => Get.find();

  final subscriptionRepo = Get.put(SubscriptionRepository());

  final RxList<SubscriptionPlanModel> subscriptionPlans = <SubscriptionPlanModel>[].obs;
  final Rx<SubscriptionPlanModel> selectedPlan = SubscriptionPlanModel.empty().obs;
  final RxString selectedPaymentMethod = ''.obs;
  final RxBool isLoading = false.obs;
  final Rx<UserSubscriptionModel?> activeSubscription = Rx<UserSubscriptionModel?>(null);
  final RxBool hasPendingSubscription = false.obs;
  final RxBool autoRenew = false.obs;

  // API endpoints
  static const String baseUrl = 'https://subscriptionapi-qza3iocmaq-uc.a.run.app';

  // Stripe endpoints
  static const String cancelSubscriptionUrl = '$baseUrl/cancelSubscription';
  static const String toggleAutoRenewUrl = '$baseUrl/toggleAutoRenew';
  static const String cancelAtPeriodEndUrl = '$baseUrl/cancelSubscriptionAtPeriodEnd';
  static const String resumeSubscriptionUrl = '$baseUrl/resumeSubscription';

  // PayPal endpoints
  static const String cancelPayPalSubscriptionUrl = '$baseUrl/cancelPayPalSubscription';

  StreamSubscription? _activeSubscriptionStream;

  @override
  void onInit() {
    super.onInit();
    loadSubscriptionPlans();
    _startListeningToActiveSubscription();
    _checkPendingSubscription();
  }

  @override
  void onClose() {
    _activeSubscriptionStream?.cancel();
    super.onClose();
  }

  /// Start listening to active subscription changes
  void _startListeningToActiveSubscription() {
    _activeSubscriptionStream = subscriptionRepo
        .streamActiveSubscription()
        .listen((subscription) {
      activeSubscription.value = subscription;
      autoRenew.value = subscription?.autoRenew ?? false;
      print('Active subscription updated: ${subscription?.subscriptionId}');
    }, onError: (error) {
      print('Error streaming active subscription: $error');
    });
  }

  /// Load subscription plans
  Future<void> loadSubscriptionPlans() async {
    try {
      isLoading.value = true;
      final plans = await subscriptionRepo.getAllPlans();
      final activePlans = plans.where((plan) => plan.isActive).toList();
      subscriptionPlans.assignAll(activePlans);

      if (activePlans.isNotEmpty) {
        selectedPlan.value = activePlans.first;
      }
    } catch (e) {
      print('Error loading subscription plans: $e');
      Get.snackbar('Error', 'Failed to load subscription plans: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load active subscription
  Future<void> loadActiveSubscription() async {
    try {
      final userId = subscriptionRepo.authUser?.uid;
      if (userId == null) return;

      final subscription = await subscriptionRepo.getActiveSubscription(userId);
      activeSubscription.value = subscription;
      autoRenew.value = subscription?.autoRenew ?? false;
    } catch (e) {
      print('Error loading active subscription: $e');
    }
  }

  /// Toggle auto-renew (处理不同支付方式)
  Future<void> toggleAutoRenew() async {
    if (activeSubscription.value == null) return;

    try {
      final newAutoRenew = !autoRenew.value;
      final subscription = activeSubscription.value!;

      await _toggleAutoRenew(subscription.subscriptionId, newAutoRenew);

      // 乐观更新 UI
      autoRenew.value = newAutoRenew;

      TLoaders.modernSnackBar(
        title: newAutoRenew ? 'Auto-Renew Enabled' : 'Auto-Renew Disabled',
        message: newAutoRenew
            ? 'Your subscription will automatically renew at the end of the billing cycle.'
            : 'Your subscription will be cancelled before the next billing cycle.',
      );

    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to toggle auto-renew: $e',
      );
      throw e;
    }
  }

  /// Toggle Stripe auto-renew (调用 API)
  // Future<void> _toggleStripeAutoRenew(String subscriptionId, bool newAutoRenew) async {
  //   final success = await _callSubscriptionApi(
  //     url: toggleAutoRenewUrl,
  //     subscriptionId: subscriptionId,
  //     additionalData: {'autoRenew': newAutoRenew},
  //   );
  //
  //   if (!success) {
  //     throw Exception('Failed to toggle Stripe auto-renew');
  //   }
  // }

  /// Toggle auto-renew (只更新 Firestore)
  Future<void> _toggleAutoRenew(String subscriptionId, bool newAutoRenew) async {
    try {
      // 只更新 Firestore，不调用 API
      await subscriptionRepo.updateAutoRenew(subscriptionId, newAutoRenew);
      print('Auto-renew updated in Firestore: $subscriptionId -> $newAutoRenew');
    } catch (e) {
      print('Error toggling auto-renew: $e');
      throw Exception('Failed to update auto-renew setting: $e');
    }
  }

  /// Cancel subscription (处理不同支付方式)
  Future<void> cancelSubscriptionImmediately() async {
    if (activeSubscription.value == null) return;

    try {
      isLoading.value = true;
      final subscription = activeSubscription.value!;
      final isPayPal = subscription.subscriptionId.startsWith('I-');

      if (isPayPal) {
        await _cancelPayPalSubscription(subscription.subscriptionId);
      } else {
        await _cancelStripeSubscription(subscription.subscriptionId);
      }

      TLoaders.successSnackBar(
        title: 'Subscription Cancelled',
        message: 'Your subscription has been cancelled immediately',
      );

    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to cancel subscription: $e',
      );
      throw e;
    } finally {
      isLoading.value = false;
    }
  }

  /// Cancel Stripe subscription
  Future<void> _cancelStripeSubscription(String subscriptionId) async {
    final success = await _callSubscriptionApi(
      url: cancelSubscriptionUrl,
      subscriptionId: subscriptionId,
    );

    if (!success) {
      throw Exception('Failed to cancel Stripe subscription');
    }

    // 等待 webhook 更新 Firestore
    await _waitForSubscriptionStatusUpdate(subscriptionId, SubscriptionStatus.cancelled);
  }

  /// Cancel PayPal subscription
  Future<void> _cancelPayPalSubscription(String subscriptionId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final idToken = await user.getIdToken();

      final response = await http.post(
        Uri.parse(cancelPayPalSubscriptionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({
          'subscriptionId': subscriptionId,
          'reason': 'User requested cancellation',
        }),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to cancel PayPal subscription');
      }

      print('PayPal subscription cancelled: $subscriptionId');

      // 等待 webhook 更新 Firestore
      await _waitForSubscriptionStatusUpdate(subscriptionId, SubscriptionStatus.cancelled);
    } catch (e) {
      print('Error cancelling PayPal subscription: $e');
      throw e;
    }
  }

  /// Wait for subscription status to be updated by webhook
  Future<void> _waitForSubscriptionStatusUpdate(
      String subscriptionId,
      SubscriptionStatus expectedStatus,
      ) async {
    const maxWaitTime = 30; // 最大等待30秒
    const interval = Duration(seconds: 1);

    for (int i = 0; i < maxWaitTime; i++) {
      await Future.delayed(interval);

      final subscription = await subscriptionRepo.getSubscriptionById(subscriptionId);

      if (subscription != null && subscription.status == expectedStatus) {
        print('Subscription status updated to $expectedStatus');
        return;
      }

      print('Waiting for webhook update... ($i/$maxWaitTime)');
    }

    // 如果超时，抛出异常或继续
    print('Timeout waiting for webhook update');
    throw Exception('Subscription status update timeout');
  }

  /// Cancel subscription at period end (仅 Stripe)
  Future<void> cancelSubscriptionAtPeriodEnd() async {
    if (activeSubscription.value == null) return;

    final subscription = activeSubscription.value!;
    final isPayPal = subscription.subscriptionId.startsWith('I-');

    if (isPayPal) {
      // PayPal 没有 "cancel at period end"，直接设置 autoRenew 为 false
      await _toggleAutoRenew(subscription.subscriptionId, false);
      return;
    }

    try {
      isLoading.value = true;

      final success = await _callSubscriptionApi(
        url: cancelAtPeriodEndUrl,
        subscriptionId: subscription.subscriptionId,
      );

      if (success) {
        TLoaders.successSnackBar(
          title: 'Subscription Scheduled to Cancel',
          message: 'Your subscription will cancel at the end of the billing period',
        );
      } else {
        throw Exception('Failed to schedule subscription cancellation');
      }

    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to schedule subscription cancellation: $e',
      );
      throw e;
    } finally {
      isLoading.value = false;
    }
  }

  /// Resume subscription (仅 Stripe)
  Future<void> resumeSubscription() async {
    if (activeSubscription.value == null) return;

    final subscription = activeSubscription.value!;
    final isPayPal = subscription.subscriptionId.startsWith('I-');

    if (isPayPal) {
      // PayPal: 重新启用 autoRenew
      await _toggleAutoRenew(subscription.subscriptionId, true);
      TLoaders.successSnackBar(
        title: 'Subscription Resumed',
        message: 'Your subscription will continue automatically',
      );
      return;
    }

    try {
      isLoading.value = true;

      final success = await _callSubscriptionApi(
        url: resumeSubscriptionUrl,
        subscriptionId: subscription.subscriptionId,
      );

      if (success) {
        TLoaders.successSnackBar(
          title: 'Subscription Resumed',
          message: 'Your subscription has been resumed',
        );
      } else {
        throw Exception('Failed to resume subscription');
      }

    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to resume subscription: $e',
      );
      throw e;
    } finally {
      isLoading.value = false;
    }
  }

  /// Show cancel subscription dialog
  void showCancelSubscriptionDialog(BuildContext context) {
    if (activeSubscription.value == null) return;

    TDialog.deleteDialog(
      title: 'Cancel Subscription',
      message: 'Are you sure you want to cancel your subscription? This action cannot be undone.',
      onConfirm: () => _handleCancelSubscription(),
      buttonTitle: 'Confirm'
    );
  }

  /// Handle cancel subscription after confirmation
  Future<void> _handleCancelSubscription() async {
    try {
      await cancelSubscriptionImmediately();
    } catch (e) {
      // Error handling is already done in cancelSubscriptionImmediately
    }
  }

  /// Generic API call method
  Future<bool> _callSubscriptionApi({
    required String url,
    required String subscriptionId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final idToken = await user.getIdToken();

      final body = {
        'subscriptionId': subscriptionId,
        if (additionalData != null) ...additionalData,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result['success'] == true;
      } else {
        print('API call error ($url): ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error calling API ($url): $e');
      return false;
    }
  }

  /// Check if user has active subscription
  Future<bool> hasActiveSubscription() async {
    try {
      final userId = subscriptionRepo.authUser?.uid;
      if (userId == null) return false;

      return await subscriptionRepo.hasActiveSubscription(userId);
    } catch (e) {
      print('Error checking active subscription: $e');
      return false;
    }
  }

  /// Check if user has pending subscription
  Future<void> _checkPendingSubscription() async {
    try {
      final userId = subscriptionRepo.authUser?.uid;
      if (userId == null) {
        hasPendingSubscription.value = false;
        return;
      }

      final hasPending = await subscriptionRepo.hasPendingSubscription(userId);
      hasPendingSubscription.value = hasPending;

    } catch (e) {
      print('Error checking pending subscription: $e');
      hasPendingSubscription.value = false;
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

  /// Refresh subscription status
  Future<void> refreshSubscriptionStatus() async {
    await loadActiveSubscription();
  }

  /// Get days remaining for active subscription
  int getDaysRemaining() {
    if (activeSubscription.value == null) return 0;
    final remaining = activeSubscription.value!.endDateTime
        .difference(DateTime.now())
        .inDays;
    return remaining > 0 ? remaining : 0;
  }

  /// Check if subscription is about to expire
  bool isExpiringSoon() {
    return getDaysRemaining() > 0 && getDaysRemaining() < 7;
  }

  /// Check if subscription is PayPal
  bool isPayPalSubscription() {
    if (activeSubscription.value == null) return false;
    return activeSubscription.value!.subscriptionId.startsWith('I-');
  }

  /// Check if subscription is Stripe
  bool isStripeSubscription() {
    if (activeSubscription.value == null) return false;
    return activeSubscription.value!.subscriptionId.startsWith('sub_');
  }
}