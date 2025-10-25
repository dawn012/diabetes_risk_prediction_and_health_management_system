import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:get/get.dart';

import '../features/community/views/posts/post_detail_screen.dart';

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

  /// 初始化Deep Link监听器
  void _initializeDeepLinkListener() {
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

  /// 获取初始深度链接（冷启动/热启动）
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

  /// 统一处理所有 deep link
  Future<void> _processDeepLink(Uri uri) async {
    try {
      isProcessingDeepLink.value = true;
      currentDeepLink.value = uri.toString();

      print('Processing deep link: ${uri.toString()}');
      print('Scheme: ${uri.scheme}, Host: ${uri.host}, Path: ${uri.path}');

      // 处理 HTTPS 链接（App Links / Universal Links）
      if (uri.scheme == 'https' &&
          (uri.host == 'diabetes-health-system.web.app' || uri.host == 'diabetes-health-system.firebaseapp.com')) {
        await _handleHttpsDeepLink(uri);
      }
      // 处理自定义 scheme（备用）
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

  /// 处理 HTTPS 链接（App Links / Universal Links）
  Future<void> _handleHttpsDeepLink(Uri uri) async {
    final pathSegments = uri.pathSegments;
    if (pathSegments.isEmpty) return;

    // Firebase 域名
    if (uri.host == 'diabetes-health-system.web.app') {
      // 处理社区链接
      if (pathSegments[0] == 'community') {
        await _handleCommunityDeepLink(uri);
      }
    }
  }

  /// 处理社区相关的 deep link
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

  /// 处理帖子 deep link
  /// 格式: https://diatrack.app/community/post/{postId}
  Future<void> _handlePostDeepLink(Uri uri) async {
    final pathSegments = uri.pathSegments;
    if (pathSegments.length < 3) {
      throw Exception('No post ID provided');
    }

    final postId = pathSegments[2];
    print('Navigating to post via App Link: $postId');

    // 导航到帖子详情页面
    Get.to(() => PostDetailScreen(postId: postId));
  }

  /// 处理自定义 scheme（备用）
  Future<void> _handleDiatrackScheme(Uri uri) async {
    switch (uri.host) {
      case 'community':
        await _handleCommunityScheme(uri);
        break;
      default:
        print('Unknown diatrack host: ${uri.host}');
    }
  }

  /// 处理自定义 scheme 的社区链接
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

  /// 处理自定义 scheme 的帖子链接
  Future<void> _handlePostScheme(Uri uri) async {
    final pathSegments = uri.pathSegments;
    if (pathSegments.length < 2) {
      throw Exception('No post ID provided');
    }

    final postId = pathSegments[1];
    print('Navigating to post via custom scheme: $postId');

    Get.to(() => PostDetailScreen(postId: postId));
  }

  /// 生成帖子的 HTTPS 链接（App Links / Universal Links）
  String generatePostDeepLink(String postId) {
    return 'https://diabetes-health-system.web.app/community/post/$postId';
  }

  /// 生成自定义 scheme 链接（备用）
  String generatePostCustomScheme(String postId) {
    return 'diatrack://community/post/$postId';
  }
}