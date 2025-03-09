import 'package:flutter/material.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/device/device_utility.dart';

class ErrorRetryScreen extends StatelessWidget {
  const ErrorRetryScreen({
    super.key,
    this.message = 'Something went wrong. Please retry.',
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: TDeviceUtils.getScreenHeight() * 0.6,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.refresh, size: 40, color: TColors.darkGrey),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 5, horizontal: 20)),
            onPressed: onRetry, // 只重新加载 PostList
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }
}
