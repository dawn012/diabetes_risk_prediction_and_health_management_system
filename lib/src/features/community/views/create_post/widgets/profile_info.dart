import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../common/widgets/images/t_circular_image.dart';
import '../../../../../utils/constants/image_strings.dart';
import '../../../../personalization/controllers/user_controller.dart';

class ProfileInfo extends StatelessWidget {
  const ProfileInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = UserController.instance;

    return Obx(() {
      final user = controller.user.value;

      // if (controller.profileLoading.value) {
      //   return const CircularLoader(); // 还在加载
      // }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TCircularImage(image: TImages.user),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.username,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                'Public',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      );
    });
  }
}
