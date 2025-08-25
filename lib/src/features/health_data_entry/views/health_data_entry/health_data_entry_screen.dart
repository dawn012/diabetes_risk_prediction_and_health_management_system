import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/health_data_entry_controller.dart';

class HealthDataEntryScreen extends StatelessWidget {
  const HealthDataEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HealthDataEntryController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: darkMode ? TColors.dark : Colors.grey.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: darkMode ? TColors.dark : Colors.grey.shade50,
        elevation: 0,
        title: Text(
          'Add Health Data',
          style: TextStyle(
            color: darkMode ? TColors.white : TColors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20
          ),
        ),
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
                        .map((section) => _buildHealthMetricSection(context, section, darkMode, controller))
                        .toList(),
                  )),

                  SizedBox(height: TSizes.spaceBtwItems),

                  /// Add Others Section
                  Obx(() => controller.getAvailableSections().isNotEmpty
                      ? _buildAddOthersSection(context, darkMode, controller)
                      : SizedBox.shrink()),
                ],
              ),
            ),
          ),

          /// Bottom Buttons
          _buildBottomButtons(context, darkMode, controller),
        ],
      ),
    );
  }

  /// Time Selection Section
  Widget _buildTimeSection(BuildContext context, bool darkMode, HealthDataEntryController controller) {
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
  Widget _buildPeriodSection(BuildContext context, bool darkMode, HealthDataEntryController controller) {
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
                  controller.selectedPeriod.value,
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
  Widget _buildHealthMetricSection(BuildContext context, String section, bool darkMode, HealthDataEntryController controller) {
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
  List<Widget> _buildSectionInputs(String section, bool darkMode, HealthDataEntryController controller) {
    switch (section) {
      case 'Blood Glucose':
        return [
          _buildInputField(
            'Glucose',
            'Enter',
            'mmol/L',
            controller.glucoseController,
            darkMode,
          ),
        ];

      case 'Blood Pressure & Pulse':
        return [
          _buildInputField(
            'Systolic',
            'Enter',
            'mmHg',
            controller.systolicController,
            darkMode,
          ),
          SizedBox(height: TSizes.sm),
          _buildInputField(
            'Diastolic',
            'Enter',
            'mmHg',
            controller.diastolicController,
            darkMode,
          ),
        ];

      case 'Weight & Body Fat':
        return [
          _buildInputField(
            'Weight',
            'Enter',
            'kg',
            controller.weightController,
            darkMode,
          ),
          SizedBox(height: TSizes.sm),
          _buildInputField(
            'Body Fat',
            'Enter',
            '%',
            controller.bodyFatController,
            darkMode,
          ),
        ];

      case 'Exercise':
        return [
          _buildInputField(
            'Activity Name',
            'Enter exercise name',
            '',
            controller.exerciseNameController,
            darkMode,
          ),
          SizedBox(height: TSizes.sm),
          _buildInputField(
            'Duration',
            'Enter duration',
            'minutes',
            controller.durationController,
            darkMode,
          ),
          SizedBox(height: TSizes.sm),
          _buildInputField(
            'Intensity Level',
            'Low/Medium/High',
            '',
            controller.intensityController,
            darkMode,
          ),
        ];

      case 'Note':
        return [
          _buildInputField(
            'Note',
            'Add your notes here...',
            '',
            controller.noteController,
            darkMode,
            maxLines: 3,
          ),
        ];

      default:
        return [];
    }
  }

  /// Input Field Builder
  Widget _buildInputField(
      String label,
      String hint,
      String unit,
      TextEditingController textController,
      bool darkMode, {
        int maxLines = 1,
      }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
              color: darkMode ? TColors.white : TColors.black,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: TextField(
            controller: textController,
            maxLines: maxLines,
            style: TextStyle(color: darkMode ? TColors.white : TColors.black),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: darkMode ? Colors.grey.shade500 : Colors.grey.shade400,
              ),
              border: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: darkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                ),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: darkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: TColors.primary),
              ),
              suffixText: unit.isNotEmpty ? unit : null,
              suffixStyle: TextStyle(
                color: darkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Add Others Section
  Widget _buildAddOthersSection(BuildContext context, bool darkMode, HealthDataEntryController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: TSizes.md),
          child: Text(
            'Add others:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: darkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ),
        ...controller.getAvailableSections().map((section) =>
            _buildAddOptionTile(context, section, darkMode, controller)
        ).toList(),
      ],
    );
  }

  /// Add Option Tile
  Widget _buildAddOptionTile(BuildContext context, String section, bool darkMode, HealthDataEntryController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: TSizes.sm),
      child: GestureDetector(
        onTap: () => controller.addSection(section),
        child: Container(
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
              _getSectionIcon(section),
              SizedBox(width: TSizes.sm),
              Expanded(
                child: Text(
                  section,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: darkMode ? TColors.white : TColors.black,
                  ),
                ),
              ),
              Icon(
                Icons.add,
                color: darkMode ? TColors.white : TColors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom Buttons
  Widget _buildBottomButtons(BuildContext context, bool darkMode, HealthDataEntryController controller) {
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
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Get.back(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: TColors.primary),
                padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(color: TColors.primary),
              ),
            ),
          ),
          SizedBox(width: TSizes.spaceBtwItems),
          Expanded(
            child: ElevatedButton(
              onPressed: controller.saveHealthData,
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.primary,
                padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                ),
              ),
              child: Text(
                'Done',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get Section Icon
  Widget _getSectionIcon(String section) {
    IconData icon;
    Color color;

    switch (section) {
      case 'Blood Glucose':
        icon = Icons.opacity;
        color = TColors.primary;
        break;
      case 'Blood Pressure & Pulse':
        icon = Icons.favorite;
        color = Colors.red;
        break;
      case 'Weight & Body Fat':
        icon = Icons.monitor_weight;
        color = Colors.blue;
        break;
      case 'Exercise':
        icon = Icons.fitness_center;
        color = Colors.orange;
        break;
      case 'Note':
        icon = Icons.note;
        color = Colors.purple;
        break;
      default:
        icon = Icons.health_and_safety;
        color = Colors.grey;
    }

    return Icon(icon, color: color, size: 20);
  }

  /// Show Date Time Picker
  void _showDateTimePicker(BuildContext context, bool darkMode, HealthDataEntryController controller) {
    Get.dialog(
      _DateTimePicker(
        initialDate: controller.selectedDate.value,
        initialTime: controller.selectedTime.value,
        darkMode: darkMode,
        onDateTimeChanged: controller.updateDateTime,
      ),
    );
  }

  /// Show Period Picker
  void _showPeriodPicker(BuildContext context, bool darkMode, HealthDataEntryController controller) {
    Get.bottomSheet(
      _PeriodPicker(
        periods: controller.periods,
        selectedPeriod: controller.selectedPeriod.value,
        darkMode: darkMode,
        onPeriodSelected: controller.updatePeriod,
      ),
      backgroundColor: Colors.transparent,
    );
  }
}

/// Date Time Picker Dialog
class _DateTimePicker extends StatefulWidget {
  final DateTime initialDate;
  final TimeOfDay initialTime;
  final bool darkMode;
  final Function(DateTime, TimeOfDay) onDateTimeChanged;

  const _DateTimePicker({
    required this.initialDate,
    required this.initialTime,
    required this.darkMode,
    required this.onDateTimeChanged,
  });

  @override
  State<_DateTimePicker> createState() => _DateTimePickerState();
}

class _DateTimePickerState extends State<_DateTimePicker> {
  late DateTime selectedDate;
  late int selectedHour;
  late int selectedMinute;

  // Controllers for the wheel scroll views
  late FixedExtentScrollController hourController;
  late FixedExtentScrollController minuteController;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
    selectedHour = widget.initialTime.hour;
    selectedMinute = widget.initialTime.minute;

    // Initialize controllers with current time positions
    hourController = FixedExtentScrollController(initialItem: selectedHour);
    minuteController = FixedExtentScrollController(initialItem: selectedMinute);
  }

  @override
  void dispose() {
    hourController.dispose();
    minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: widget.darkMode ? TColors.dark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
      ),
      child: Container(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Header
            Text(
              'Select Date & Time',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: widget.darkMode ? TColors.white : TColors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: TSizes.spaceBtwSections),

            /// Calendar
            Container(
              height: 300,
              child: CalendarDatePicker(
                initialDate: selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now().toLocal(),
                onDateChanged: (date) => setState(() => selectedDate = date),
              ),
            ),

            SizedBox(height: TSizes.spaceBtwSections),

            /// 24-Hour Time Picker
            Container(
              height: 150,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Hour Picker (00-23)
                  _buildNumberPicker(
                    minValue: 0,
                    maxValue: 23,
                    value: selectedHour,
                    controller: hourController,
                    onChanged: (hour) => setState(() => selectedHour = hour),
                  ),
                  Text(':',
                    style: TextStyle(
                        fontSize: 24,
                        color: TColors.primary
                    ),
                  ),
                  // Minute Picker (00-59)
                  _buildNumberPicker(
                    minValue: 0,
                    maxValue: 59,
                    value: selectedMinute,
                    controller: minuteController,
                    onChanged: (minute) => setState(() => selectedMinute = minute),
                    interval: 1, // Allow per-minute selection
                  ),
                ],
              ),
            ),

            SizedBox(height: TSizes.spaceBtwSections),

            /// Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: Get.back,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: TColors.primary),
                    ),
                    child: Text(
                      'CANCEL',
                      style: TextStyle(color: TColors.primary),
                    ),
                  ),
                ),
                SizedBox(width: TSizes.spaceBtwItems),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onDateTimeChanged(
                        selectedDate,
                        TimeOfDay(hour: selectedHour, minute: selectedMinute),
                      );
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColors.primary,
                    ),
                    child: Text(
                      'CONFIRM',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPicker({
    required int minValue,
    required int maxValue,
    required int value,
    required FixedExtentScrollController controller,
    required ValueChanged<int> onChanged,
    int interval = 1,
  }) {
    return SizedBox(
      width: 80,
      child: ListWheelScrollView(
        controller: controller,
        itemExtent: 50,
        diameterRatio: 1.5,
        physics: FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) {
          final newValue = minValue + (index * interval);
          onChanged(newValue);
        },
        children: List.generate(
          ((maxValue - minValue) ~/ interval) + 1,
              (index) {
            final number = minValue + (index * interval);
            return Center(
              child: Text(
                number.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: number == value ? 24 : 18,
                  color: number == value
                      ? TColors.primary
                      : widget.darkMode
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                  fontWeight: number == value
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Period Picker Bottom Sheet
class _PeriodPicker extends StatelessWidget {
  final List<String> periods;
  final String selectedPeriod;
  final bool darkMode;
  final Function(String) onPeriodSelected;

  const _PeriodPicker({
    required this.periods,
    required this.selectedPeriod,
    required this.darkMode,
    required this.onPeriodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: darkMode ? TColors.dark : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(TSizes.cardRadiusLg),
          topRight: Radius.circular(TSizes.cardRadiusLg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Header
          Container(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            decoration: BoxDecoration(
              color: TColors.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(TSizes.cardRadiusLg),
                topRight: Radius.circular(TSizes.cardRadiusLg),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Period',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          /// Period Options
          Container(
            constraints: BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: periods.length,
              itemBuilder: (context, index) {
                final period = periods[index];
                final isSelected = period == selectedPeriod;

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: TSizes.defaultSpace,
                    vertical: TSizes.xs,
                  ),
                  child: ListTile(
                    title: Text(
                      period,
                      style: TextStyle(
                        color: darkMode ? TColors.white : TColors.black,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedTileColor: TColors.primary.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                    ),
                    onTap: () {
                      onPeriodSelected(period);
                      Get.back();
                    },
                    trailing: isSelected
                        ? Icon(Icons.check, color: TColors.primary)
                        : null,
                  ),
                );
              },
            ),
          ),

          SizedBox(height: TSizes.defaultSpace),
        ],
      ),
    );
  }
}