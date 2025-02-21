import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/image_strings.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/signup_controller.dart';
import '../forget_password_otp/otp_screen.dart';

class ForgetPasswordPhoneScreen extends StatelessWidget {
  const ForgetPasswordPhoneScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final controller = Get.put(SignUpController());

    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(TSizes.defaultSize),
            child: Column(
              children: [
                const SizedBox(height: TSizes.defaultSize * 2),
                // FormHeaderWidget(
                //   image: tForgetPasswordImage,
                //   imageColor: tPrimaryColor,
                //   title: tForgetPassword.toUpperCase(),
                //   subtitle: tForgetPasswordSubTitle,
                //   lineHeight: 10,
                //   crossAxisAlignment: CrossAxisAlignment.center,
                //   heightBetween: 30.0,
                //   textAlign: TextAlign.center,
                // ),
                Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image(
                        image: AssetImage(TImages.forgetPasswordImage),
                        // height: size.height * imageHeight,
                        height: 150,
                        color: dark ? TColors.white : TColors.black,
                      ),
                      const SizedBox(height: TSizes.lg),
                      Text(
                        TTexts.forgetPassword.toUpperCase(),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: TSizes.sm),
                      Text(
                        TTexts.forgetMailSubTitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwSections),

                Form(
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                            label: Text(TTexts.phoneNo),
                            hintText: TTexts.phoneNo,
                            prefixIcon: Icon(Icons.local_phone_rounded)),
                      ),
                      const SizedBox(height: TSizes.spaceBtwSections),
                      SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                              onPressed: () {
                                controller.phoneAuthentication("+60123456789");
                                Get.to(() => const OTPScreen());
                              },
                              child: const Text(TTexts.next))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
