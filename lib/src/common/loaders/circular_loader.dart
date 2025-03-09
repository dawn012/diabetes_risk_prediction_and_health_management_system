import 'package:flutter/material.dart';

import '../../utils/device/device_utility.dart';

class CircularLoader extends StatelessWidget {
  const CircularLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: TDeviceUtils.getScreenHeight() * 0.6,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
