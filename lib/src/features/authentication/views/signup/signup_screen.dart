import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/loading_widget.dart';
import '../../../../common/widgets/login_signup/form_divider.dart';
import '../../../../common/widgets/login_signup/social_buttons.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../controllers/login_controller.dart';
import 'widgets/signup_form.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Title
                  Text(TTexts.signUpTitle, style: Theme.of(context).textTheme.headlineMedium,),
                  /// SubTitle
                  Text(TTexts.signUpSubTitle, style: Theme.of(context).textTheme.bodyMedium,),
                  SizedBox(height: TSizes.spaceBtwSections,),

                  /// Sign Up Form
                  TSignUpForm(),

                  /// Divider
                  const SizedBox(height: TSizes.spaceBtwSections,),
                  TFormDivider(dividerText: TTexts.orSignUpWith.capitalize!),
                  const SizedBox(height: TSizes.spaceBtwSections,),

                  /// Footer
                  const TSocialButtons(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}