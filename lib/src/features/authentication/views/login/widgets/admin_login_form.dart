import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/constants/admin_colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../../../utils/validators/user_profile_validator.dart';
import '../../../controllers/admin_login_controller.dart';

class AdminLoginForm extends StatefulWidget {
  const AdminLoginForm({Key? key}) : super(key: key);

  @override
  _AdminLoginFormState createState() => _AdminLoginFormState();
}

class _AdminLoginFormState extends State<AdminLoginForm> {
  FocusNode emailFocusNode = FocusNode();
  FocusNode passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    emailFocusNode.addListener(() {
      setState(() {});
    });
    passwordFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminLoginController>();
    final darkMode = THelperFunctions.isDarkMode(context);
    final isWeb = THelperFunctions.screenWidth() > 600;

    return Form(
      key: controller.loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          /// Email Field
          TextFormField(
            controller: controller.email,
            validator: (value) => TUserProfileValidator.validateEmail(value),
            focusNode: emailFocusNode,
            style: TextStyle(
              color: TAdminColors.getOnSurfaceColor(darkMode),
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.email_outlined,
                color: emailFocusNode.hasFocus
                    ? TAdminColors.primary
                    : TAdminColors.getOnSurfaceVariantColor(darkMode),
              ),
              labelText: TTexts.email,
              labelStyle: TextStyle(
                color: emailFocusNode.hasFocus
                    ? TAdminColors.primary
                    : TAdminColors.getOnSurfaceVariantColor(darkMode),
              ),
              filled: true,
              fillColor: TAdminColors.getSurfaceVariantColor(darkMode),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: TAdminColors.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: TAdminColors.error,
                  width: 1,
                ),
              ),
            ),
          ),

          SizedBox(height: TSizes.spaceBtwInputFields),

          /// Password Field
          Obx(
                () => TextFormField(
              controller: controller.password,
              validator: (value) =>
                  TUserProfileValidator.validateEmptyText('password', value),
              obscureText: controller.hidePassword.value,
              focusNode: passwordFocusNode,
              style: TextStyle(
                color: TAdminColors.getOnSurfaceColor(darkMode),
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: passwordFocusNode.hasFocus
                      ? TAdminColors.primary
                      : TAdminColors.getOnSurfaceVariantColor(darkMode),
                ),
                labelText: TTexts.password,
                labelStyle: TextStyle(
                  color: passwordFocusNode.hasFocus
                      ? TAdminColors.primary
                      : TAdminColors.getOnSurfaceVariantColor(darkMode),
                ),
                filled: true,
                fillColor: TAdminColors.getSurfaceVariantColor(darkMode),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: TAdminColors.primary,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: TAdminColors.error,
                    width: 1,
                  ),
                ),
                suffixIcon: IconButton(
                  onPressed: controller.togglePasswordVisibility,
                  icon: Icon(
                    controller.hidePassword.value
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: isWeb ? TSizes.xl : TSizes.lg),

          /// Sign In Button
          Obx(
                () => SizedBox(
              height: isWeb ? 56 : 48,
              child: ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () => controller.adminLogin(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TAdminColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: TAdminColors.primary.withOpacity(0.6),
                  disabledForegroundColor: Colors.white.withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: controller.isLoading.value
                    ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                )
                    : Text(
                  TTexts.signIn,
                  style: TextStyle(
                    fontSize: isWeb ? 16 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}