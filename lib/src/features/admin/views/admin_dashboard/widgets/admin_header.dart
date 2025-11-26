import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../common/widgets/dialogs/common_confirmation_dialog.dart';
import '../../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../../data/repositories/notification/notification_repository.dart';
import '../../../../../utils/constants/admin_colors.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/admin_dashboard_controller.dart';
import '../../../../personalization/controllers/user_controller.dart';
import '../../profile/admin_notification_screen.dart';

class AdminHeader extends StatelessWidget {
  const AdminHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);
    final authRepo = AuthenticationRepository.instance;
    final userController = Get.find<UserController>();
    final dashboardController = Get.find<AdminDashboardController>();
    final currentUserId = authRepo.authUser?.uid ?? '';

    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceColor(darkMode),
        border: Border(
          bottom: BorderSide(
            color: TAdminColors.getBorderColor(darkMode),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: darkMode ? Colors.black12 : Colors.grey.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Breadcrumb or current page
          Text(
            'Admin Dashboard',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: TAdminColors.getOnSurfaceColor(darkMode),
            ),
          ),

          Spacer(),

          // Quick actions and user menu
          Row(
            children: [
              // Notification Bell
              StreamBuilder<int>(
                stream: NotificationRepository.instance
                    .streamUnreadCount(currentUserId),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;

                  return Stack(
                    clipBehavior: Clip.none, // Allow badge to overflow
                    children: [
                      IconButton(
                        onPressed: () {
                          Get.to(() => AdminNotificationScreen());
                        },
                        icon: Icon(
                          Iconsax.notification_bold,
                          color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                          size: 20,
                        ),
                        tooltip: 'Notifications',
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: unreadCount > 99 ? 4 : 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: TAdminColors.error,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: TAdminColors.getSurfaceColor(darkMode),
                                width: 1.3,
                              ),
                            ),
                            constraints: BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Center(
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: unreadCount > 99 ? 8 : 10,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),

              SizedBox(width: 8),

              // Theme toggle
              IconButton(
                onPressed: () => Get.changeThemeMode(
                  Get.isDarkMode ? ThemeMode.light : ThemeMode.dark,
                ),
                icon: SizedBox(
                  width: 24,
                  height: 24,
                  child: Transform.translate(
                    offset: Get.isDarkMode ? Offset(10, 0) : Offset(0, 0),
                    child: Icon(
                      Get.isDarkMode ? Iconsax.sun_1_bold : Iconsax.moon_bold,
                      color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                      size: 20,
                    ),
                  ),
                ),
                tooltip: 'Toggle theme',
              ),

              SizedBox(width: 16),

              // User profile menu
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'profile':
                      dashboardController.selectMenuItem(5);
                      break;
                    case 'settings':
                    // TODO: Navigate to settings
                      break;
                    case 'logout':
                      ConfirmationDialog.showLogout(
                        onConfirm: () async {
                          await AuthenticationRepository.instance.logout();
                        },
                      );
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Iconsax.user_bold, size: 16),
                        SizedBox(width: 12),
                        Text('Profile'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Iconsax.setting_bold, size: 16),
                        SizedBox(width: 12),
                        Text('Settings'),
                      ],
                    ),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Iconsax.logout_bold, size: 16, color: TAdminColors.error),
                        SizedBox(width: 12),
                        Text('Logout', style: TextStyle(color: TAdminColors.error)),
                      ],
                    ),
                  ),
                ],
                child: Obx(() {
                  final user = userController.user.value;
                  final hasProfileImage = user.profileImg.isNotEmpty;
                  final username = user.username.isNotEmpty ? user.username : 'Admin';
                  final email = authRepo.authUser?.email ?? '';

                  return Row(
                    children: [
                      hasProfileImage
                          ? CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(user.profileImg),
                        backgroundColor: TAdminColors.getSurfaceVariantColor(darkMode),
                      )
                          : CircleAvatar(
                        radius: 20,
                        backgroundColor: TAdminColors.primary,
                        child: Text(
                          username.isNotEmpty
                              ? username.substring(0, 1).toUpperCase()
                              : email.isNotEmpty
                              ? email.substring(0, 1).toUpperCase()
                              : 'A',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            user.username.isNotEmpty ? user.username : email.split('@').first,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: TAdminColors.getOnSurfaceColor(darkMode),
                            ),
                          ),
                          Text(
                            'Administrator',
                            style: TextStyle(
                              fontSize: 12,
                              color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Iconsax.arrow_down_1_bold,
                        size: 16,
                        color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}