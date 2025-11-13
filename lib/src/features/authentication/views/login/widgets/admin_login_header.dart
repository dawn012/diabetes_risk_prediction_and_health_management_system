import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../utils/constants/admin_colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/helpers/helper_functions.dart';

class AdminLoginHeader extends StatelessWidget {
  const AdminLoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);
    final isWeb = THelperFunctions.screenWidth() > 600;

    return Column(
      children: [
        // Logo with gradient background
        Container(
          padding: EdgeInsets.all(isWeb ? 24 : 20),
          decoration: BoxDecoration(
            gradient: TAdminColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: TAdminColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Iconsax.shield_tick_bold,
            size: isWeb ? 48 : 40,
            color: Colors.white,
          ),
        ),

        SizedBox(height: isWeb ? TSizes.lg : TSizes.md),

        // App Name
        Text(
          TTexts.appName,
          style: TextStyle(
            fontSize: isWeb ? 32 : 28,
            fontWeight: FontWeight.bold,
            color: TAdminColors.getOnSurfaceColor(darkMode),
            letterSpacing: 1.2,
          ),
        ),

        SizedBox(height: TSizes.xs),

        // Title
        Text(
          TTexts.adminLoginTitle,
          style: TextStyle(
            fontSize: isWeb ? 24 : 20,
            fontWeight: FontWeight.w600,
            color: TAdminColors.getOnSurfaceColor(darkMode),
          ),
        ),

        SizedBox(height: TSizes.xs),

        // Subtitle
        Text(
          TTexts.adminLoginSubTitle,
          style: TextStyle(
            fontSize: isWeb ? 16 : 14,
            color: TAdminColors.getOnSurfaceVariantColor(darkMode),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}