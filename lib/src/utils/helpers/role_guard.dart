import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/loaders/loaders.dart';
import '../../data/repositories/authentication/authentication_repository.dart';

class RoleGuard {
  /// 检查用户是否有指定角色
  static Future<bool> hasRole(List<String> allowedRoles) async {
    final authRepo = AuthenticationRepository.instance;
    final userRole = await authRepo.getUserRole();
    return allowedRoles.contains(userRole);
  }

  /// 导航到需要特定角色的页面
  static Future<void> navigateTo(dynamic page, {required List<String> allowedRoles}) async {
    if (await hasRole(allowedRoles)) {
      Get.to(() => page);
    } else {
      _showAccessDeniedMessage();
    }
  }

  /// 显示访问拒绝消息（根据平台调整）
  static void _showAccessDeniedMessage() {
    if (kIsWeb) {
      // Web端：显示更明显的错误提示
      Get.dialog(
        AlertDialog(
          title: Text('Access Denied'),
          content: Text("You don't have the permission to access this page."),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Confirm'),
            ),
          ],
        ),
      );
    } else {
      // Mobile端：使用Snackbar
      TLoaders.errorSnackBar(title: 'Access Denied', message: "You don't have the permission to access this page.");
    }
  }

  /// 检查并执行操作
  static Future<void> executeWithRole(Function action, {required List<String> allowedRoles}) async {
    if (await hasRole(allowedRoles)) {
      action();
    } else {
      _showAccessDeniedMessage();
    }
  }
}