import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../controllers/otp_controller.dart';

class OTPScreen extends StatelessWidget {
  const OTPScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var otpController = Get.put(OTPController());
    var otp;

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(TSizes.defaultSize),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              TTexts.otpTitle,
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 80.0, height: 0),
            ),
            Text(TTexts.otpSubTitle.toUpperCase(), style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            )),
            const SizedBox(height: TSizes.defaultSize + 10.0),

            const Text("${TTexts.otpMessage} support@codingwitht.com", textAlign: TextAlign.center),
            const SizedBox(height: TSizes.defaultSize - 10.0),

            OtpTextField(
                mainAxisAlignment: MainAxisAlignment.center,
                numberOfFields: 6,
                fillColor: Colors.black.withOpacity(0.1),
                filled: true,
                onSubmit: (code) {
                  otp = code;
                  otpController.verifyOTP(otp);
                }),
            const SizedBox(height: TSizes.defaultSize - 10.0),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: () {
                otpController.verifyOTP(otp);
              }, child: const Text(TTexts.next)),
            ),
          ],
        ),
      ),
    );
  }
}
