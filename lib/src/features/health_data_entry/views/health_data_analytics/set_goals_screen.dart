import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../../utils/validators/user_profile_validator.dart';
import '../../../personalization/controllers/update_profile_controller.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../controllers/exercise_controller.dart';
import 'connect_exercise_apps_screen.dart';

class SetGoalsScreen extends StatelessWidget {
  const SetGoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final updateProfileController = Get.put(UpdateProfileController());
    final userController = Get.find<UserController>();
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: darkMode ? TColors.dark : TColors.light,
      appBar: TAppBar(
        backgroundColor: TColors.primary,
        title: const Text(
          'Set Goals',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        showBackArrow: true,
        iconTheme: IconThemeData(color: TColors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise Section Header
            Text(
              'Exercise',
              style: TextStyle(
                color: TColors.textSecondary,
                fontSize: TSizes.fontSizeMd,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: TSizes.spaceBtwItems),

            // Daily Steps Goal Card - 使用 UserController 的实时数据
            Obx(() => _buildGoalCard(
              context: context,
              darkMode: darkMode,
              title: 'Daily Steps',
              currentValue: '${userController.user.value.profile.dailyStepsGoal} Steps',
              onTap: () => _showStepsGoalDialog(context, updateProfileController, userController),
            )),

            const SizedBox(height: TSizes.md),

            // Weekly Exercise Time Goal Card - 使用 UserController 的实时数据
            Obx(() => _buildGoalCard(
              context: context,
              darkMode: darkMode,
              title: 'Weekly Exercise Time',
              currentValue: '${userController.user.value.profile.weeklyExerciseTime} Minutes',
              onTap: () => _showExerciseGoalDialog(context, updateProfileController, userController),
            )),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Connect Section Header
            Text(
              'Connect',
              style: TextStyle(
                color: TColors.textSecondary,
                fontSize: TSizes.fontSizeMd,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: TSizes.spaceBtwItems),

            // Connect to Exercise Apps Card
            _buildConnectCard(context: context, darkMode: darkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard({
    required BuildContext context,
    required bool darkMode,
    required String title,
    required String currentValue,
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
          vertical: TSizes.xs,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: darkMode ? TColors.white : TColors.textPrimary,
            fontSize: TSizes.fontSizeMd,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentValue,
              style: TextStyle(
                color: TColors.primary,
                fontSize: TSizes.fontSizeMd,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: TSizes.xs),
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

  Widget _buildConnectCard({
    required BuildContext context,
    required bool darkMode,
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
          vertical: TSizes.xs,
        ),
        title: Text(
          'Connect to Exercise Apps',
          style: TextStyle(
            color: darkMode ? TColors.white : TColors.textPrimary,
            fontSize: TSizes.fontSizeMd,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() {
              final exerciseController = Get.find<ExerciseController>();
              final isConnected = exerciseController.isConnected.value;

              return Text(
                isConnected ? 'Connected' : 'Not Connected',
                style: TextStyle(
                  color: isConnected ? TColors.success : TColors.textSecondary,
                  fontSize: TSizes.fontSizeMd,
                  fontWeight: FontWeight.bold,
                ),
              );
            }),
            const SizedBox(width: TSizes.xs),
            Icon(
              Icons.chevron_right,
              color: darkMode ? TColors.white : TColors.textSecondary,
            ),
          ],
        ),
        onTap: () => Get.to(() => const ConnectExerciseAppsScreen()),
      ),
    );
  }

  void _showStepsGoalDialog(BuildContext context, UpdateProfileController updateProfileController, UserController userController) {
    final darkMode = THelperFunctions.isDarkMode(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _GoalDialog(
          darkMode: darkMode,
          title: 'Daily Steps Goal',
          description: 'Set your daily steps target (1,000 - 50,000 steps)',
          labelText: 'Steps per day',
          suffixText: 'steps',
          initialValue: userController.user.value.profile.dailyStepsGoal.toString(), // 使用当前值
          maxLength: 5,
          validator: TUserProfileValidator.validateDailyStepsGoal,
          onSave: (value) async {
            await updateProfileController.updateSingleGoal(
              'dailyStepsGoal',
              int.parse(value),
            );
          },
        );
      },
    );
  }

  void _showExerciseGoalDialog(BuildContext context, UpdateProfileController updateProfileController, UserController userController) {
    final darkMode = THelperFunctions.isDarkMode(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _GoalDialog(
          darkMode: darkMode,
          title: 'Weekly Exercise Goal',
          description: 'Set your weekly exercise time target (0 - 1,000 minutes)',
          labelText: 'Minutes per week',
          suffixText: 'min',
          initialValue: userController.user.value.profile.weeklyExerciseTime.toString(), // 使用当前值
          maxLength: 4,
          validator: TUserProfileValidator.validateWeeklyExerciseTime,
          onSave: (value) async {
            await updateProfileController.updateSingleGoal(
              'weeklyExerciseTime',
              int.parse(value),
            );
          },
        );
      },
    );
  }
}

// 独立的 StatefulWidget 用于 Dialog
class _GoalDialog extends StatefulWidget {
  final bool darkMode;
  final String title;
  final String description;
  final String labelText;
  final String suffixText;
  final String initialValue;
  final int maxLength;
  final String? Function(String?)? validator;
  final Future<void> Function(String value) onSave;

  const _GoalDialog({
    required this.darkMode,
    required this.title,
    required this.description,
    required this.labelText,
    required this.suffixText,
    required this.initialValue,
    required this.maxLength,
    required this.validator,
    required this.onSave,
  });

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  late final TextEditingController _controller;
  late final GlobalKey<FormState> _formKey;
  bool _isSaving = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _formKey = GlobalKey<FormState>();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSaving,
      child: AlertDialog(
        backgroundColor: widget.darkMode ? TColors.darkContainer : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: widget.darkMode ? TColors.white : TColors.textPrimary,
            fontSize: TSizes.fontSizeLg,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.description,
                  style: TextStyle(
                    color: TColors.textSecondary,
                    fontSize: TSizes.fontSizeSm,
                  ),
                ),
                const SizedBox(height: TSizes.md),
                TextFormField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.maxLength),
                  ],
                  validator: widget.validator,
                  enabled: !_isSaving,
                  style: TextStyle(
                    color: widget.darkMode ? TColors.white : TColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: widget.labelText,
                    labelStyle: TextStyle(color: TColors.textSecondary),
                    suffixText: widget.suffixText,
                    suffixStyle: TextStyle(color: TColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
                      borderSide: BorderSide(color: TColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: TColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TSizes.buttonRadius),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      if (_isDisposed) return;

      setState(() => _isSaving = true);

      try {
        await widget.onSave(_controller.text);

        // 确保在关闭前等待一帧，避免过快关闭导致问题
        if (!_isDisposed && mounted) {
          await Future.delayed(const Duration(milliseconds: 100));
        }

        if (!_isDisposed && mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (!_isDisposed && mounted) {
          setState(() => _isSaving = false);
        }
        // Error handling is done in controller
      }
    }
  }
}