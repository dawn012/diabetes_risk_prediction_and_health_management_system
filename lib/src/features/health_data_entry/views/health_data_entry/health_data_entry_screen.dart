import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../common/widgets/dialogs/dialog.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/health_data_entry_controller.dart';
import '../../models/health_data_model.dart';

class HealthDataEntryScreen extends StatelessWidget {
  final HealthDataModel? editData;
  final List<String>? initialSections;

  const HealthDataEntryScreen({super.key, this.editData, this.initialSections});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HealthDataEntryController(editData: editData, initialSections: initialSections));
    final darkMode = THelperFunctions.isDarkMode(context);
    final isEditing = editData != null;

    return Scaffold(
      backgroundColor: darkMode ? TColors.dark : Colors.grey.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: darkMode ? TColors.dark : Colors.grey.shade50,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          isEditing ? 'Edit Health Data' : 'Add Health Data',
          style: TextStyle(
              color: darkMode ? TColors.white : TColors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: Icon(
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
                  /// Time Section
                  _buildTimeSection(context, darkMode, controller),

                  SizedBox(height: TSizes.spaceBtwItems),

                  /// Period Section
                  _buildPeriodSection(context, darkMode, controller),

                  SizedBox(height: TSizes.spaceBtwSections),

                  /// Active Health Metrics
                  Obx(() => Column(
                    children: controller.activeSections
                        .map((section) => _buildHealthMetricSection(
                        context, section, darkMode, controller))
                        .toList(),
                  )),

                  SizedBox(height: TSizes.spaceBtwItems),

                  /// Add Others Section
                  Obx(() =>
                      _buildAddOthersSection(context, darkMode, controller)),
                ],
              ),
            ),
          ),

          /// Bottom Buttons
          _buildBottomButtons(context, darkMode, controller, isEditing),
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
          Spacer(),
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
                  style: TextStyle(
                    color: TColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: TSizes.xs),
                Icon(
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
          Spacer(),
          GestureDetector(
            onTap: () => _showPeriodPicker(context, darkMode, controller),
            child: Obx(() => Row(
              children: [
                Text(
                  controller.selectedPeriod.value.displayName,
                  style: TextStyle(
                    color: TColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: TSizes.xs),
                Icon(
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
  Widget _buildHealthMetricSection(BuildContext context, String section,
      bool darkMode, HealthDataEntryController controller) {
    return Container(
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
              SizedBox(width: TSizes.sm),
              Text(
                section,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: darkMode ? TColors.white : TColors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
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

          SizedBox(height: TSizes.md),

          /// Input Fields
          ..._buildSectionInputs(section, darkMode, controller),
        ],
      ),
    );
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
          SizedBox(height: TSizes.sm),
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
          SizedBox(height: TSizes.sm),
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
          SizedBox(height: TSizes.sm),
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
          SizedBox(height: TSizes.sm),
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
          SizedBox(height: TSizes.sm),
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
            maxLines: 3,
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

        // Input field with error - FIXED: Error only shows under input
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
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
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
                  if (error == null) return SizedBox(height: 4);

                  return Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      error,
                      style: TextStyle(
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
      return SizedBox.shrink();
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
          SizedBox(height: TSizes.sm),
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
                      SizedBox(width: TSizes.xs),
                      Text(
                        section,
                        style: TextStyle(
                          color: TColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: TSizes.xs),
                      Icon(
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
      HealthDataEntryController controller, bool isEditing) {
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
            SizedBox(width: TSizes.md),
            Expanded(
              child: Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () => _handleSave(controller, isEditing),
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
                    AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Text(
                  isEditing ? 'Update' : 'Save',
                  style: TextStyle(
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
        iconColor = TColors.glucoseGood;
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
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: darkMode
                ? ColorScheme.dark(primary: TColors.primary)
                : ColorScheme.light(primary: TColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      controller.selectedDate.value = date;

      // Show Time Picker
      final time = await showTimePicker(
        context: context,
        initialTime: controller.selectedTime.value,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: darkMode
                  ? ColorScheme.dark(primary: TColors.primary)
                  : ColorScheme.light(primary: TColors.primary),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        controller.selectedTime.value = time;
      }
    }
  }

  /// Show Period Picker
  void _showPeriodPicker(BuildContext context, bool darkMode,
      HealthDataEntryController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: darkMode ? TColors.darkerGrey : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(TSizes.cardRadiusLg)),
      ),
      isScrollControlled: true,
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
                SizedBox(height: TSizes.md),
                ...PhysiologicalTimePeriod.values
                    .map((period) => ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 0),
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
                        ? Icon(Icons.check, color: TColors.primary)
                        : const SizedBox.shrink();
                  }),
                ))
                    .toList(),
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
      HealthDataEntryController controller, bool isEditing) async {
    try {
      if (isEditing) {
        await controller.updateHealthData();
      } else {
        await controller.saveHealthData();
      }
    } catch (e) {
      // Error handling is done in the controller
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