import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/validators/user_profile_validator.dart';
import '../../../controllers/login_controller.dart';
import '../../forget_password/forget_password_options/forget_password_bottom_sheet.dart';
import '../../signup/signup_screen.dart';

class TLoginForm extends StatefulWidget {
  const TLoginForm({Key? key}) : super(key: key);

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<TLoginForm> {
  // 创建FocusNode用于监听焦点
  FocusNode emailFocusNode = FocusNode();
  FocusNode passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 监听焦点变化
    emailFocusNode.addListener(() {
      setState(() {}); // 通过 setState() 来触发 UI 的重新构建
    });
    passwordFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    // 释放FocusNode
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());

    return Form(
      key: controller.loginFormKey,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: TSizes.spaceBtwSections),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Email
            TextFormField(
              controller: controller.email,
              validator: (value) => TUserProfileValidator.validateEmail(value),
              focusNode: emailFocusNode, // 将FocusNode关联到TextFormField
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person_outline_outlined),
                labelText: TTexts.email,
                labelStyle: TextStyle(
                  color: emailFocusNode.hasFocus
                      ? TColors.primary // 获得焦点时的颜色
                      : null, // 未获得焦点时的颜色
                ),
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwInputFields),

            /// Password
            Obx(
              () => TextFormField(
                controller: controller.password,
                validator: (value) =>
                    TUserProfileValidator.validateEmptyText('password', value),
                obscureText: controller.hidePassword,
                focusNode: passwordFocusNode,
                // 将FocusNode关联到TextFormField
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.fingerprint),
                  labelText: TTexts.password,
                  labelStyle: TextStyle(
                    color: passwordFocusNode.hasFocus
                        ? TColors.primary // 获得焦点时的颜色
                        : null, // 未获得焦点时的颜色
                  ),
                  suffixIcon: IconButton(
                    onPressed: controller.togglePasswordVisibility,
                    icon: Icon(
                      controller.hidePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwInputFields / 2),

            /// Remember Me & Forget Password
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     Row(
            //       children: [
            //         Obx(
            //           () => Checkbox(
            //               value: controller.rememberMe,
            //               onChanged: (value) {
            //                 controller.toggleRememberMe();
            //               }),
            //         ),
            //         GestureDetector(
            //           onTap: () {
            //             controller.toggleRememberMe();
            //           },
            //           child: const Text(TTexts.rememberMe),
            //         ),
            //       ],
            //     ),
            //
            //     /// Forget Password
            //     TextButton(
            //       onPressed: () {
            //         ForgetPasswordScreen.buildShowModalBottomSheet(context);
            //       },
            //       child: Text('${TTexts.forgetPassword}?'),
            //     ),
            //   ],
            // ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  ForgetPasswordScreen.buildShowModalBottomSheet(context);
                },
                child: Text('${TTexts.forgetPassword}?'),
              ),
            ),

            const SizedBox(
              height: TSizes.spaceBtwSections,
            ),

            /// Sign In Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  controller.emailAndPasswordSignIn();
                  // Get.to(() => NavigationMenu());
                },
                child: const Text(TTexts.signIn),
              ),
            ),
            const SizedBox(
              height: TSizes.spaceBtwItems,
            ),

            /// Create Account Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Get.to(() => SignUpScreen()),
                child: const Text(TTexts.createAccount),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
