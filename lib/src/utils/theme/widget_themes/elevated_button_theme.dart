import 'package:flutter/material.dart';

import '../../constants/colors.dart';

class TElevatedButtonTheme {
  TElevatedButtonTheme._();

  static ElevatedButtonThemeData lightElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      foregroundColor: TColors.white,
      backgroundColor: TColors.buttonPrimary,
      disabledForegroundColor: TColors.white.withOpacity(0.7),
      disabledBackgroundColor: TColors.buttonPrimary.withOpacity(0.5),
      padding: const EdgeInsets.symmetric(vertical: 18),
      textStyle: const TextStyle(fontSize: 16, color: TColors.white, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  static ElevatedButtonThemeData darkElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      foregroundColor: TColors.white,
      backgroundColor: TColors.buttonPrimary,
      disabledForegroundColor: TColors.white.withOpacity(0.7),
      disabledBackgroundColor: TColors.buttonPrimary.withOpacity(0.5),
      padding: const EdgeInsets.symmetric(vertical: 18),
      textStyle: const TextStyle(fontSize: 16, color: TColors.white, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}