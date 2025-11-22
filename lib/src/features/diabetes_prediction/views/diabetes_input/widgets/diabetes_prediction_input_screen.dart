import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../diabetes_prediction_overview_screen.dart';

/// Navigation mode for input screens
enum NavigationMode {
  flow, // Sequential flow (start new)
  edit, // Edit from overview
}

/// Base screen wrapper for diabetes prediction input screens
class DiabetesPredictionInputScreen extends StatelessWidget {
  final String title;
  final double progressValue;
  final Widget content;
  final bool showBackButton;
  final bool showCloseButton;
  final VoidCallback? onBack;
  final VoidCallback? onClose;
  final VoidCallback? onContinue;
  final bool canProceed;
  final bool isLoading;
  final String continueButtonText;
  final bool showSyncButton;
  final VoidCallback? onSync;
  final NavigationMode navigationMode;
  final VoidCallback? onSave; // For edit mode

  // 强制显示 Process Photos 按钮
  final bool forceProcessButton;
  final VoidCallback? onProcess;

  const DiabetesPredictionInputScreen({
    super.key,
    required this.title,
    required this.progressValue,
    required this.content,
    this.showBackButton = true,
    this.showCloseButton = false,
    this.onBack,
    this.onClose,
    this.onContinue,
    this.canProceed = false,
    this.isLoading = false,
    this.continueButtonText = 'Continue',
    this.showSyncButton = false,
    this.onSync,
    this.navigationMode = NavigationMode.flow,
    this.onSave,
    this.forceProcessButton = false,
    this.onProcess,
  });

  /// Handle close - slide down to Overview
  void _handleClose(bool darkMode) {
    Get.off(
          () => DiabetesPredictionOverviewScreen(),
      transition: Transition.upToDown,
      duration: Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: darkMode ? TColors.black : TColors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: null,
        title: Text(
          'Diabetes Prediction',
          style: TextStyle(
            color: darkMode ? TColors.white : TColors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (showSyncButton && onSync != null)
            IconButton(
              icon: Icon(
                Icons.sync,
                color: TColors.primary,
              ),
              onPressed: onSync,
              tooltip: 'Sync from health logs',
            ),
          if (showCloseButton)
            IconButton(
              icon: Icon(
                Icons.close,
                color: darkMode ? TColors.white : TColors.black,
              ),
              onPressed: onClose ?? () => _handleClose(darkMode),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Fixed progress bar and content area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Progress indicator
                    Container(
                      width: double.infinity,
                      height: 6,
                      decoration: BoxDecoration(
                        color: darkMode ? TColors.darkerGrey : TColors.grey,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progressValue,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [TColors.primary, TColors.accent],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Dynamic content area
                    Expanded(child: content),
                  ],
                ),
              ),
            ),

            // Fixed bottom navigation
            _buildBottomNavigation(darkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(bool darkMode) {
    // 新增：如果强制显示 Process 按钮，优先处理
    if (forceProcessButton) {
      return Container(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            if (showBackButton) ...[
              Expanded(
                child: Container(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: onBack ?? () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TColors.primary,
                      side: BorderSide(color: TColors.primary, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],

            Expanded(
              flex: showBackButton ? 2 : 1,
              child: Container(
                height: 56,
                child: ElevatedButton(
                  onPressed: canProceed && !isLoading ? onProcess : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary,
                    disabledBackgroundColor: darkMode
                        ? TColors.darkerGrey
                        : TColors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(TColors.white),
                    ),
                  )
                      : Text(
                    'Process Photos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: canProceed
                          ? TColors.white
                          : darkMode
                          ? TColors.darkGrey
                          : TColors.darkerGrey,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 原有的 Edit mode 逻辑
    if (navigationMode == NavigationMode.edit) {
      return Container(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          height: 56,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canProceed && !isLoading ? (onSave ?? onContinue) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: TColors.primary,
              disabledBackgroundColor: darkMode
                  ? TColors.darkerGrey
                  : TColors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(TColors.white),
              ),
            )
                : Text(
              continueButtonText, // 这里会显示 'Save' 或 'Process Photos'
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: canProceed
                    ? TColors.white
                    : darkMode
                    ? TColors.darkGrey
                    : TColors.darkerGrey,
              ),
            ),
          ),
        ),
      );
    }

    // 原有的 Flow mode 逻辑保持不变
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          if (showBackButton) ...[
            Expanded(
              child: Container(
                height: 56,
                child: OutlinedButton(
                  onPressed: onBack ?? () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TColors.primary,
                    side: BorderSide(color: TColors.primary, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],

          Expanded(
            flex: showBackButton ? 2 : 1,
            child: Container(
              height: 56,
              child: ElevatedButton(
                onPressed: canProceed && !isLoading ? onContinue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.primary,
                  disabledBackgroundColor: darkMode
                      ? TColors.darkerGrey
                      : TColors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(TColors.white),
                  ),
                )
                    : Text(
                  continueButtonText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: canProceed
                        ? TColors.white
                        : darkMode
                        ? TColors.darkGrey
                        : TColors.darkerGrey,
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

/// Reusable section header component
class SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String questionNumber;
  final IconData icon;
  final Color iconColor;

  const SectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.questionNumber,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [iconColor.withOpacity(0.1), iconColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: TColors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  questionNumber,
                  style: TextStyle(
                    fontSize: 14,
                    color: iconColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: darkMode ? TColors.white : TColors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 16,
                    color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable input container
class InputContainer extends StatelessWidget {
  final Widget child;
  final bool darkMode;

  const InputContainer({
    super.key,
    required this.child,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: darkMode ? TColors.darkerGrey.withOpacity(0.3) : TColors.softGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: darkMode ? TColors.darkerGrey : TColors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

/// Custom slider with consistent styling
class CustomSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final Color activeColor;
  final bool darkMode;
  final double thumbRadius;
  final double trackHeight;

  const CustomSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
    required this.activeColor,
    required this.darkMode,
    this.thumbRadius = 12,
    this.trackHeight = 6,
  });

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: activeColor,
        inactiveTrackColor: darkMode ? TColors.darkerGrey : TColors.grey,
        thumbColor: activeColor,
        overlayColor: activeColor.withOpacity(0.2),
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: thumbRadius),
        overlayShape: RoundSliderOverlayShape(overlayRadius: thumbRadius + 8),
        trackHeight: trackHeight,
      ),
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }
}

/// Quick select button component
class QuickSelectButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedColor;
  final bool darkMode;

  const QuickSelectButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.selectedColor,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withOpacity(0.1)
              : darkMode ? TColors.darkerGrey.withOpacity(0.3) : TColors.grey.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? selectedColor
                : darkMode ? TColors.white : TColors.black,
          ),
        ),
      ),
    );
  }
}

/// Range indicator for sliders
class RangeIndicators extends StatelessWidget {
  final List<String> labels;
  final List<Color>? colors;
  final bool darkMode;
  final bool useWrap; // 是否使用换行布局

  const RangeIndicators({
    super.key,
    required this.labels,
    this.colors,
    required this.darkMode,
    this.useWrap = false, // 默认不使用换行
  });

  @override
  Widget build(BuildContext context) {
    // 如果标签较长或数量多，使用换行布局
    final shouldWrap = useWrap || _shouldUseWrapLayout();

    if (shouldWrap) {
      return _buildWrapLayout();
    } else {
      return _buildRowLayout();
    }
  }

  /// 判断是否应该使用换行布局
  bool _shouldUseWrapLayout() {
    // 检查是否有长标签
    final hasLongLabels = labels.any((label) => label.length > 8);
    // 检查标签数量
    final tooManyLabels = labels.length > 3;

    return hasLongLabels || tooManyLabels;
  }

  /// 行布局 - 适合短标签
  Widget _buildRowLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: List.generate(labels.length, (index) {
          return Expanded(
            child: Center( // 保证Text居中
              child: Text(
                labels[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: colors != null ? FontWeight.w600 : FontWeight.normal,
                  color: colors != null
                      ? colors![index]
                      : darkMode ? TColors.darkGrey : TColors.darkerGrey,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }),
      ),
    );
  }

  /// 换行布局 - 适合长标签
  Widget _buildWrapLayout() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      runAlignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: List.generate(labels.length, (index) {
        return _buildLabelItem(index);
      }),
    );
  }

  /// 构建单个标签项目
  Widget _buildLabelItem(int index) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: 120, // 限制最大宽度
      ),
      child: Text(
        labels[index],
        style: TextStyle(
          fontSize: 12,
          fontWeight: colors != null ? FontWeight.w600 : FontWeight.normal,
          color: colors != null
              ? colors![index]
              : darkMode ? TColors.darkGrey : TColors.darkerGrey,
        ),
        textAlign: TextAlign.center,
        maxLines: 2, // 允许最多两行
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}