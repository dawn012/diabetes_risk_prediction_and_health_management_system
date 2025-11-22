import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:get/get.dart';

import '../common/loaders/loaders.dart';
import '../data/repositories/subscription/payment_repository.dart';
import '../data/repositories/subscription/subscription_repository.dart';
import '../features/community/views/posts/post_detail_screen.dart';
import '../features/subscription/views/subscription_detail_screen.dart';
import '../features/subscription/views/subscription_history_screen.dart';
import '../features/subscription/views/subscription_plan_selection_screen.dart';
import '../features/subscription/views/transaction_detail_screen.dart';

class DeepLinkService extends GetxService {
  static DeepLinkService get instance => Get.find();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri?>? _linkSubscription;

  final RxString currentDeepLink = ''.obs;
  final RxBool isProcessingDeepLink = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeDeepLinkListener();
    _getInitialAppLink();
  }

  @override
  void onClose() {
    _linkSubscription?.cancel();
    super.onClose();
  }

  /// Initialize Deep Link listener
  void _initializeDeepLinkListener() {
    print('🔗 Deep link listener started');
    _linkSubscription = _appLinks.uriLinkStream.listen(
          (Uri? uri) {
        if (uri != null) {
          _processDeepLink(uri);
        }
      },
      onError: (err) {
        print('Deep link error: $err');
      },
    );
  }

  /// Get initial deep link (cold start/warm start)
  Future<void> _getInitialAppLink() async {
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _processDeepLink(initialUri);
      }
    } catch (e) {
      print('Failed to get initial app link: $e');
    }
  }

  /// Process all deep links
  Future<void> _processDeepLink(Uri uri) async {
    try {
      isProcessingDeepLink.value = true;
      currentDeepLink.value = uri.toString();

      print('Processing deep link: ${uri.toString()}');
      print('Scheme: ${uri.scheme}, Host: ${uri.host}, Path: ${uri.path}');

      // Handle HTTPS links (App Links / Universal Links)
      if (uri.scheme == 'https' &&
          (uri.host == 'diabetes-health-system.web.app' ||
              uri.host == 'diabetes-health-system.firebaseapp.com' ||
              uri.host == 'diatrack.app')) {
        await _handleHttpsDeepLink(uri);
      }
      // Handle custom scheme (diatrack://)
      else if (uri.scheme == 'diatrack') {
        await _handleDiatrackScheme(uri);
      } else {
        print('Unhandled scheme: ${uri.scheme}');
      }
    } catch (e) {
      print('Error processing deep link: $e');
      Get.snackbar(
        'Error',
        'Failed to process link: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isProcessingDeepLink.value = false;
    }
  }

  /// Handle HTTPS links (App Links / Universal Links)
  Future<void> _handleHttpsDeepLink(Uri uri) async {
    final pathSegments = uri.pathSegments;

    print("Deep link activated: $pathSegments");
    if (pathSegments.isEmpty) return;

    // 处理所有类型的 HTTPS 链接
    switch (pathSegments[0]) {
      case 'community':
        await _handleCommunityDeepLink(uri);
        break;
      case 'subscription':
        await _handleSubscriptionDeepLink(uri);
        break;
      case 'receipt':
        await _handleReceiptDeepLink(uri);
        break;
      case 'payment':
        await _handlePaymentDeepLink(uri);
        break;
      default:
        print('Unknown HTTPS path: ${pathSegments[0]}');
    }
  }

  /// Handle community-related deep links
  Future<void> _handleCommunityDeepLink(Uri uri) async {
    final pathSegments = uri.pathSegments;
    if (pathSegments.length < 2) return;

    switch (pathSegments[1]) {
      case 'post':
        await _handlePostDeepLink(uri);
        break;
      default:
        print('Unknown community path: ${pathSegments[1]}');
    }
  }

  /// Handle post deep link
  /// Format: https://diatrack.app/community/post/{postId}
  Future<void> _handlePostDeepLink(Uri uri) async {
    final pathSegments = uri.pathSegments;
    if (pathSegments.length < 3) {
      throw Exception('No post ID provided');
    }

    final postId = pathSegments[2];
    print('Navigating to post via App Link: $postId');

    Get.to(() => PostDetailScreen(postId: postId));
  }

  // 处理订阅相关链接
  Future<void> _handleSubscriptionDeepLink(Uri uri) async {
    final pathSegments = uri.pathSegments;
    if (pathSegments.length < 2) return;

    final subscriptionId = pathSegments[1];

    if (pathSegments.length >= 3) {
      // 处理 /subscription/{id}/renew 或 /subscription/{id}/reactivate 或 /subscription/{id}/payment
      final action = pathSegments[2];
      switch (action) {
        case 'renew':
          Get.to(() => SubscriptionPlanScreen());
          break;
        case 'reactivate':
          Get.to(() => SubscriptionPlanScreen());
          break;
      }
    } else {
      // 处理 /subscription/{id}
      Get.to(() => SubscriptionHistoryScreen());
    }
  }

  Future<void> _handlePaymentDeepLink(Uri uri) async {
    final pathSegments = uri.pathSegments;
    if (pathSegments.length < 2) return;

    final subscriptionId = pathSegments[1];
    await _handleUpdatePaymentMethod(subscriptionId);
  }

  Future<void> _handleUpdatePaymentMethod(String subscriptionId) async {
    try {
      print('Handling update payment method for subscription: $subscriptionId');

      final subscriptionRepo = Get.put(SubscriptionRepository());

      // 获取订阅详情
      final subscription = await subscriptionRepo.getSubscriptionById(subscriptionId);
      if (subscription == null) {
        throw Exception('Subscription not found: $subscriptionId');
      }

      Get.to(() => SubscriptionDetailScreen(subscription: subscription));

      print('✅ Navigation to update payment method completed');

    } catch (e) {
      print('❌ Error handling update payment method: $e');
      Get.snackbar(
        'Error',
        'Unable to update payment method: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // 处理收据链接
  Future<void> _handleReceiptDeepLink(Uri uri) async {
    final pathSegments = uri.pathSegments;
    if (pathSegments.length < 2) return;

    final transactionId = pathSegments[1];

    _navigateToReceiptDetail(transactionId);
  }

  /// Handle custom scheme (fallback)
  Future<void> _handleDiatrackScheme(Uri uri) async {
    switch (uri.host) {
      case 'community':
        await _handleCommunityScheme(uri);
        break;
      case 'subscription':
        await _handleSubscriptionScheme(uri);
        break;
      case 'receipt':
        await _handleReceiptScheme(uri);
        break;
      case 'payment':  // 新增独立的 payment scheme
        await _handlePaymentScheme(uri);
        break;
      default:
        print('Unknown diatrack host: ${uri.host}');
    }
  }

  // 处理自定义 scheme 订阅链接
  Future<void> _handleSubscriptionScheme(Uri uri) async {
    final pathSegments = uri.pathSegments;
    if (pathSegments.isEmpty) return;

    final subscriptionId = pathSegments[0];

    if (pathSegments.length >= 2) {
      final action = pathSegments[1];
      switch (action) {
        case 'renew':
          Get.to(() => SubscriptionPlanScreen());
          break;
        case 'reactivate':
          Get.to(() => SubscriptionPlanScreen());
          break;
      }
    } else {
      Get.to(() => SubscriptionHistoryScreen());
    }
  }

  // 处理自定义 scheme 收据链接
  Future<void> _handleReceiptScheme(Uri uri) async {
    final pathSegments = uri.pathSegments;
    if (pathSegments.isEmpty) return;

    final transactionId = pathSegments[0];
    _navigateToReceiptDetail(transactionId);
  }

  Future<void> _handlePaymentScheme(Uri uri) async {
    final pathSegments = uri.pathSegments;
    if (pathSegments.isEmpty) return;

    final subscriptionId = pathSegments[0];
    await _handleUpdatePaymentMethod(subscriptionId);
  }

  /// Handle custom scheme community links
  Future<void> _handleCommunityScheme(Uri uri) async {
    final pathSegments = uri.pathSegments;
    if (pathSegments.isEmpty) return;

    switch (pathSegments[0]) {
      case 'post':
        await _handlePostScheme(uri);
        break;
      default:
        print('Unknown community scheme path: ${pathSegments[0]}');
    }
  }

  /// Handle custom scheme post link
  Future<void> _handlePostScheme(Uri uri) async {
    final pathSegments = uri.pathSegments;
    if (pathSegments.length < 2) {
      throw Exception('No post ID provided');
    }

    final postId = pathSegments[1];
    print('Navigating to post via custom scheme: $postId');

    Get.to(() => PostDetailScreen(postId: postId));
  }

  // ==================== Link Generators ====================

  /// Generate post HTTPS link (App Links / Universal Links)
  String generatePostDeepLink(String postId) {
    return 'https://diabetes-health-system.web.app/community/post/$postId';
  }

  /// Generate post custom scheme link (fallback)
  String generatePostCustomScheme(String postId) {
    return 'diatrack://community/post/$postId';
  }

  /// Generate PayPal success callback URL (for Native SDK)
  /// 使用 diatrack:// scheme，因为 Native SDK 会处理回调
  String generatePayPalSuccessUrl({
    required String userId,
    required String planId,
  }) {
    return 'diatrack://payment/paypal-success';
  }

  /// Generate PayPal cancel callback URL (for Native SDK)
  String generatePayPalCancelUrl() {
    return 'diatrack://payment/paypal-cancel';
  }

  Future<void> _navigateToReceiptDetail(String transactionId) async {
    try {
      final paymentRepo = Get.put(PaymentRepository());
      final subscriptionRepo = Get.put(SubscriptionRepository());
      
      final subscriptionId = await paymentRepo.getSubscriptionIdByTransactionId(transactionId) ?? '';
      final subscription = await subscriptionRepo.getSubscriptionById(subscriptionId);

      if (subscription == null) {
        TLoaders.errorSnackBar(
          title: 'Error',
          message: 'Subscription not found',
        );
        return;
      }

      // 导航到收据详情页面
      Get.to(() => TransactionDetailScreen(subscription: subscription, transactionId: transactionId,));
    } catch (e) {
      print('❌ Error handling receipt deep link: $e');
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Unable to load transaction details',
      );
    }
  }
}