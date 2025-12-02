import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../common/loaders/loaders.dart';
import '../common/widgets/dialogs/dialog.dart';
import '../common/widgets/tutorial_overlay/tutorial_overlay_widget.dart';
import '../features/health_data_entry/views/health_data_entry/health_data_entry_screen.dart';
import '../features/personalization/controllers/user_controller.dart';
import '../utils/constants/colors.dart';

/// 教学流程步骤
enum TutorialStep {
  notStarted,                // 未开始
  dashboardWelcome,          // Dashboard 欢迎
  dashboardAddButton,        // Dashboard 添加按钮
  dataEntryIntro,            // 数据录入 - 介绍时间和周期选择
  dataEntryGlucose,          // 数据录入 - 血糖输入
  dataEntrySave,             // 数据录入 - 保存
  dashboardGlucoseCard,      // Dashboard 血糖卡片
  analyticsTimeRange,        // Analytics 时间范围选择
  analyticsLastRecord,       // Analytics 最后记录标签
  analyticsStatistics,       // Analytics 统计表
  analyticsDistribution,     // Analytics 分布图
  analyticsTrends,           // Analytics 趋势图
  analyticsClickTotal,       // Analytics - 点击Total查看记录
  analyticsDeleteRecord,     // Analytics - 删除记录教学
  completed,                 // 教学完成
}

/// 统一的教学流程管理器
class TutorialFlowManager extends GetxController {
  static TutorialFlowManager get instance => Get.find();

  final _storage = GetStorage();
  static const String _tutorialCompletedKey = 'tutorial_completed';
  static const String _currentStepKey = 'current_tutorial_step';

  // 教学状态
  final Rx<TutorialStep> currentStep = TutorialStep.notStarted.obs;
  final RxBool isTutorialActive = false.obs;
  final RxBool showOverlay = false.obs;

  // 所有教学步骤的 GlobalKey
  final welcomeKey = GlobalKey();
  final addButtonKey = GlobalKey();
  final timeSelectionKey = GlobalKey();
  final periodSelectionKey = GlobalKey();
  final glucoseInputKey = GlobalKey();
  final dataEntrySaveKey = GlobalKey();
  final glucoseCardKey = GlobalKey();
  final timeRangeKey = GlobalKey();
  final lastRecordLabelKey = GlobalKey();
  final analyticsStatisticsKey = GlobalKey();
  final analyticsDistributionKey = GlobalKey();
  final analyticsTrendsKey = GlobalKey();
  final analyticsClickTotalKey = GlobalKey();
  final dataListRecordKey = GlobalKey();

  // Overlay entry
  OverlayEntry? _overlayEntry;
  final RxBool needsResume = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadTutorialState();
  }

  String _userKey(String baseKey) {
    final uid = UserController.instance.user.value.userId;
    if (uid.isEmpty) return baseKey; // 未登录时共用
    return '${uid}_$baseKey';        // 例：uid123_tutorial_completed
  }

  void _loadTutorialState() {
    final completed = _storage.read(_userKey(_tutorialCompletedKey)) ?? false;
    print('Tutorial completed for this user? $completed');

    final savedStepIndex = _storage.read(_userKey(_currentStepKey));
    print('Saved step index for this user: $savedStepIndex');

    if (completed) {
      currentStep.value = TutorialStep.completed;
    } else if (savedStepIndex != null) {
      currentStep.value = TutorialStep.values[savedStepIndex];
      if (currentStep.value != TutorialStep.notStarted &&
          currentStep.value != TutorialStep.completed) {
        isTutorialActive.value = true;
      }
    } else {
      currentStep.value = TutorialStep.notStarted;
    }
  }

  /// 检查是否已完成教学
  bool get hasCompletedTutorial {
    return currentStep.value == TutorialStep.completed;
  }

  /// 开始教学流程
  void startTutorial(BuildContext context) {
    if (hasCompletedTutorial) {
      print('Tutorial already completed');
      return;
    }

    isTutorialActive.value = true;
    currentStep.value = TutorialStep.dashboardWelcome;
    saveCurrentStep();

    // 延迟显示第一个教学
    Future.delayed(const Duration(milliseconds: 500), () {
      if (context.mounted) {
        showCurrentStepOverlay(context);
      }
    });
  }

  /// 显示当前步骤的 overlay
  void showCurrentStepOverlay(BuildContext context) {
    if (!isTutorialActive.value || !context.mounted) {
      print('⚠️ Cannot show overlay: tutorial not active or context not mounted');
      return;
    }

    // 移除现有的 overlay
    hideOverlay();

    print('🎬 Showing overlay for step: $currentStep');

    // 🚨 使用更可靠的方式显示 overlay
    _showOverlayForCurrentStepImmediately(context);
  }

  void _showOverlayForCurrentStepImmediately(BuildContext context) {
    if (!context.mounted) return;

    // 先尝试立即显示
    _tryShowOverlay(context);

    // 如果失败，延迟重试
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      _tryShowOverlay(context);
    });
  }

  void _tryShowOverlay(BuildContext context) {
    try {
      _showOverlayForCurrentStep(context);
    } catch (e) {
      print('❌ Error showing overlay: $e');
      // 延迟重试
      Future.delayed(const Duration(milliseconds: 100), () {
        if (context.mounted) {
          _showOverlayForCurrentStep(context);
        }
      });
    }
  }

  void _showOverlayForCurrentStep(BuildContext context) {
    if (_overlayEntry != null && showOverlay.value) {
      print('⚠️ Overlay already exists, skipping...');
      return;
    }

    // 清理旧的 overlay entry（以防万一）
    _overlayEntry = null;

    GlobalKey? targetKey;
    String title = '';
    String description = '';
    bool showNextButton = true;
    bool showCompleteButton = false;
    bool allowInteraction = false;
    TooltipPosition position = TooltipPosition.bottom;
    VoidCallback? onNext;
    VoidCallback? onComplete;

    switch (currentStep.value) {
      case TutorialStep.dashboardWelcome:
        targetKey = welcomeKey;
        title = '👋 Welcome to Your Dashboard!';
        description = 'This is your main control center. Here you can view your daily health status and track various health metrics.';
        position = TooltipPosition.bottom;
        onNext = () => _advanceToNextStep(context);
        break;

      case TutorialStep.dashboardAddButton:
        targetKey = addButtonKey;
        title = '➕ Add Health Records';
        description = 'Tap this button to add your first blood glucose record.';
        position = TooltipPosition.top;
        onNext = () {
          hideOverlay();
          // 直接导航到数据录入页面
          _navigateToDataEntry(context);
        };
        break;

      case TutorialStep.dataEntryIntro:
        targetKey = timeSelectionKey;
        title = '⏰ Set Time and Period';
        description = 'You can select the date/time and physiological period (e.g., Before Meal, After Meal) for your record.';
        position = TooltipPosition.bottom;
        onNext = () => _advanceToNextStep(context);
        break;

      case TutorialStep.dataEntryGlucose:
        targetKey = glucoseInputKey;
        title = '🩸 Enter Your Blood Glucose';
        description = 'Type your blood glucose reading here. After entering, click "Complete" to continue.';
        position = TooltipPosition.bottom;
        allowInteraction = true;
        showNextButton = false;
        showCompleteButton = true;
        onComplete = () => _advanceToNextStep(context);
        break;

      case TutorialStep.dataEntrySave:
        targetKey = dataEntrySaveKey;
        title = '💾 Save Your Record';
        description = 'Great! Now tap "Save" to store your glucose reading.';
        position = TooltipPosition.top;
        showNextButton = false;
        allowInteraction = true;
        break;

      case TutorialStep.dashboardGlucoseCard:
        targetKey = glucoseCardKey;
        title = '📊 View Your Glucose Data';
        description = 'Great! Now you can see your glucose data here. Tap on this card to view detailed analytics.';
        position = TooltipPosition.top;
        showNextButton = false;
        allowInteraction = true;
        break;

      case TutorialStep.analyticsTimeRange:
        targetKey = timeRangeKey;
        title = '📅 Time Range Filter';
        description = 'You can filter data by different time periods: Past 7 Days, Past 14 Days, or set a Custom Range.';
        position = TooltipPosition.bottom;
        onNext = () => _advanceToNextStep(context);
        break;

      case TutorialStep.analyticsLastRecord:
        targetKey = lastRecordLabelKey;
        title = '🕐 Last Record Info';
        description = 'This shows when your last record was logged, helping you track your recording frequency.';
        position = TooltipPosition.bottom;
        onNext = () => _advanceToNextStep(context);
        break;

      case TutorialStep.analyticsStatistics:
        targetKey = analyticsStatisticsKey;
        title = '📊 Interactive Statistics';
        description = 'Tap on "Highest" to see your highest glucose records, "Lowest" for lowest, and "Average" to see all records.';
        position = TooltipPosition.bottom;
        onNext = () => _advanceToNextStep(context);
        break;

      case TutorialStep.analyticsDistribution:
        targetKey = analyticsDistributionKey;
        title = '🥧 Distribution Chart';
        description = 'This pie chart shows how your glucose levels are distributed across different ranges (Normal, High, Low).';
        position = TooltipPosition.top;
        onNext = () => _advanceToNextStep(context);
        break;

      case TutorialStep.analyticsTrends:
        targetKey = analyticsTrendsKey;
        title = '📈 Trends Over Time';
        description = 'This chart shows your glucose trends. You can filter by periods like "Before Meal", "After Meal", etc.';
        position = TooltipPosition.top;
        onNext = () => _advanceToNextStep(context);
        break;

      case TutorialStep.analyticsClickTotal:
        targetKey = analyticsClickTotalKey;
        title = '📋 View All Records';
        description = 'Now tap on "Total" to view all your glucose records in a list. This is where you can manage your data.';
        position = TooltipPosition.top;
        showNextButton = false;
        allowInteraction = true; // 允许用户交互
        break;

      case TutorialStep.analyticsDeleteRecord:
        targetKey = dataListRecordKey;
        title = '🗑️ Delete Record';
        description = 'Tap the delete button to remove this test record. This helps you learn how to manage your data.';
        position = TooltipPosition.bottom;
        showNextButton = false;
        allowInteraction = true;
        break;

      default:
        return;
    }

    if (targetKey == null) return;

    // 创建 overlay
    _overlayEntry = OverlayEntry(
      builder: (context) => TutorialOverlay(
        targetKey: targetKey!,
        title: title,
        description: description,
        tooltipPosition: position,
        showNextButton: showNextButton,
        showCompleteButton: showCompleteButton,
        allowInteraction: allowInteraction,
        onNext: onNext,
        onComplete: onComplete,
        onSkip: () => _showSkipConfirmation(context),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    showOverlay.value = true;
  }

  /// 隐藏 overlay
  Future<void> hideOverlay() async {
    if (_overlayEntry != null) {
      try {
        _overlayEntry?.remove();
        _overlayEntry?.dispose(); // 添加 dispose
        _overlayEntry = null;
      } catch (e) {
        print('⚠️ Error removing overlay entry: $e');
      }
    }
    showOverlay.value = false;

    // 增加延迟时间，确保 overlay 完全移除
    await Future.delayed(const Duration(milliseconds: 150));
  }

  /// 推进到下一步
  void _advanceToNextStep(BuildContext context) {
    print('🔄 Advancing to next step from: $currentStep');

    // 🚨 先隐藏当前 overlay，等待完成后再推进
    hideOverlay().then((_) {
      _proceedToNextStepAfterHide(context);
    });
  }

  /// 在 overlay 隐藏后继续推进到下一步
  void _proceedToNextStepAfterHide(BuildContext context) {
    final nextStep = _getNextStep(currentStep.value);
    if (nextStep != null) {
      currentStep.value = nextStep;
      saveCurrentStep();

      print('🔄 Step advanced to: $nextStep');

      // 🚨 使用更长的延迟确保页面稳定
      Future.delayed(const Duration(milliseconds: 200), () {
        if (context.mounted) {
          showCurrentStepOverlay(context);
        } else {
          print('⚠️ Context not mounted when trying to show next step');
        }
      });
    } else {
      completeTutorial();
    }
  }

  /// 导航到数据录入页面
  void _navigateToDataEntry(BuildContext context) {
    // 推进到数据录入介绍步骤
    currentStep.value = TutorialStep.dataEntryIntro;
    saveCurrentStep();

    // 导航到数据录入页面
    Get.to(() => HealthDataEntryScreen(
      initialSections: ['Blood Glucose'],
    ));
  }

  /// 完成整个教学
  void completeTutorial({bool showMessage=true}) {
    hideOverlay();
    isTutorialActive.value = false;
    currentStep.value = TutorialStep.completed;
    _storage.write(_userKey(_tutorialCompletedKey), true);
    _storage.remove(_userKey(_currentStepKey));

    if (showMessage) {
      TLoaders.successSnackBar(
        title: '🎉 Tutorial Complete!',
        message: 'You\'re ready to start tracking your health!',
      );
    }
  }

  /// 重置教学状态
  void resetTutorial() {
    hideOverlay();
    _storage.remove(_userKey(_tutorialCompletedKey));
    _storage.remove(_userKey(_currentStepKey));
    currentStep.value = TutorialStep.notStarted;
    isTutorialActive.value = false;
  }

  /// 获取下一步骤
  TutorialStep? _getNextStep(TutorialStep current) {
    switch (current) {
      case TutorialStep.dashboardWelcome:
        return TutorialStep.dashboardAddButton;
      case TutorialStep.dashboardAddButton:
        return TutorialStep.dataEntryIntro;
      case TutorialStep.dataEntryIntro:
        return TutorialStep.dataEntryGlucose;
      case TutorialStep.dataEntryGlucose:
        return TutorialStep.dataEntrySave;
      case TutorialStep.dataEntrySave:
        return TutorialStep.dashboardGlucoseCard;
      case TutorialStep.dashboardGlucoseCard:
        return TutorialStep.analyticsTimeRange;
      case TutorialStep.analyticsTimeRange:
        return TutorialStep.analyticsLastRecord;
      case TutorialStep.analyticsLastRecord:
        return TutorialStep.analyticsStatistics;
      case TutorialStep.analyticsStatistics:
        return TutorialStep.analyticsDistribution;
      case TutorialStep.analyticsDistribution:
        return TutorialStep.analyticsTrends;
      case TutorialStep.analyticsTrends:
        return TutorialStep.analyticsClickTotal;
      case TutorialStep.analyticsClickTotal:
        return TutorialStep.analyticsDeleteRecord;
      case TutorialStep.analyticsDeleteRecord:
        return null; // 教学完成
      default:
        return null;
    }
  }

  void saveCurrentStep() {
    _storage.write(_userKey(_currentStepKey), currentStep.value.index);
  }

  /// 检查是否应该显示指定步骤的教学
  bool shouldShowTutorialFor(TutorialStep step) {
    return isTutorialActive.value && currentStep.value == step;
  }

  /// 显示跳过确认对话框
  Future<void> _showSkipConfirmation(BuildContext context) async {
    // 保存当前步骤
    final currentStepBeforeDialog = currentStep.value;

    hideOverlay().then((_) async {
      final result = await TDialog.confirmDialog(
        title: 'Skip Tutorial?',
        message: 'Are you sure you want to skip the tutorial? You can restart it later from Settings.',
        confirmText: 'Skip',
        cancelText: 'Continue',
        icon: Icons.warning_amber_rounded,
        iconColor: TColors.warning,
        confirmButtonColor: TColors.warning,
        onConfirm: () {
          // 用户点击 Skip 后的逻辑
          completeTutorial(showMessage: false);
          TLoaders.modernSnackBar(
            title: 'Tutorial Skipped',
            message: 'You can restart it from Settings',
          );
        },
      );

      // 用户点击 “Continue Tutorial” 或关闭对话框时恢复引导
      if (result == false || result == null) {
        _overlayEntry = null;
        showOverlay.value = false;
        currentStep.value = currentStepBeforeDialog;
        needsResume.value = true;
      }
    });
  }

  void reloadForCurrentUser() {
    hideOverlay();
    _loadTutorialState();
  }

  @override
  void onClose() {
    hideOverlay();
    super.onClose();
  }
}