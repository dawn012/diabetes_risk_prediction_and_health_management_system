import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../forget_password_mail/forget_password.dart';
import '../forget_password_phone/forget_password_phone_screen.dart';
import 'bottom_sheet_button_widget.dart';

class ForgetPasswordScreen {
  static Future<dynamic> buildShowModalBottomSheet(BuildContext context) {

    return showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      builder: (context) => Container(
        padding: const EdgeInsets.all(TSizes.defaultSize),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(TTexts.forgetPasswordTitle, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: TSizes.sm,),
            Text(TTexts.forgetPasswordSubTitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: TSizes.defaultSize),

            ForgetPasswordBtnWidget(
              onTap: () {
                Navigator.pop(context);
                Get.to(() => ForgetPasswordMailScreen());
              },
              title: TTexts.email,
              subTitle: TTexts.resetViaEMail,
              btnIcon: Icons.mail_outline_rounded,
            ),
            const SizedBox(height: TSizes.defaultSize - 10.0),

            ForgetPasswordBtnWidget(
              onTap: () {
                Navigator.pop(context);
                Get.to(() => const ForgetPasswordPhoneScreen());
              },
              title: TTexts.phoneNo,
              subTitle: TTexts.resetViaPhone,
              btnIcon: Icons.mobile_friendly_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
