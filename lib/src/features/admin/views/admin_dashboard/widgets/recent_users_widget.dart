import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../common/widgets/dialogs/image_preview_dialog.dart';
import '../../../../../utils/constants/admin_colors.dart';
import '../../../../../utils/formatters/formatter.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/recent_users_controller.dart';

class RecentUsersWidget extends StatelessWidget {
  const RecentUsersWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RecentUsersController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceColor(darkMode),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: darkMode ? Colors.black26 : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Recent Users',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: TAdminColors.getOnSurfaceColor(darkMode),
                ),
              ),
              Spacer(),
              TextButton.icon(
                onPressed: () => controller.loadRecentUsers(),
                icon: Icon(Iconsax.refresh_bold, size: 16),
                label: Text('Refresh'),
                style: TextButton.styleFrom(
                  foregroundColor: TAdminColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Obx(() {
            if (controller.isLoading.value) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(
                    color: TAdminColors.primary,
                  ),
                ),
              );
            }

            if (controller.recentUsers.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Iconsax.user_bold,
                        size: 48,
                        color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No recent users',
                        style: TextStyle(
                          color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: controller.recentUsers.map((user) {
                final isNewUser = DateTime.now().difference(user.joinDate).inDays < 1;
                final hasSubscription = controller.isActiveSync(user.userId);

                return _buildUserItem(
                  title: user.username,
                  subtitle: user.email,
                  trailing: TFormatter.formatElapsedTime(user.joinDate),
                  profileImg: user.profileImg,
                  badge: hasSubscription ? 'Premium' : null,
                  badgeColor: TAdminColors.warning,
                  darkMode: darkMode,
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildUserItem({
    required String title,
    required String subtitle,
    required String trailing,
    required String? profileImg,
    String? badge,
    Color? badgeColor,
    required bool darkMode,
  }) {
    final hasImage = profileImg != null && profileImg.isNotEmpty;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Avatar，可点击预览大图
          GestureDetector(
            onTap: hasImage
                ? () {
              ImagePreviewDialog.showNetworkImage(
                context: Get.context!,
                imageUrl: profileImg!,
                title: "$title's Avatar",
                maxWidth: 400,
                maxHeight: 400,
              );
            }
                : null,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TAdminColors.primary.withOpacity(0.1),
              ),
              child: ClipOval(
                child: hasImage
                    ? Image.network(
                  profileImg!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return _buildInitialsAvatar(title, darkMode);
                  },
                )
                    : _buildInitialsAvatar(title, darkMode),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: TAdminColors.getOnSurfaceColor(darkMode),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (badge != null) ...[
                      SizedBox(width: 8),
                      Container(
                        padding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (badgeColor ?? TAdminColors.primary)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: badgeColor ?? TAdminColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color:
                    TAdminColors.getOnSurfaceVariantColor(darkMode),
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Text(
            trailing,
            style: TextStyle(
              color: TAdminColors.getOnSurfaceVariantColor(darkMode),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar(String title, bool darkMode) {
    final initial =
    (title.isNotEmpty ? title[0] : '?').toUpperCase();
    return Container(
      color: TAdminColors.primary.withOpacity(0.1),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: TAdminColors.primary,
          ),
        ),
      ),
    );
  }
}