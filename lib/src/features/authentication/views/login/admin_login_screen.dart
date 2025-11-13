import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utils/constants/admin_colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/admin_login_controller.dart';
import 'widgets/admin_login_form.dart';
import 'widgets/admin_login_header.dart';

class AdminLoginScreen extends StatelessWidget {
  const AdminLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);
    final controller = Get.put(AdminLoginController());
    final isWeb = THelperFunctions.screenWidth() > 600;

    return Scaffold(
      backgroundColor: TAdminColors.getBackgroundColor(darkMode),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isWeb ? 480 : double.infinity,
            ),
            padding: EdgeInsets.all(isWeb ? TSizes.xl : TSizes.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// Logo & Header
                AdminLoginHeader(),

                SizedBox(height: isWeb ? TSizes.spaceBtwSections : TSizes.lg),

                /// Login Form Card
                Container(
                  padding: EdgeInsets.all(isWeb ? TSizes.xl : TSizes.lg),
                  decoration: BoxDecoration(
                    color: TAdminColors.getSurfaceColor(darkMode),
                    borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
                    boxShadow: [
                      BoxShadow(
                        color: darkMode
                            ? Colors.black26
                            : Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: AdminLoginForm(),
                ),

                SizedBox(height: TSizes.lg),

                /// Footer
                Text(
                  TTexts.adminLoginFooter,
                  style: TextStyle(
                    color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}