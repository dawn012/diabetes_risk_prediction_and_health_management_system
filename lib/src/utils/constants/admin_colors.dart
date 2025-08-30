import 'package:flutter/material.dart';

/// Admin Side Color
class TAdminColors {
  TAdminColors._();

  // Primary Colors
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF10B981);
  static const Color secondaryLight = Color(0xFF34D399);
  static const Color secondaryDark = Color(0xFF059669);

  // Accent Colors
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentLight = Color(0xFFFBBF24);
  static const Color accentDark = Color(0xFFD97706);

  // Neutral Colors - Light Theme
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF5F5F5);
  static const Color lightOnBackground = Color(0xFF1A1A1A);
  static const Color lightOnSurface = Color(0xFF2D2D2D);
  static const Color lightOnSurfaceVariant = Color(0xFF6B7280);

  // Neutral Colors - Dark Theme
  static const Color darkBackground = Color(0xFF0F1115);
  static const Color darkSurface = Color(0xFF1A1D23);
  static const Color darkSurfaceVariant = Color(0xFF2D3139);
  static const Color darkOnBackground = Color(0xFFF9FAFB);
  static const Color darkOnSurface = Color(0xFFE5E7EB);
  static const Color darkOnSurfaceVariant = Color(0xFF9CA3AF);

  /* -- Error and Validation Colors -- */
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

  // Semantic Colors
  static const Color online = Color(0xFF10B981);
  static const Color offline = Color(0xFF6B7280);
  static const Color banned = Color(0xFFEF4444);
  static const Color pending = Color(0xFFF59E0B);

  // Border & Divider Colors
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color darkBorder = Color(0xFF374151);
  static const Color lightDivider = Color(0xFFE5E7EB);
  static const Color darkDivider = Color(0xFF374151);

  // Shadow Colors
  static const Color lightShadow = Color(0x1A000000);
  static const Color darkShadow = Color(0x33000000);

  // Black and White
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [error, errorLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Interactive Colors
  static const Color hoverLight = Color(0xFFF3F4F6);
  static const Color hoverDark = Color(0xFF374151);
  static const Color focusLight = Color(0xFFDDD6FE);
  static const Color focusDark = Color(0xFF5B21B6);

  // Data Visualization Colors
  static const List<Color> chartColors = [
    Color(0xFF6366F1),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
  ];

  // Role-based Colors
  static const Color adminColor = Color(0xFF7C3AED);
  static const Color managerColor = Color(0xFF059669);
  static const Color userColor = Color(0xFF3B82F6);

  // Table Colors
  static const Color lightTableHeader = Color(0xFFF9FAFB);
  static const Color darkTableHeader = Color(0xFF1F2937);
  static const Color lightTableRow = Color(0xFFFFFFFF);
  static const Color darkTableRow = Color(0xFF1A1D23);
  static const Color lightTableRowHover = Color(0xFFF9FAFB);
  static const Color darkTableRowHover = Color(0xFF2D3139);

  // Get color based on theme
  static Color getBackgroundColor(bool isDark) =>
      isDark ? darkBackground : lightBackground;

  static Color getSurfaceColor(bool isDark) =>
      isDark ? darkSurface : lightSurface;

  static Color getSurfaceVariantColor(bool isDark) =>
      isDark ? darkSurfaceVariant : lightSurfaceVariant;

  static Color getOnSurfaceColor(bool isDark) =>
      isDark ? darkOnSurface : lightOnSurface;

  static Color getOnSurfaceVariantColor(bool isDark) =>
      isDark ? darkOnSurfaceVariant : lightOnSurfaceVariant;

  static Color getBorderColor(bool isDark) =>
      isDark ? darkBorder : lightBorder;

  static Color getHoverColor(bool isDark) =>
      isDark ? hoverDark : hoverLight;

  static Color getTableHeaderColor(bool isDark) =>
      isDark ? darkTableHeader : lightTableHeader;

  static Color getTableRowColor(bool isDark) =>
      isDark ? darkTableRow : lightTableRow;

  static Color getTableRowHoverColor(bool isDark) =>
      isDark ? darkTableRowHover : lightTableRowHover;

  // Role color getter
  static Color getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return adminColor;
      case 'user manager':
      case 'community manager':
      case 'achievement manager':
        return managerColor;
      default:
        return userColor;
    }
  }

  // Status color getter
  static Color getStatusColor(bool isActive, bool isVerified) {
    if (!isActive) return banned;
    if (isVerified) return success;
    return warning;
  }
}