import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../controllers/splash_screen_controller.dart';

class SplashScreen extends StatelessWidget {
  SplashScreen({Key? key}) : super(key: key);

  // 全部地方都使用同一个实例
  // 可以在任何地方通过 Get.find<SplashScreenController>() 来访问这个实例
  final splashController = Get.put(SplashScreenController());

  @override
  Widget build(BuildContext context) {
    splashController.startAnimation();

    return Scaffold(
      body: Stack(
        children: [
          // Obx会监听splashController中的状态变化，当其中的animate状态发生变化时，Obx内的Widget会自动重建
          Obx(
            () => AnimatedPositioned(
              duration: const Duration(milliseconds: 1600),
              top: splashController.animate.value ? -10 : -40,
              left: splashController.animate.value ? -30 : -60,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 1600),
                opacity: splashController.animate.value ? 1 : 0,
                child: const Image(
                  image: AssetImage(TImages.splashTopIcon),
                  width: 150,
                  height: 150,
                ),
              ),
            ),
          ),
          Obx(
            () => AnimatedPositioned(
              duration: const Duration(milliseconds: 2000),
              top: 115,
              left: splashController.animate.value ? TSizes.defaultSize : -80,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 2000),
                opacity: splashController.animate.value ? 1 : 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TTexts.appName,
                      style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    Text(
                      TTexts.appTagLine,
                      style: Theme.of(context).textTheme.headlineLarge,
                    )
                  ],
                ),
              ),
            ),
          ),
          Obx(
            () => AnimatedPositioned(
              duration: const Duration(milliseconds: 2400),
              bottom: splashController.animate.value ? 50 : -30,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 2400),
                opacity: splashController.animate.value ? 1 : 0,
                child: const Image(
                  image: AssetImage(TImages.splashImage),
                  width: 400,
                  height: 400,
                ),
              ),
            ),
          ),
          Obx(
            () => AnimatedPositioned(
              duration: const Duration(milliseconds: 2400),
              bottom: splashController.animate.value ? 30 : -30,
              right: TSizes.defaultSize,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 2000),
                opacity: splashController.animate.value ? 1 : 0,
                child: Container(
                  width: TSizes.defaultSize,
                  height: TSizes.defaultSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: TColors.primary,
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
