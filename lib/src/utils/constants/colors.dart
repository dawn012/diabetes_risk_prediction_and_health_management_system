import 'package:flutter/material.dart';

class TColors {
  TColors._();

  /// User Side Color
  /* -- App Basic Colors -- */
  static const Color primary = Color(0xff017aff);
  static const Color secondary = Color(0xff143371);
  static const Color third = Color(0xff5f94c2);
  static const Color accent = Color(0xffb0c7ff);
  static const Color lightBlueColor = Color(0xffe9f2ff);

  /* -- Text Colors -- */
  static const Color textPrimary = Color(0xff333333);
  static const Color textSecondary = Color(0xff6c757d);
  static const Color textWhite = Color(0xffffffff);

  /* -- Background Colors -- */
  static const Color light = Color(0xfff6f6f6);
  static const Color dark = Color(0xff272727);
  static const Color primaryBackground = Color(0xfff3f5ff);

  /* -- Background Container Colors -- */
  static const Color lightContainer = Color(0xfff6f6f6);
  // static Color darkContainer = Colors.white.withValues(alpha: 0.1);

  /* -- Button Colors -- */
  static const Color buttonPrimary = Color(0xff017aff);
  static const Color buttonSecondary = Color(0xff6c7570);
  static const Color buttonDisabled = Color(0xffc4c4c4);

  /* -- Border Colors -- */
  static const Color borderPrimary = Color(0xffd9d9d9);
  static const Color borderSecondary = Color(0xffe6e6e6);

  /* -- Error and Validation Colors -- */
  // static const Color error = Color(0xffd32f2f);
  // static const Color success = Color(0xff388e3c);
  // static const Color warning = Color(0xfff57c00);
  // static const Color info = Color(0xff1976d2);
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF6EE7B7);
  static const Color successDark = Color(0xFF047857);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFCD34D);
  static const Color warningDark = Color(0xFFB45309);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFCA5A5);
  static const Color errorDark = Color(0xFFDC2626);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF93C5FD);
  static const Color infoDark = Color(0xFF1D4ED8);

  /* -- Neutral Shades -- */
  static const Color black = Color(0xff232323);
  static const Color darkerGrey = Color(0xff4f4f4f);
  static const Color darkGrey = Color(0xff939393);
  static const Color grey = Color(0xffe0e0e0);
  static const Color softGrey = Color(0xfff4f4f4);
  static const Color lightGrey = Color(0xfff9f9f9);
  static const Color white = Color(0xffffffff);

  static const Color tCardBgColor = Color(0xfff7f6f1);
  // static const Color tWhiteColor = Color(0xffffffff);
  // static const Color tDarkColor = Color(0xff000000);

  /* -- Ranking Color -- */
  static const Color gold = Color(0xFFFFB300);
  static const Color silver = Color(0xFF9E9E9E);
  static const Color bronze = Color(0xFFBF6000);

  static const Color communityBgColor = Color(0xffc9ccd3);

  /* -- Health Data Level Colors -- */
  // Glucose Levels
  static const Color glucoseLow = Color(0xFF8B5CF6);        // Purple for low
  static const Color glucoseLowLight = Color(0xFFDDD6FE);
  static const Color glucoseLowDark = Color(0xFF7C3AED);

  static const Color glucoseGood = Color(0xFF10B981);       // Green for good (reuse success)
  static const Color glucoseGoodLight = Color(0xFFD1FAE5);
  static const Color glucoseGoodDark = Color(0xFF047857);

  static const Color glucoseHigh = Color(0xFFFF6B35);       // Orange-red for high
  static const Color glucoseHighLight = Color(0xFFFFE4DD);
  static const Color glucoseHighDark = Color(0xFFE55B2B);

  // Blood Pressure Levels
  static const Color bpLow = Color(0xFF06B6D4);            // Cyan for low BP
  static const Color bpLowLight = Color(0xFFCFFAFE);
  static const Color bpLowDark = Color(0xFF0891B2);

  static const Color bpNormal = Color(0xFF10B981);         // Green for normal
  static const Color bpNormalLight = Color(0xFFD1FAE5);
  static const Color bpNormalDark = Color(0xFF047857);

  static const Color bpElevated = Color(0xFFF59E0B);       // Yellow for elevated
  static const Color bpElevatedLight = Color(0xFFFEF3C7);
  static const Color bpElevatedDark = Color(0xFFD97706);

  static const Color bpHigh = Color(0xFFEF4444);           // Red for high
  static const Color bpHighLight = Color(0xFFFECECE);
  static const Color bpHighDark = Color(0xFFDC2626);

  /* -- Weight Status Colors -- */
  static const Color weightUnderweight = Color(0xFF06B6D4);
  static const Color weightNormal = Color(0xFF10B981);
  static const Color weightOverweight = Color(0xFFF59E0B);
  static const Color weightObese = Color(0xFFEF4444);

  /* -- Exercise Intensity Colors -- */
  static const Color exerciseLowIntensity = Color(0xFF06B6D4);      // Cyan for low intensity
  static const Color exerciseLowIntensityLight = Color(0xFFCFFAFE);
  static const Color exerciseLowIntensityDark = Color(0xFF0891B2);

  static const Color exerciseModerateIntensity = Color(0xFFF59E0B);  // Orange for moderate
  static const Color exerciseModerateIntensityLight = Color(0xFFFCD34D);
  static const Color exerciseModerateIntensityDark = Color(0xFFB45309);

  static const Color exerciseHighIntensity = Color(0xFFEF4444);      // Red for high intensity
  static const Color exerciseHighIntensityLight = Color(0xFFFCA5A5);
  static const Color exerciseHighIntensityDark = Color(0xFFDC2626);
  static const Color exerciseDefault = Color(0xFF10B981);

  /* -- Steps Colors -- */
  static const Color stepsDefault = Color(0xFF9E9E9E);              // Grey for steps bars
  static const Color stepsGoalLine = Color(0xFF017aff);             // Primary blue for goal line
  static const Color stepsAboveGoal = Color(0xFF10B981);            // Green for above goal
  static const Color stepsBelowGoal = Color(0xFFF59E0B);            // Orange for below goal

  /* -- Chart Colors -- */
  static const Color chartGridLine = Color(0xFFE5E7EB);
  static const Color chartAxisText = Color(0xFF6B7280);
  static const Color chartTooltipBg = Color(0xFFF9FAFB);
  static const Color chartTooltipBorder = Color(0xFFE5E7EB);

  /* -- Notification Colors -- */
  static const Color unreadNotification = Color(0xFFE3F2FD);         // Light blue background for unread
  static const Color unreadNotificationDark = Color(0xFF1E3A8A);     // Dark blue background for unread (dark mode)
  static const Color unreadIndicator = Color(0xFF2563EB);            // Blue dot for unread indicator

  static const Color readNotification = Color(0xFFFFFFFF);           // White background for read
  static const Color readNotificationDark = Color(0xFF374151);      // Dark gray background for read (dark mode)

  static const Color reminderNotification = Color(0xFFFEF3C7);       // Light yellow for reminder notifications
  static const Color reminderNotificationDark = Color(0xFF92400E);   // Dark yellow for reminder (dark mode)
  static const Color reminderIcon = Color(0xFFF59E0B);              // Orange icon for reminder

  static const Color systemNotification = Color(0xFFDCFDF7);         // Light green for system notifications
  static const Color systemNotificationDark = Color(0xFF064E3B);     // Dark green for system (dark mode)
  static const Color systemIcon = Color(0xFF059669);                // Green icon for system

  static const Color notificationBorder = Color(0xFFE5E7EB);         // Light border
  static const Color notificationBorderDark = Color(0xFF4B5563);     // Dark border

  static const Color notificationShadow = Color(0x0A000000);         // Subtle shadow
  static const Color notificationShadowDark = Color(0x1A000000);     // Darker shadow for dark mode

  static const Color deleteAction = Color(0xFFDC2626);               // Red for delete actions
  static const Color deleteBackground = Color(0xFFFEE2E2);           // Light red background for delete

  static const Color batchSelectBorder = Color(0xFF3B82F6);          // Blue border for batch selection
  static const Color batchSelectBackground = Color(0xFFEBF8FF);      // Light blue background for batch selection

/* -- Additional Dark Mode Colors -- */
  static const Color darkContainer = Color(0xFF2D2D2D);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkBackground = Color(0xFF121212);

  /* -- Text Field Colors -- */
  static const Color inputFillLight = Color(0xFFF8F9FA);
  static const Color inputFillDark = Color(0xFF2D3139);
  static const Color inputBorderLight = Color(0xFFE1E5E9);
  static const Color inputBorderDark = Color(0xFF404854);

  /* -- Enhanced Gradient Colors -- */
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF017aff),
      Color(0xFF017aff),
    ],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2D3139),
      Color(0xFF1E2329),
    ],
  );

  /* -- Shadow Colors -- */
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowDark = Color(0x33000000);

  /* -- Interactive States -- */
  static const Color hoverLight = Color(0xFFF5F7FA);
  static const Color hoverDark = Color(0xFF374151);
  static const Color pressedLight = Color(0xFFEBF0F7);
  static const Color pressedDark = Color(0xFF4B5563);

  /* -- Status Colors with Variants -- */
  static const Color onlineIndicator = Color(0xFF10B981);
  static const Color offlineIndicator = Color(0xFF6B7280);
  static const Color typingIndicator = Color(0xFF3B82F6);

  /* -- Enhanced Card Colors -- */
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1F2937);
  static const Color cardBorderLight = Color(0xFFE5E7EB);
  static const Color cardBorderDark = Color(0xFF374151);

  /* -- Post Type Colors -- */
  static const Color generalPost = Color(0xFF6366F1);
  static const Color tipsPost = Color(0xFF10B981);
  static const Color recipePost = Color(0xFFF59E0B);
  static const Color storyPost = Color(0xFFEF4444);

  /// Helper method to get post type color
  static Color getPostTypeColor(String postType) {
    switch (postType.toLowerCase()) {
      case 'general':
        return generalPost;
      case 'tips':
        return tipsPost;
      case 'recipe':
        return recipePost;
      case 'story':
        return storyPost;
      default:
        return primary;
    }
  }

  /* -- Post Status Colors -- */
  static const Color postActive = Color(0xFF10B981);
  static const Color postActiveLight = Color(0xFFD1FAE5);
  static const Color postActiveDark = Color(0xFF047857);

  static const Color postDisabled = Color(0xFF9CA3AF);
  static const Color postDisabledLight = Color(0xFFF3F4F6);
  static const Color postDisabledDark = Color(0xFF6B7280);

  static const Color postDisabledBg = Color(0xFFFEF2F2);
  static const Color postDisabledBgDark = Color(0xFF7F1D1D);

  /* -- Chip Colors -- */
  static const Color chipBackground = Color(0xFFF3F4F6);
  static const Color chipBackgroundDark = Color(0xFF374151);
  static const Color chipSelected = Color(0xFF017aff);
  static const Color chipSelectedDark = Color(0xFF3B82F6);

  /* -- Search Bar Colors -- */
  static const Color searchBarBackground = Color(0xFFF9FAFB);
  static const Color searchBarBackgroundDark = Color(0xFF1F2937);

  /* -- Leaderboard Colors -- */
  static const Color leaderboardCurrentUserBg = Color(0xFF017aff);
  static const Color leaderboardCurrentUserBorder = Color(0xFF017aff);

  /* -- Tab Selector Colors -- */
  static const Color tabSelectorBackgroundLight = Color(0xFFFFFFFF);
  static const Color tabSelectorBackgroundDark = Color(0xFF1F2937);
  static const Color tabSelectorTextLight = Color(0xFF6B7280);
  static const Color tabSelectorTextDark = Color(0xFF9CA3AF);

  /// Helper methods for theme-based colors
  static Color getCardColor(bool isDark) => isDark ? cardDark : cardLight;
  static Color getCardBorderColor(bool isDark) => isDark ? cardBorderDark : cardBorderLight;
  static Color getInputFillColor(bool isDark) => isDark ? inputFillDark : inputFillLight;
  static Color getInputBorderColor(bool isDark) => isDark ? inputBorderDark : inputBorderLight;
  static Color getHoverColor(bool isDark) => isDark ? hoverDark : hoverLight;
  static Color getShadowColor(bool isDark) => isDark ? shadowDark : shadowLight;
}

