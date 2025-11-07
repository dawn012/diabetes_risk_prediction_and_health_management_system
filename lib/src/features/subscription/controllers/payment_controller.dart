import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/subscription/subscription_repository.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/helpers/export_helper.dart';
import '../models/payment_transaction_model.dart';
import '../models/subscription_plan_model.dart';
import '../models/user_subscription_model.dart';
import '../views/subscription_success_screen.dart';

class PaymentController extends GetxController {
  static PaymentController get instance => Get.find();
  final subscriptionRepo = Get.put(SubscriptionRepository());

  // Platform channel for PayPal Native SDK
  static const platform = MethodChannel('com.diatrack/paypal');

  // Observable variables
  final RxString selectedPaymentMethod = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isProcessingPayment = false.obs;

  // Payment status tracking
  final RxString paymentStatus = ''.obs;
  final RxString currentPaymentIntentId = ''.obs;
  final RxString currentPayPalSubscriptionId = ''.obs;
  final RxString currentStripeSubscriptionId = ''.obs;

  static const String baseUrl = 'https://subscriptionapi-qza3iocmaq-uc.a.run.app';
  static const String createSubscriptionUrl = '$baseUrl/createSubscription';
  static const String verifySubscriptionUrl = '$baseUrl/verifySubscription';
  static const String createPayPalSubscriptionUrl = '$baseUrl/createPayPalSubscription';
  static const String verifyPayPalSubscriptionUrl = '$baseUrl/verifyPayPalSubscription';

  @override
  void onInit() {
    super.onInit();
    _setupPayPalMethodCallHandler();
  }

  /// Setup method call handler for PayPal callbacks
  void _setupPayPalMethodCallHandler() {
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onPayPalSuccess':
          final subscriptionId = call.arguments['subscriptionId'] as String?;
          if (subscriptionId != null) {
            await _handlePayPalSuccess(subscriptionId);
          }
          break;
        case 'onPayPalError':
          final error = call.arguments['error'] as String?;
          _handlePaymentError('PayPal error: ${error ?? "Unknown error"}');
          break;
        case 'onPayPalCancel':
          _handlePayPalCancel();
          break;
      }
    });
  }

  /// Handle PayPal success callback from native SDK
  Future<void> _handlePayPalSuccess(String subscriptionId) async {
    try {
      paymentStatus.value = 'Processing PayPal subscription...';
      isProcessingPayment.value = true;

      // 验证 PayPal subscription 状态
      final verifyResult = await _verifyPayPalSubscription(subscriptionId);

      if (verifyResult == null || verifyResult['status'] != 'ACTIVE') {
        throw Exception('PayPal subscription verification failed');
      }

      // 等待 webhook 处理
      await _waitForPayPalWebhookUpdate(subscriptionId);

    } catch (e) {
      _handlePaymentError('PayPal callback error: $e');
    } finally {
      isProcessingPayment.value = false;
    }
  }

  /// Handle PayPal cancel
  void _handlePayPalCancel() {
    paymentStatus.value = 'PayPal payment cancelled';
    isProcessingPayment.value = false;

    TLoaders.warningSnackBar(
      title: 'Payment Cancelled',
      message: 'You have cancelled the PayPal payment',
    );

    // 删除 pending subscription
    if (currentPayPalSubscriptionId.value.isNotEmpty) {
      _deletePendingSubscription(currentPayPalSubscriptionId.value);
    }
  }

  /// Verify PayPal subscription
  Future<Map<String, dynamic>?> _verifyPayPalSubscription(String subscriptionId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final idToken = await user.getIdToken();

      final response = await http.post(
        Uri.parse(verifyPayPalSubscriptionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({'subscriptionId': subscriptionId}),
      );

      print('PayPal verify response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('PayPal verification failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error verifying PayPal subscription: $e');
      return null;
    }
  }

  /// Wait for PayPal webhook to update subscription
  Future<void> _waitForPayPalWebhookUpdate(String subscriptionId) async {
    try {
      paymentStatus.value = 'Waiting for confirmation...';

      for (int i = 0; i < 10; i++) {
        await Future.delayed(Duration(seconds: 1));

        final subscription = await subscriptionRepo.getSubscriptionById(subscriptionId);

        if (subscription != null && subscription.status == SubscriptionStatus.active) {
          paymentStatus.value = 'Subscription activated!';

          TLoaders.successSnackBar(
            title: 'Subscription Activated',
            message: 'Your PayPal subscription has been activated!',
          );

          Get.offAll(() => SubscriptionSuccessScreen(), arguments: subscription);
          return;
        }
      }

      TLoaders.modernSnackBar(
        title: 'Processing',
        message: 'Your subscription is being processed. Please check your subscriptions.',
      );

      Get.back();
    } catch (e) {
      print('Error waiting for webhook update: $e');
      throw e;
    }
  }

  /// Select payment method
  void selectPaymentMethod(String method) {
    selectedPaymentMethod.value = method;
  }

  /// Confirm subscription payment
  Future<void> confirmSubscriptionPayment(SubscriptionPlanModel plan) async {
    if (selectedPaymentMethod.value.isEmpty) {
      TLoaders.errorSnackBar(title: 'Error', message: 'Please select a payment method');
      return;
    }

    switch (selectedPaymentMethod.value) {
      case 'stripe':
        await _processStripeSubscriptionPayment(plan);
        break;
      case 'paypal':
        await _processPayPalSubscriptionPayment(plan);
        break;
      default:
        TLoaders.errorSnackBar(title: 'Error', message: 'Invalid payment method selected');
    }
  }

  /// Process Stripe Subscription Payment
  Future<void> _processStripeSubscriptionPayment(SubscriptionPlanModel plan) async {
    try {
      isProcessingPayment.value = true;
      paymentStatus.value = 'Creating subscription...';

      final subscriptionData = await _createStripeSubscription(plan);

      if (subscriptionData == null) {
        throw Exception('Failed to create subscription');
      }

      print("Subscription Data: $subscriptionData");
      currentStripeSubscriptionId.value = subscriptionData['subscriptionId'];
      currentPaymentIntentId.value = subscriptionData['client_secret'];

      paymentStatus.value = 'Creating subscription record...';
      await _createPendingSubscription(
        subscriptionId: currentStripeSubscriptionId.value,
        plan: plan,
        isStripe: true,
      );

      paymentStatus.value = 'Initializing payment sheet...';
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: subscriptionData['client_secret'],
          merchantDisplayName: 'Diatrack',
          customerId: subscriptionData['customer_id'],
          customerEphemeralKeySecret: subscriptionData['ephemeral_key'],
          style: ThemeMode.system,
          billingDetails: const BillingDetails(
            address: Address(
              country: 'MY',
              city: '',
              line1: '',
              line2: '',
              postalCode: '',
              state: '',
            ),
          ),
          googlePay: const PaymentSheetGooglePay(
            merchantCountryCode: 'MY',
            currencyCode: 'MYR',
            testEnv: true,
          ),
        ),
      );

      paymentStatus.value = 'Presenting payment sheet...';
      await Stripe.instance.presentPaymentSheet();

      paymentStatus.value = 'Verifying payment...';
      await _verifySubscriptionPaymentStatus(
        currentStripeSubscriptionId.value,
        plan,
      );
    } catch (e) {
      if (e.toString().contains('canceled') || e.toString().contains('cancelled')) {
        paymentStatus.value = 'Payment cancelled by user';
        TLoaders.warningSnackBar(
          title: 'Payment Cancelled',
          message: 'You have cancelled the payment process',
        );
        await _deletePendingSubscription(currentStripeSubscriptionId.value);
      } else {
        _handlePaymentError(e.toString());
        // await _updateSubscriptionStatusToFailed(currentStripeSubscriptionId.value);
      }
    } finally {
      isProcessingPayment.value = false;
    }
  }

  /// Create pending subscription record in Firestore
  Future<void> _createPendingSubscription({
    required String subscriptionId,
    required SubscriptionPlanModel plan,
    required bool isStripe,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final existingSubscription = await subscriptionRepo.getSubscriptionById(subscriptionId);
      if (existingSubscription != null) {
        print('Subscription record already exists: $subscriptionId');
        return;
      }

      final now = DateTime.now();
      final endDate = now.add(Duration(days: plan.durationDays));

      final subscription = UserSubscriptionModel(
        subscriptionId: subscriptionId,
        userId: user.uid,
        subscriptionPlan: plan,
        paymentTransactions: [PaymentTransactionModel.empty()],
        startDateTime: now,
        endDateTime: endDate,
        autoRenew: false,
        status: SubscriptionStatus.pending,
      );

      await subscriptionRepo.createPendingSubscriptionOnly(subscription);
      print('Pending ${isStripe ? "Stripe" : "PayPal"} subscription created: $subscriptionId');
    } catch (e) {
      print('Error creating pending subscription: $e');
      throw Exception('Failed to create pending subscription: $e');
    }
  }

  /// Update subscription status to failed
  // Future<void> _updateSubscriptionStatusToFailed(String subscriptionId) async {
  //   try {
  //     if (subscriptionId.isEmpty) return;
  //     await subscriptionRepo.updateSubscriptionStatus(
  //       subscriptionId,
  //       SubscriptionStatus.failed,
  //     );
  //     print('Subscription status updated to failed: $subscriptionId');
  //   } catch (e) {
  //     print('Error updating subscription to failed: $e');
  //   }
  // }

  /// Delete pending subscription
  Future<void> _deletePendingSubscription(String subscriptionId) async {
    try {
      if (subscriptionId.isEmpty) return;
      await subscriptionRepo.deleteSubscription(subscriptionId);
      print('Pending subscription deleted: $subscriptionId');
    } catch (e) {
      print('Error deleting pending subscription: $e');
    }
  }

  /// Verify subscription payment status
  Future<void> _verifySubscriptionPaymentStatus(
      String stripeSubscriptionId,
      SubscriptionPlanModel plan,
      ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final idToken = await user.getIdToken();

      final response = await http.post(
        Uri.parse(verifySubscriptionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({
          'subscriptionId': stripeSubscriptionId,
        }),
      );

      print('Verify subscription response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final subscriptionStatus = result['subscriptionStatus'];
        final paymentStatus = result['paymentStatus'];

        if (subscriptionStatus == 'active' && paymentStatus == 'succeeded') {
          await _waitForWebhookUpdate(stripeSubscriptionId);
        } else if (subscriptionStatus == 'incomplete') {
          throw Exception('Payment requires additional authentication');
        } else {
          paymentStatus.value = 'Payment processing...';
          await _waitForWebhookUpdate(stripeSubscriptionId);
        }
      } else {
        throw Exception('Failed to verify payment status');
      }
    } catch (e) {
      print('Error verifying payment: $e');
      TLoaders.modernSnackBar(
        title: 'Payment Status',
        message: 'Payment submitted. We\'ll confirm the status shortly.',
      );
    }
  }

  /// Wait for webhook to update subscription
  Future<void> _waitForWebhookUpdate(String stripeSubscriptionId) async {
    try {
      paymentStatus.value = 'Waiting for confirmation...';

      for (int i = 0; i < 10; i++) {
        await Future.delayed(Duration(seconds: 1));

        final subscription = await subscriptionRepo.getSubscriptionById(stripeSubscriptionId);

        if (subscription != null && subscription.status == SubscriptionStatus.active) {
          paymentStatus.value = 'Payment successful!';

          TLoaders.successSnackBar(
            title: 'Payment Successful',
            message: 'Your subscription has been activated!',
          );

          Get.offAll(() => SubscriptionSuccessScreen(), arguments: subscription);
          return;
        }
      }

      TLoaders.modernSnackBar(
        title: 'Payment Processing',
        message: 'Your payment is being processed. Please check your subscriptions.',
      );

      Get.back();
    } catch (e) {
      print('Error waiting for webhook update: $e');
      throw e;
    }
  }

  /// Create Stripe Subscription
  Future<Map<String, dynamic>?> _createStripeSubscription(
      SubscriptionPlanModel plan,
      ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final idToken = await user.getIdToken();

      final response = await http.post(
        Uri.parse(createSubscriptionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({
          'priceId': 'price_1SPhYoFLRUQjWHbT9s3nhT2w',
          'planId': plan.subscriptionPlanId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create subscription: ${response.body}');
      }
    } catch (e) {
      print('Failed to initialize payment: $e');
      return null;
    }
  }

  /// Handle Payment Error
  void _handlePaymentError(String error) {
    String errorMessage = 'Payment failed';

    if (error.contains('canceled') || error.contains('cancelled')) {
      errorMessage = 'Payment was canceled by user';
    } else if (error.contains('failed')) {
      errorMessage = 'Payment failed. Please try again';
    } else if (error.contains('network')) {
      errorMessage = 'Network error. Please check your connection';
    }

    paymentStatus.value = errorMessage;

    TLoaders.errorSnackBar(
      title: 'Payment Error',
      message: errorMessage,
    );
  }

  /// Process PayPal Subscription Payment (使用内嵌 Native SDK)
  Future<void> _processPayPalSubscriptionPayment(SubscriptionPlanModel plan) async {
    try {
      isProcessingPayment.value = true;
      paymentStatus.value = 'Creating PayPal subscription...';

      // Step 1: 创建 PayPal subscription
      final subscriptionData = await _createPayPalSubscription(plan);
      if (subscriptionData == null) {
        throw Exception('Failed to create PayPal subscription');
      }

      currentPayPalSubscriptionId.value = subscriptionData['subscriptionId'];
      final approvalUrl = subscriptionData['approval_url'];

      if (approvalUrl == null) {
        throw Exception('No approval URL received from PayPal');
      }

      // Step 2: 创建 pending subscription record
      await _createPendingSubscription(
        subscriptionId: currentPayPalSubscriptionId.value,
        plan: plan,
        isStripe: false,
      );

      paymentStatus.value = 'Opening PayPal...';

      // Step 3: 使用 Native PayPal SDK 打开内嵌支付界面
      await _launchPayPalNativeCheckout(approvalUrl);

    } catch (e) {
      _handlePaymentError(e.toString());
      isProcessingPayment.value = false;
    }
  }

  /// Launch PayPal Native Checkout
  Future<void> _launchPayPalNativeCheckout(String approvalUrl) async {
    try {
      await platform.invokeMethod('startPayPalCheckout', {
        'approvalUrl': approvalUrl,
        'subscriptionId': currentPayPalSubscriptionId.value,
      });
    } catch (e) {
      print('Error launching PayPal checkout: $e');
      throw Exception('Failed to launch PayPal checkout: $e');
    }
  }

  /// Create PayPal Subscription
  Future<Map<String, dynamic>?> _createPayPalSubscription(SubscriptionPlanModel plan) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final idToken = await user.getIdToken();

      final response = await http.post(
        Uri.parse(createPayPalSubscriptionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({
          'planId': plan.subscriptionPlanId,
        }),
      );

      print('PayPal subscription response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create PayPal subscription: ${response.body}');
      }
    } catch (e) {
      print('Error in _createPayPalSubscription: $e');
      TLoaders.errorSnackBar(title: 'Error', message: 'Failed to initialize PayPal payment: $e');
      return null;
    }
  }

  /// Reset payment status
  void resetPaymentStatus() {
    paymentStatus.value = '';
    currentPaymentIntentId.value = '';
    currentPayPalSubscriptionId.value = '';
    currentStripeSubscriptionId.value = '';
    selectedPaymentMethod.value = '';
    isProcessingPayment.value = false;
  }

  /// Get current payment status
  String getCurrentPaymentStatus() {
    return paymentStatus.value;
  }

  /// Download payment receipt
  Future<void> downloadReceipt(UserSubscriptionModel subscription) async {
    try {
      await ExportHelper.exportReceipt(subscription: subscription);
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to download receipt: $e',
      );
    }
  }
}