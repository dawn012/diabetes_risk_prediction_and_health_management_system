import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/constants/colors.dart';
import '../dashboard.dart';

class THomeAppBar extends StatelessWidget {
  final String title;

  const THomeAppBar({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return TAppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .headlineMedium!
                .apply(color: TColors.white),
          ),
        ],
      ),
      actions: [
        TNotificationIcon(
          onPressed: () {},
          iconColor: TColors.white,
        ),
      ],
    );
  }
}

