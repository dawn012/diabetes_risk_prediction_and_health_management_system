import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../utils/device/device_utility.dart';

class TAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TAppBar({
    super.key,
    this.title,
    this.showBackArrow = false,
    this.leadingIcon,
    this.actions,
    this.leadingOnPressed,
    this.backgroundColor,
    this.iconTheme,
    this.automaticallyImplyLeading = false,
    this.bottom,
  });

  final Widget? title;
  final bool showBackArrow;
  final IconData? leadingIcon;
  final List<Widget>? actions;
  final VoidCallback? leadingOnPressed;
  final Color? backgroundColor;
  final IconThemeData? iconTheme;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: AppBar(
        automaticallyImplyLeading: automaticallyImplyLeading,
        leading: showBackArrow
            ? IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Iconsax.arrow_left_2_outline),
        )
            : leadingIcon != null
            ? IconButton(
          onPressed: leadingOnPressed,
          icon: Icon(leadingIcon),
        )
            : null,
        title: title,
        actions: actions,
        bottom: bottom,
        backgroundColor: backgroundColor,
        iconTheme: iconTheme,
        elevation: 0,
        // Add padding to prevent tab from squishing title
        toolbarHeight: TDeviceUtils.getAppBarHeight() + (bottom != null ? 8 : 0),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    TDeviceUtils.getAppBarHeight() +
        (bottom?.preferredSize.height ?? 0) +
        (bottom != null ? 8 : 0), // Add extra padding when bottom exists
  );
}