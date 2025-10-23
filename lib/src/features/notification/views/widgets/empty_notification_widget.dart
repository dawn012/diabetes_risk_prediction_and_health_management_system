import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';

class EmptyNotificationWidget extends StatelessWidget {
  final int tabIndex;

  const EmptyNotificationWidget({
    super.key,
    required this.tabIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(TSizes.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _getIconBackgroundColor().withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIcon(),
                  size: 60,
                  color: _getIconColor(),
                ),
              ),

              SizedBox(height: TSizes.xl),

              // Title
              Text(
                _getTitle(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? TColors.white : TColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: TSizes.md),

              // Subtitle
              Text(
                _getSubtitle(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: TColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
              ),

              SizedBox(height: TSizes.xl),

              // Action button (if applicable)
              if (_shouldShowActionButton())
                _buildActionButton(context),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (tabIndex) {
      case 1: // Unread
        return Iconsax.notification_bold;
      case 2: // Read
        return Iconsax.tick_circle_bold;
      default: // All
        return Iconsax.notification_bing_bold;
    }
  }

  Color _getIconColor() {
    switch (tabIndex) {
      case 1: // Unread
        return TColors.unreadIndicator;
      case 2: // Read
        return TColors.success;
      default: // All
        return TColors.primary;
    }
  }

  Color _getIconBackgroundColor() {
    switch (tabIndex) {
      case 1: // Unread
        return TColors.unreadIndicator;
      case 2: // Read
        return TColors.success;
      default: // All
        return TColors.primary;
    }
  }

  String _getTitle() {
    switch (tabIndex) {
      case 1: // Unread
        return 'No Unread Notifications';
      case 2: // Read
        return 'No Read Notifications';
      default: // All
        return 'No Notifications';
    }
  }

  String _getSubtitle() {
    switch (tabIndex) {
      case 1: // Unread
        return 'You\'re all caught up! No new notifications to review.';
      case 2: // Read
        return 'You haven\'t read any notifications yet, or all read notifications have been cleared.';
      default: // All
        return 'You don\'t have any notifications yet. We\'ll notify you about important updates, reminders, and system messages.';
    }
  }

  bool _shouldShowActionButton() {
    return tabIndex == 0; // Only show for "All" tab
  }

  Widget _buildActionButton(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: 280),
      child: ElevatedButton.icon(
        onPressed: () {
          // Navigate to settings or reminder setup
          // This is where you would implement navigation to notification settings
        },
        icon: Icon(
          Iconsax.setting_4_bold,
          size: 18,
        ),
        label: Text('Notification Settings'),
        style: ElevatedButton.styleFrom(
          backgroundColor: TColors.primary,
          foregroundColor: TColors.white,
          padding: EdgeInsets.symmetric(
            vertical: TSizes.md,
            horizontal: TSizes.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}