// role_middleware.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/loaders/loaders.dart';
import '../../data/repositories/authentication/authentication_repository.dart';

class RoleMiddleware extends GetMiddleware {
  final List<String> allowedRoles;

  RoleMiddleware({required this.allowedRoles});

  @override
  Future<GetNavConfig?> redirectDelegate(GetNavConfig route) async {
    final authRepo = AuthenticationRepository.instance;
    final userRole = await authRepo.getUserRole();

    // 检查用户是否有权限
    final hasPermission = allowedRoles.contains(userRole);

    if (!hasPermission) {
      if (kIsWeb) {
        // Web端：重定向到访问拒绝页面
        return GetNavConfig.fromRoute('/access-denied');
      } else {
        // Mobile端：显示错误提示并阻止导航
        TLoaders.errorSnackBar(
            title: 'Access Denied',
            message: "You don't have the permission to access this page."
        );
        return null; // 阻止导航
      }
    }

    // 有权限，继续导航
    return await super.redirectDelegate(route);
  }

  @override
  int get priority => 2; // 设置优先级
}