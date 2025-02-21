import 'package:diabetes_risk_prediction_and_health_management_system/src/features/authentication/views/signup/verify_email.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/validators/validation.dart';
import '../../../controllers/signup_controller.dart';
import 'terms_conditions_checkbox.dart';

class TSignUpForm extends StatefulWidget {
  const TSignUpForm({
    Key? key,
  }) : super(key: key);

  @override
  _SignUpFormState createState() => _SignUpFormState();
}

class _SignUpFormState extends State<TSignUpForm> {
  // 创建FocusNode用于监听焦点
  FocusNode usernameFocusNode = FocusNode();
  FocusNode emailFocusNode = FocusNode();
  FocusNode passwordFocusNode = FocusNode();
  FocusNode confirmPasswordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 监听焦点变化
    usernameFocusNode.addListener(() {
      setState(() {}); // 通过 setState() 来触发 UI 的重新构建
    });
    emailFocusNode.addListener(() {
      setState(() {});
    });
    passwordFocusNode.addListener(() {
      setState(() {});
    });
    confirmPasswordFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    // 释放FocusNode
    usernameFocusNode.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SignUpController());

    return Form(
      key: controller.signupFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Username
          TextFormField(
            controller: controller.username,
            focusNode: usernameFocusNode,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.person_outline_rounded),
              labelText: TTexts.username,
              labelStyle: TextStyle(
                color: usernameFocusNode.hasFocus
                    ? TColors.primary // 获得焦点时的颜色
                    : null, // 未获得焦点时的颜色
              ),
            ),
            validator: (value) =>
                TValidator.validateEmptyText('username', value),
          ),
          const SizedBox(height: TSizes.spaceBtwInputFields),

          /// Email
          TextFormField(
            controller: controller.email,
            focusNode: emailFocusNode,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.email_outlined),
              labelText: TTexts.email,
              labelStyle: TextStyle(
                color: emailFocusNode.hasFocus
                    ? TColors.primary // 获得焦点时的颜色
                    : null, // 未获得焦点时的颜色
              ),
            ),
            validator: (value) => TValidator.validateEmail(value),
          ),
          const SizedBox(height: TSizes.spaceBtwInputFields),

          /// Password
          Obx(() => TextFormField(
                controller: controller.password,
                obscureText: controller.hidePassword,
                // 使用 .value 来获取 RxBool 的值
                focusNode: passwordFocusNode,
                decoration: InputDecoration(
                  prefixIcon: Icon(Iconsax.password_check_bold),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.hidePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: controller.togglePasswordVisibility,
                  ),
                  labelText: TTexts.password,
                  labelStyle: TextStyle(
                    color: passwordFocusNode.hasFocus
                        ? TColors.primary // 获得焦点时的颜色
                        : null, // 未获得焦点时的颜色
                  ),
                ),
                validator: (value) => TValidator.validatePassword(value),
              )),
          const SizedBox(height: TSizes.spaceBtwInputFields),

          /// Confirm Password
          Obx(
            () => TextFormField(
              controller: controller.confirmPassword,
              obscureText: controller.hideConfirmPassword,
              focusNode: confirmPasswordFocusNode,
              decoration: InputDecoration(
                prefixIcon: Icon(Iconsax.password_check_bold),
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.hideConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: controller.toggleConfirmPasswordVisibility,
                ),
                labelText: TTexts.confirmPassword,
                labelStyle: TextStyle(
                  color: confirmPasswordFocusNode.hasFocus
                      ? TColors.primary // 获得焦点时的颜色
                      : null, // 未获得焦点时的颜色
                ),
              ),
              validator: (value) => TValidator.validateConfirmPassword(
                  value, controller.password.text),
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwInputFields),

          /// Terms & Conditions Checkbox
          TTermsAndConditionsCheckbox(),
          const SizedBox(height: TSizes.spaceBtwSections),

          /// Create Account Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                controller.signup();
              },
              child: const Text(TTexts.createAccount),
            ),
          ),
        ],
      ),
    );
  }
}
