import 'package:diabetes_risk_prediction_and_health_management_system/src/utils/extensions/date_time_extension.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../common/loaders/circular_loader.dart';
import '../../../../../common/widgets/images/t_circular_image.dart';
import '../../../../../utils/constants/image_strings.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../authentication/models/user_model.dart';
import '../../../../personalization/controllers/user_controller.dart';

class PostInfoTile extends StatelessWidget {
  const PostInfoTile({
    super.key,
    required this.datePublished,
    required this.userId,
  });

  final DateTime datePublished;
  final String userId;

  @override
  Widget build(BuildContext context) {
    // final controller = UserController.instance;
    final controller = Get.put(UserController());

    return Obx(() {
      if (controller.userCache.containsKey(userId)) {
        final user = controller.userCache[userId]!;
        return _buildPostInfo(context, user);
      } else {
        return FutureBuilder(
          future: controller.fetchUserRecordById(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularLoader(); // 🔄 只有首次加载用户数据时才显示 loading
            }

            if (snapshot.hasError || snapshot.data == null) {
              return const Text(TTexts.commonErrorMessage);
            }

            return _buildPostInfo(context, snapshot.data!);
          },
        );
      }
    });
  }

  Widget _buildPostInfo(BuildContext context, UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              // TODO: 跳转到 Profile 详情页
            },
            child: const TCircularImage(
              image: TImages.user,
              padding: 0,
              width: 50,
              height: 50,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.username,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                datePublished.fromNow(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.more_horiz),
        ],
      ),
    );
  }
}
