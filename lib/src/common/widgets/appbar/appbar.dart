import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../utils/constants/sizes.dart';
import '../../../utils/device/device_utility.dart';

// PreferredSizeWidget 要求实现 preferredSize 属性，表示组件的理想尺寸。
// 自定义 AppBar 需要自己实现 PreferredSizeWidget
class TAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TAppBar({
    super.key,
    this.title,
    this.showBackArrow = false,
    this.leadingIcon,
    this.actions,
    this.leadingOnPressed
  });

  final Widget? title;
  final bool showBackArrow;
  final IconData? leadingIcon;  // 自定义左侧图标
  final List<Widget>? actions;  // 提供一组操作按钮
  final VoidCallback? leadingOnPressed;  // 定义左侧图标的点击事件

  @override
  Widget build(BuildContext context) {
    return Padding(
        // padding: const EdgeInsets.symmetric(horizontal: TSizes.md),  // 给 AppBar 左右添加一定的内边距，让内容 不会紧贴屏幕边缘
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: AppBar(
        automaticallyImplyLeading: false,  // 禁止 AppBar 自动添加返回按钮
        leading: showBackArrow  // 有 back show back，不然就 show 自定义 icon
            ? IconButton(onPressed: () => Get.back(), icon: const Icon(Iconsax.arrow_left_2_outline),)
            : leadingIcon != null ? IconButton(onPressed: leadingOnPressed, icon: Icon(leadingIcon)) : null,
        title: title,
        actions: actions,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(TDeviceUtils.getAppBarHeight());  // 拿默认高度
}
