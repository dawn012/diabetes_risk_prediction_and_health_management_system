import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../common/loaders/loaders.dart';
import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/dialogs/dialog.dart';
import '../../../../services/tutorial_flow_manager.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/constants/physiological_period_constants.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/health_data_entry_controller.dart';
import '../../models/health_data_model.dart';

class HealthDataEntryScreen extends StatelessWidget {
  final HealthDataModel? editData;
  final List<String>? initialSections;

  const HealthDataEntryScreen({
    super.key,
    this.editData,
    this.initialSections,
  });

  void _initializeTutorial(BuildContext context, TutorialFlowManager flowManager) {
    if (flowManager.shouldShowTutorialFor(TutorialStep.dataEntryIntro)) {
      // 显示时间和周期选择介绍
      Future.delayed(const Duration(milliseconds: 500), () {
        if (context.mounted) {
          flowManager.showCurrentStepOverlay(context);
        }
      });
    } else if (flowManager.shouldShowTutorialFor(TutorialStep.dataEntryGlucose)) {
      // 显示血糖输入教学
      Future.delayed(const Duration(milliseconds: 500), () {
        if (context.mounted) {
          flowManager.showCurrentStepOverlay(context);
        }
      });
    } else if (flowManager.shouldShowTutorialFor(TutorialStep.dataEntrySave)) {
      // 显示保存按钮教学
      Future.delayed(const Duration(milliseconds: 500), () {
        if (context.mounted) {
          flowManager.showCurrentStepOverlay(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HealthDataEntryController(
      editData: editData,
      initialSections: initialSections,
    ));
    final darkMode = THelperFunctions.isDarkMode(context);
    final isEditing = editData != null;
    final flowManager = TutorialFlowManager.instance;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTutorial(context, flowManager);
    });

    return Scaffold(
      backgroundColor: darkMode ? TColors.dark : Colors.grey.shade50,
      appBar: TAppBar(
        automaticallyImplyLeading: false,
        backgroundColor: darkMode ? TColors.dark : Colors.grey.shade50,
        showBackArrow: true,
        title: Text(
          isEditing ? 'Edit Health Data' : 'Add Health Data',
          style: TextStyle(
              color: darkMode ? TColors.white : TColors.black,
              fontWeight: FontWeight.w600,
              fontSize: 18),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
              onPressed: () => _showDeleteDialog(context, controller),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              child: Column(
                children: [
                  Container(
                    key: flowManager.timeSelectionKey,
                    child: Column(
                      children: [
                        /// Time Section
                        _buildTimeSection(context, darkMode, controller),

                        const SizedBox(height: TSizes.spaceBtwItems),

                        /// Period Section
                        _buildPeriodSection(context, darkMode, controller),
                      ],
                    ),
                  ),

                  const SizedBox(height: TSizes.spaceBtwSections),

                  /// Active Health Metrics
                  Obx(() => Column(
                    children: controller.activeSections
                        .map((section) => _buildHealthMetricSection(
                        context, section, darkMode, controller, flowManager))
                        .toList(),
                  )),

                  const SizedBox(height: TSizes.spaceBtwItems),

                  /// Add Others Section
                  Obx(() => _buildAddOthersSection(context, darkMode, controller)),
                ],
              ),
            ),
          ),

          /// Bottom Buttons
          Container(
            key: flowManager.dataEntrySaveKey,
            child: _buildBottomButtons(context, darkMode, controller, isEditing, flowManager),
          ),
        ],
      ),
    );
  }

  /// Time Selection Section
  Widget _buildTimeSection(BuildContext context, bool darkMode,
      HealthDataEntryController controller) {
    return Container(
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: darkMode ? TColors.darkerGrey : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        border: Border.all(
          color: darkMode ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Text(
            'Time',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: darkMode ? TColors.white : TColors.black,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _showDateTimePicker(context, darkMode, controller),
            child: Obx(() => Row(
              children: [
                Text(
                  DateFormat('E, M/d/yyyy, HH:mm').format(
                    DateTime(
                      controller.selectedDate.value.year,
                      controller.selectedDate.value.month,
                      controller.selectedDate.value.day,
                      controller.selectedTime.value.hour,
                      controller.selectedTime.value.minute,
                    ),
                  ),
                  style: const TextStyle(
                    color: TColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: TSizes.xs),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: TColors.primary,
                ),
              ],
            )),
          ),
        ],
      ),
    );
  }

  /// Period Selection Section
  Widget _buildPeriodSection(BuildContext context, bool darkMode,
      HealthDataEntryController controller) {
    return Container(
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: darkMode ? TColors.darkerGrey : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        border: Border.all(
          color: darkMode ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Text(
            'Period',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: darkMode ? TColors.white : TColors.black,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _showPeriodPicker(context, darkMode, controller),
            child: Obx(() => Row(
              children: [
                Text(
                  controller.selectedPeriod.value.displayName,
                  style: const TextStyle(
                    color: TColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: TSizes.xs),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: TColors.primary,
                ),
              ],
            )),
          ),
        ],
      ),
    );
  }

  /// Health Metric Section Builder
  Widget _buildHealthMetricSection(
      BuildContext context,
      String section,
      bool darkMode,
      HealthDataEntryController controller,
      TutorialFlowManager flowManager) {
    Widget sectionContent = Container(
      margin: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: darkMode ? TColors.darkerGrey : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        border: Border.all(
          color: darkMode ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          /// Header with close button
          Row(
            children: [
              _getSectionIcon(section),
              const SizedBox(width: TSizes.sm),
              Text(
                section,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: darkMode ? TColors.white : TColors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // 在教学模式下隐藏关闭按钮
              if (!flowManager.shouldShowTutorialFor(TutorialStep.dataEntryGlucose) ||
                  section != 'Blood Glucose')
                GestureDetector(
                  onTap: () => controller.removeSection(section),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: TSizes.md),

          /// Input Fields
          ..._buildSectionInputs(section, darkMode, controller),
        ],
      ),
    );

    // 如果是血糖部分且在教学流程中，添加 key
    if (section == 'Blood Glucose' &&
        flowManager.shouldShowTutorialFor(TutorialStep.dataEntryGlucose)) {
      return Container(
        key: flowManager.glucoseInputKey,
        child: sectionContent,
      );
    }

    return sectionContent;
  }

  /// Build inputs for each section
  List<Widget> _buildSectionInputs(String section, bool darkMode,
      HealthDataEntryController controller) {
    switch (section) {
      case 'Blood Glucose':
        return [
          _buildInputField(
            'Glucose',
            'Enter glucose level',
            'mmol/L',
            controller.glucoseController,
            darkMode,
            controller,
            fieldKey: 'glucose',
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
          ),
        ];

      case 'Blood Pressure & Pulse':
        return [
          _buildInputField(
            'Systolic',
            'Enter systolic',
            'mmHg',
            controller.systolicController,
            darkMode,
            controller,
            fieldKey: 'systolic',
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
          ),
          const SizedBox(height: TSizes.sm),
          _buildInputField(
            'Diastolic',
            'Enter diastolic',
            'mmHg',
            controller.diastolicController,
            darkMode,
            controller,
            fieldKey: 'diastolic',
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
          ),
          const SizedBox(height: TSizes.sm),
          _buildInputField(
            'Pulse',
            'Enter pulse',
            'bpm',
            controller.pulseController,
            darkMode,
            controller,
            fieldKey: 'pulse',
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
          ),
        ];

      case 'Weight & Body Fat':
        return [
          _buildInputField(
            'Weight',
            'Enter weight',
            'kg',
            controller.weightController,
            darkMode,
            controller,
            fieldKey: 'weight',
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
          ),
          const SizedBox(height: TSizes.sm),
          _buildInputField(
            'Body Fat',
            'Enter body fat',
            '%',
            controller.bodyFatController,
            darkMode,
            controller,
            fieldKey: 'bodyFat',
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
          ),
        ];

      case 'Exercise':
        return [
          _buildInputField(
            'Activity',
            'Enter exercise name',
            '',
            controller.exerciseNameController,
            darkMode,
            controller,
            fieldKey: 'activityType',
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: TSizes.sm),
          _buildInputField(
            'Duration',
            'Enter duration',
            'minutes',
            controller.durationController,
            darkMode,
            controller,
            fieldKey: 'duration',
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
          ),
          const SizedBox(height: TSizes.sm),
          _buildIntensitySelector(darkMode, controller),
        ];

      case 'Note':
        return [
          _buildInputField(
            'Note',
            'Add your notes here...',
            '',
            controller.noteController,
            darkMode,
            controller,
            fieldKey: 'note',
            maxLines: 1,
            keyboardType: TextInputType.multiline,
          ),
        ];

      default:
        return [];
    }
  }

  /// Intensity selector
  Widget _buildIntensitySelector(
      bool darkMode, HealthDataEntryController controller) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            'Intensity',
            style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
              color: darkMode ? TColors.white : TColors.black,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Obx(() => DropdownButton<IntensityLevel>(
            value: controller.selectedIntensityLevel.value,
            isExpanded: true,
            underline: Container(
              height: 1,
              color: darkMode ? Colors.grey.shade600 : Colors.grey.shade300,
            ),
            dropdownColor: darkMode ? TColors.darkerGrey : Colors.white,
            style: TextStyle(
              color: darkMode ? TColors.white : TColors.black,
            ),
            items: IntensityLevel.values.map((IntensityLevel level) {
              return DropdownMenuItem<IntensityLevel>(
                value: level,
                child: Text(level.displayName),
              );
            }).toList(),
            onChanged: (IntensityLevel? newValue) {
              if (newValue != null) {
                controller.updateIntensityLevel(newValue);
              }
            },
          )),
        ),
      ],
    );
  }

  /// Input Field Builder with improved error display - FIXED
  Widget _buildInputField(
      String label,
      String hint,
      String unit,
      TextEditingController textController,
      bool darkMode,
      HealthDataEntryController controller, {
        int maxLines = 1,
        String? fieldKey,
        TextInputType? keyboardType,
        List<TextInputFormatter>? inputFormatters,
      }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label - Fixed flex
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Text(
              label,
              style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                color: darkMode ? TColors.white : TColors.black,
              ),
            ),
          ),
        ),

        // Input field with error
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() {
                final hasError = fieldKey != null &&
                    controller.getFieldError(fieldKey) != null;

                return TextField(
                  controller: textController,
                  maxLines: maxLines,
                  keyboardType: keyboardType ??
                      (unit.isNotEmpty && unit != 'Low/Medium/High'
                          ? TextInputType.numberWithOptions(decimal: true)
                          : TextInputType.text),
                  inputFormatters: inputFormatters,
                  style: TextStyle(
                    color: darkMode ? TColors.white : TColors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: darkMode
                          ? Colors.grey.shade500
                          : Colors.grey.shade400,
                    ),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: hasError
                            ? TColors.error
                            : (darkMode
                            ? Colors.grey.shade600
                            : Colors.grey.shade300),
                      ),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: hasError
                            ? TColors.error
                            : (darkMode
                            ? Colors.grey.shade600
                            : Colors.grey.shade300),
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: hasError ? TColors.error : TColors.primary,
                        width: 2,
                      ),
                    ),
                    suffixText: unit.isNotEmpty ? unit : null,
                    suffixStyle: TextStyle(
                      color: darkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (_) {
                    // Clear error when user starts typing
                    if (fieldKey != null && hasError) {
                      controller.fieldErrors.remove(fieldKey);
                      controller.fieldErrors.refresh();
                    }
                  },
                );
              }),

              // Error message - Only under the input field
              if (fieldKey != null)
                Obx(() {
                  final error = controller.getFieldError(fieldKey);
                  if (error == null) return const SizedBox(height: 4);

                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      error,
                      style: const TextStyle(
                        color: TColors.error,
                        fontSize: 11,
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  /// Add Others Section
  Widget _buildAddOthersSection(BuildContext context, bool darkMode,
      HealthDataEntryController controller) {
    final availableSections = controller.getAvailableSections();

    if (availableSections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(TSizes.md),
      width: double.infinity,
      decoration: BoxDecoration(
        color: darkMode ? TColors.darkerGrey : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        border: Border.all(
          color: darkMode ? Colors.grey.shade700 : Colors.grey.shade200,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Others',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: darkMode ? TColors.white : TColors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: TSizes.sm),
          Wrap(
            spacing: TSizes.sm,
            runSpacing: TSizes.sm,
            children: availableSections.map((section) {
              return GestureDetector(
                onTap: () => controller.addSection(section),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TSizes.md,
                    vertical: TSizes.sm,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: TColors.primary.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(TSizes.cardRadiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _getSectionIcon(section),
                      const SizedBox(width: TSizes.xs),
                      Text(
                        section,
                        style: const TextStyle(
                          color: TColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: TSizes.xs),
                      const Icon(
                        Icons.add,
                        size: 16,
                        color: TColors.primary,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Bottom Buttons
  Widget _buildBottomButtons(BuildContext context, bool darkMode,
      HealthDataEntryController controller, bool isEditing, TutorialFlowManager flowManager) {
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: darkMode ? TColors.dark : Colors.white,
        border: Border(
          top: BorderSide(
            color: darkMode ? Colors.grey.shade700 : Colors.grey.shade200,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Get.back(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                  side: BorderSide(
                    color:
                    darkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: darkMode ? TColors.white : TColors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: TSizes.md),
            Expanded(
              child: Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () => _handleSave(controller, isEditing, flowManager),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                ),
                child: controller.isLoading.value
                    ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Text(
                  isEditing ? 'Update' : 'Save',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }

  /// Get Section Icon
  Widget _getSectionIcon(String section) {
    IconData iconData;
    Color iconColor;

    switch (section) {
      case 'Blood Glucose':
        iconData = Icons.bloodtype_outlined;
        iconColor = TColors.glucoseNormal;
        break;
      case 'Blood Pressure & Pulse':
        iconData = Icons.favorite_outline;
        iconColor = TColors.bpNormal;
        break;
      case 'Weight & Body Fat':
        iconData = Icons.monitor_weight_outlined;
        iconColor = TColors.weightNormal;
        break;
      case 'Exercise':
        iconData = Icons.fitness_center_outlined;
        iconColor = TColors.success;
        break;
      case 'Note':
        iconData = Icons.note_outlined;
        iconColor = TColors.info;
        break;
      default:
        iconData = Icons.health_and_safety_outlined;
        iconColor = TColors.primary;
    }

    return Icon(
      iconData,
      color: iconColor,
      size: 20,
    );
  }

  /// Show Date Time Picker
  void _showDateTimePicker(BuildContext context, bool darkMode,
      HealthDataEntryController controller) async {
    // Show Date Picker first
    final date = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate.value,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(), // 不能选择未来日期
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: darkMode
                ? const ColorScheme.dark(primary: TColors.primary)
                : const ColorScheme.light(primary: TColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      controller.selectedDate.value = date;

      // 计算当前日期可选的最晚时间
      final now = DateTime.now();
      final isToday = date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;

      // Show Time Picker
      final time = await showTimePicker(
        context: context,
        initialTime: controller.selectedTime.value,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: darkMode
                  ? const ColorScheme.dark(primary: TColors.primary)
                  : const ColorScheme.light(primary: TColors.primary),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        // 验证时间不能超过当前时间
        if (isToday) {
          final selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );

          if (selectedDateTime.isAfter(now)) {
            // 时间超过当前时间，显示警告
            TLoaders.warningSnackBar(
              title: 'Invalid Time',
              message: 'Cannot select future time. Please choose a time in the past.',
            );
            return;
          }
        }

        // 时间有效，更新
        controller.updateTime(time);
      }
    }
  }

  /// Show Period Picker
  void _showPeriodPicker(BuildContext context, bool darkMode,
      HealthDataEntryController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: darkMode ? TColors.darkerGrey : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TSizes.cardRadiusLg)),
      ),
      isScrollControlled: true,
      // 添加约束限制最大高度
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6, // 最多占屏幕60%
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Period',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: darkMode ? TColors.white : TColors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: TSizes.md),

                // Period options
                ...PhysiologicalTimePeriod.values
                    .map((period) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                  title: Text(
                    period.displayName,
                    style: TextStyle(
                      color: darkMode ? TColors.white : TColors.black,
                    ),
                  ),
                  onTap: () {
                    controller.updatePeriod(period);
                    Get.back();
                  },
                  trailing: Obx(() {
                    return controller.selectedPeriod.value == period
                        ? const Icon(Icons.check, color: TColors.primary)
                        : const SizedBox.shrink();
                  }),
                ))
                    .toList(),

                // 添加底部间距，确保最后一个选项不会被遮挡
                const SizedBox(height: TSizes.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show Delete Dialog
  void _showDeleteDialog(
      BuildContext context, HealthDataEntryController controller) {
    TDialog.deleteDialog(
      title: 'Delete Record',
      message:
      'Are you sure you want to delete this health record? This action cannot be undone.',
      onConfirm: () => _handleDelete(controller),
    );
  }

  /// Handle Save
  void _handleSave(
      HealthDataEntryController controller,
      bool isEditing,
      TutorialFlowManager flowManager) async {
    try {
      // Tutorial 模式验证
      if (flowManager.shouldShowTutorialFor(TutorialStep.dataEntrySave)) {
        final glucoseText = controller.glucoseController.text.trim();
        if (glucoseText.isEmpty) {
          TLoaders.warningSnackBar(
            title: 'Enter Glucose Value',
            message: 'Please enter your blood glucose value before saving.',
          );
          return;
        }

        final glucoseValue = double.tryParse(glucoseText);
        if (glucoseValue == null || glucoseValue <= 0) {
          TLoaders.warningSnackBar(
            title: 'Invalid Glucose Value',
            message: 'Please enter a valid glucose value.',
          );
          return;
        }
      }

      // 执行保存操作
      if (isEditing) {
        await controller.updateHealthData();
      } else {
        await controller.saveHealthData();
      }

      // Tutorial 模式处理
      if (flowManager.shouldShowTutorialFor(TutorialStep.dataEntrySave)) {
        print('🎯 Data entry saved in tutorial mode');

        TLoaders.successSnackBar(
          title: 'Record Saved!',
          message: 'Your glucose reading has been recorded successfully.',
        );

        await flowManager.hideOverlay();

        flowManager.currentStep.value = TutorialStep.dashboardGlucoseCard;
        flowManager.saveCurrentStep();
        flowManager.isTutorialActive.value = true;

        print('📍 Step set to: ${flowManager.currentStep.value}');

        // 不直接 Get.back()，让 controller 处理返回
        // controller.saveHealthData() 会自动调用 Get.back() 并刷新 Dashboard

        // 等待返回 Dashboard 后显示 overlay
        Future.delayed(const Duration(milliseconds: 600), () {
          final currentContext = Get.context;
          if (currentContext != null &&
              currentContext.mounted &&
              flowManager.isTutorialActive.value &&
              flowManager.currentStep.value == TutorialStep.dashboardGlucoseCard) {
            print('🎬 Showing glucose card tutorial');
            flowManager.showCurrentStepOverlay(currentContext);
          }
        });

        return; // 添加 return，避免执行后面的代码
      }

      // 非 tutorial 模式：controller 已经自动处理了返回

    } catch (e) {
      print('Error saving health data: $e');

      if (flowManager.shouldShowTutorialFor(TutorialStep.dataEntrySave)) {
        TLoaders.errorSnackBar(
          title: 'Save Failed',
          message: 'Failed to save your record. Please try again.',
        );
      }
    }
  }

  /// Handle Delete
  void _handleDelete(HealthDataEntryController controller) async {
    try {
      await controller.deleteHealthData();
      if (Get.context != null) {
        Navigator.of(Get.context!, rootNavigator: true).pop(true);
      }
    } catch (e) {
      // Error handling is done in the controller
    }
  }
}