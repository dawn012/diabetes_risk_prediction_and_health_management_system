import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/loaders/loaders.dart';
import '../../../../services/step_tracking_service.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';

class ConnectExerciseAppsScreen extends StatelessWidget {
  const ConnectExerciseAppsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);
    final stepTrackingService = StepTrackingService.instance;

    return Scaffold(
      backgroundColor: darkMode ? TColors.dark : TColors.light,
      appBar: AppBar(
        backgroundColor: TColors.primary,
        title: const Text(
          'Connect to Exercise Apps',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise Data Section
            Text(
              'Exercise Data',
              style: TextStyle(
                color: TColors.textSecondary,
                fontSize: TSizes.fontSizeMd,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: TSizes.spaceBtwItems),

            // Google Fit
            _buildAppCard(
              darkMode: darkMode,
              iconPath: 'assets/icons/google_fit.png',
              appName: 'Google Fit',
              isConnected: false,
              onTap: () => _connectApp('Google Fit'),
            ),

            const SizedBox(height: TSizes.md),

            // This Phone
            Obx(() => _buildAppCard(
              darkMode: darkMode,
              iconWidget: Icon(
                Icons.phone_android,
                color: TColors.primary,
                size: 40,
              ),
              appName: 'This Phone',
              isConnected: stepTrackingService.isConnected.value,
              onTap: () async {
                final result = await Get.to(() => const ThisPhoneScreen());
                // No need to handle result, service handles it
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildAppCard({
    required bool darkMode,
    String? iconPath,
    Widget? iconWidget,
    required String appName,
    required bool isConnected,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: darkMode ? TColors.darkContainer : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TSizes.md,
          vertical: TSizes.sm,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: TColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(TSizes.cardRadiusSm),
          ),
          child: iconWidget ??
              (iconPath != null
                  ? Image.asset(iconPath, width: 32, height: 32)
                  : Icon(Icons.apps, color: TColors.primary, size: 32)),
        ),
        title: Text(
          appName,
          style: TextStyle(
            color: darkMode ? TColors.white : TColors.textPrimary,
            fontSize: TSizes.fontSizeMd,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isConnected) ...[
              Text(
                'Connected',
                style: TextStyle(
                  color: TColors.success,
                  fontSize: TSizes.fontSizeMd,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: TSizes.xs),
            ],
            Icon(
              Icons.chevron_right,
              color: darkMode ? TColors.white : TColors.textSecondary,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  void _connectApp(String appName) {
    TLoaders.modernSnackBar(
        title: 'Connecting...', message: 'Attempting to connect to $appName');

    Future.delayed(const Duration(seconds: 2), () {
      TLoaders.successSnackBar(
          title: 'Connected!', message: '$appName connected successfully');
    });
  }
}

class ThisPhoneScreen extends StatelessWidget {
  const ThisPhoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);
    final stepTrackingService = StepTrackingService.instance;

    return Scaffold(
        backgroundColor: darkMode ? TColors.dark : TColors.light,
        appBar: AppBar(
          backgroundColor: TColors.primary,
          title: const Text(
            'This Phone',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ),
      body: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          children: [
            // Icon and connection indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(TSizes.md),
                  decoration: BoxDecoration(
                    color: TColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                  ),
                  child: Icon(
                    Icons.directions_walk,
                    color: TColors.primary,
                    size: 40,
                  ),
                ),
                const SizedBox(width: TSizes.lg),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: TSizes.md, vertical: TSizes.sm),
                  child: Row(
                    children: [
                      Icon(Icons.sync_alt,
                          color: darkMode ? TColors.white : TColors.textPrimary),
                    ],
                  ),
                ),
                const SizedBox(width: TSizes.lg),
                Container(
                  padding: const EdgeInsets.all(TSizes.md),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                  ),
                  child: Icon(
                    Icons.phone_android,
                    color: Colors.green,
                    size: 40,
                  ),
                ),
              ],
            ),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Connection Status
            Obx(() => Container(
              padding: const EdgeInsets.all(TSizes.md),
              decoration: BoxDecoration(
                color: stepTrackingService.isConnected.value
                    ? TColors.success.withOpacity(0.1)
                    : TColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                border: Border.all(
                  color: stepTrackingService.isConnected.value
                      ? TColors.success
                      : TColors.warning,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    stepTrackingService.isConnected.value
                        ? Icons.check_circle
                        : Icons.info_outline,
                    color: stepTrackingService.isConnected.value
                        ? TColors.success
                        : TColors.warning,
                  ),
                  const SizedBox(width: TSizes.md),
                  Expanded(
                    child: Text(
                      stepTrackingService.isConnected.value
                          ? 'Currently tracking your steps'
                          : 'Step tracking is disconnected',
                      style: TextStyle(
                        color: darkMode ? TColors.white : TColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )),

            const SizedBox(height: TSizes.spaceBtwItems),

            // Description
            Text(
              'You can use your mobile phone to track your daily steps. Enable step tracking to automatically retrieve your phone\'s steps data.',
              style: TextStyle(
                color: darkMode ? TColors.white : TColors.textPrimary,
                fontSize: TSizes.fontSizeMd,
                height: 1.6,
              ),
              textAlign: TextAlign.left,
            ),

            const SizedBox(height: TSizes.spaceBtwItems),

            Text(
              'After you connect your phone, the app can analyze your steps data and display steps-related statistics and charts.',
              style: TextStyle(
                color: darkMode ? TColors.white : TColors.textPrimary,
                fontSize: TSizes.fontSizeMd,
                height: 1.6,
              ),
              textAlign: TextAlign.left,
            ),

            const Spacer(),

            // Connect/Disconnect button - 修改这里
            Obx(() {
              final isConnected = stepTrackingService.isConnected.value;

              return SizedBox(
                width: double.infinity,
                child: isConnected
                    ? OutlinedButton(
                  onPressed: () => _showDisconnectDialog(
                      context, stepTrackingService),
                  style: OutlinedButton.styleFrom(
                    padding:
                    const EdgeInsets.symmetric(vertical: TSizes.md),
                    side: BorderSide(color: TColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(TSizes.borderRadiusLg),
                    ),
                  ),
                  child: Text(
                    'Disconnect This Phone',
                    style: TextStyle(
                      color: TColors.error,
                      fontSize: TSizes.fontSizeMd,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
                    : ElevatedButton(
                  onPressed: () =>
                      _connectPhone(context, stepTrackingService),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary,
                    padding:
                    const EdgeInsets.symmetric(vertical: TSizes.md),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(TSizes.borderRadiusLg),
                    ),
                  ),
                  child: Text(
                    'Connect This Phone',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: TSizes.fontSizeMd,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _connectPhone(
      BuildContext context, StepTrackingService stepTrackingService) async {
    // 显示加载提示
    TLoaders.modernSnackBar(
      title: 'Connecting...',
      message: 'Setting up step tracking',
    );

    // 调用 startTracking
    await stepTrackingService.startTracking();

    // 检查是否成功连接
    if (stepTrackingService.isConnected.value) {
      TLoaders.successSnackBar(
        title: 'Connected!',
        message: 'Step tracking is now active',
      );
    }
  }

  void _showDisconnectDialog(
      BuildContext context, StepTrackingService stepTrackingService) {
    final darkMode = THelperFunctions.isDarkMode(context);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: darkMode ? TColors.darkContainer : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
          ),
          title: Text(
            'Disconnect Phone',
            style: TextStyle(
              color: darkMode ? TColors.white : TColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to disconnect this phone? You will no longer receive step data from your device.',
            style: TextStyle(
              color: darkMode ? TColors.white : TColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: TColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                stepTrackingService.stopTracking();
                TLoaders.successSnackBar(
                  title: 'Disconnected',
                  message:
                  'Phone disconnected successfully. Step tracking has been stopped.',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
                ),
              ),
              child: const Text(
                'Disconnect',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}