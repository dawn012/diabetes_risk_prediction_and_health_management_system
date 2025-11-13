import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../common/widgets/dialogs/dialog.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';

class ProfileSelectionDialog {
  /// Show single selection dialog
  static Future<String?> showSingleSelection({
    required String title,
    required List<String> options,
    String? currentValue,
    IconData? icon,
  }) async {
    return await Get.dialog<String>(
      _SingleSelectionDialog(
        title: title,
        options: options,
        currentValue: currentValue,
        icon: icon,
      ),
    );
  }

  /// Show multi selection dialog
  static Future<List<String>?> showMultiSelection({
    required String title,
    required List<String> options,
    List<String>? currentValues,
    IconData? icon,
  }) async {
    return await Get.dialog<List<String>>(
      _MultiSelectionDialog(
        title: title,
        options: options,
        currentValues: currentValues ?? [],
        icon: icon,
      ),
    );
  }

  /// Show gender selection with one-time change warning
  static Future<String?> showGenderSelection({
    required String currentGender,
    required bool hasChangedBefore,
  }) async {
    if (hasChangedBefore && currentGender.isNotEmpty) {
      // Show warning first
      final proceed = await TDialog.confirmDialog(
        title: 'Change Gender',
        message: 'Gender can only be changed once after initial setup. '
            'Are you sure you want to change it? This action cannot be undone.',
        confirmText: 'Proceed',
        icon: Iconsax.warning_2_bold,
        iconColor: TColors.warning,
        confirmButtonColor: TColors.warning,
      );

      if (proceed != true) return null;
    }

    return await showSingleSelection(
      title: 'Select Gender',
      options: ['Male', 'Female'],
      currentValue: currentGender == 'M' ? 'Male' : (currentGender == 'F' ? 'Female' : null),
      icon: Iconsax.user_bold,
    );
  }
}

class _SingleSelectionDialog extends StatefulWidget {
  final String title;
  final List<String> options;
  final String? currentValue;
  final IconData? icon;

  const _SingleSelectionDialog({
    required this.title,
    required this.options,
    this.currentValue,
    this.icon,
  });

  @override
  State<_SingleSelectionDialog> createState() => _SingleSelectionDialogState();
}

class _SingleSelectionDialogState extends State<_SingleSelectionDialog> {
  String? selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.currentValue;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);

    return Dialog(
      backgroundColor: isDark ? TColors.dark : TColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: 400, maxHeight: 600),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon and Title
            if (widget.icon != null) ...[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: TColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: TColors.primary,
                  size: 28,
                ),
              ),
              SizedBox(height: 16),
            ],

            Text(
              widget.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: isDark ? TColors.white : TColors.black,
              ),
            ),
            SizedBox(height: 20),

            // Options List
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.options.length,
                itemBuilder: (context, index) {
                  final option = widget.options[index];
                  final isSelected = selectedValue == option;

                  return Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            selectedValue = option;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? TColors.primary.withOpacity(0.1)
                                : (isDark
                                ? TColors.darkGrey.withOpacity(0.15)
                                : TColors.lightGrey),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? TColors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? TColors.primary
                                        : (isDark ? TColors.darkGrey : TColors.grey),
                                    width: 2,
                                  ),
                                  color: Colors.transparent,
                                ),
                                child: isSelected
                                    ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: TColors.primary,
                                    ),
                                  ),
                                )
                                    : null,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    fontSize: 15,
                                    color: isSelected
                                        ? TColors.primary
                                        : (isDark ? TColors.white : TColors.black),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: isDark ? TColors.white : TColors.black,
                      side: BorderSide(
                        color: isDark
                            ? TColors.darkGrey.withOpacity(0.5)
                            : TColors.grey.withOpacity(0.5),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: selectedValue != null
                        ? () => Get.back(result: selectedValue)
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: TColors.primary,
                      foregroundColor: TColors.white,
                      disabledBackgroundColor: isDark
                          ? TColors.darkGrey.withOpacity(0.3)
                          : TColors.grey.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Confirm',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
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
}

class _MultiSelectionDialog extends StatefulWidget {
  final String title;
  final List<String> options;
  final List<String> currentValues;
  final IconData? icon;

  const _MultiSelectionDialog({
    required this.title,
    required this.options,
    required this.currentValues,
    this.icon,
  });

  @override
  State<_MultiSelectionDialog> createState() => _MultiSelectionDialogState();
}

class _MultiSelectionDialogState extends State<_MultiSelectionDialog> {
  late List<String> selectedValues;

  @override
  void initState() {
    super.initState();
    selectedValues = List.from(widget.currentValues);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);

    return Dialog(
      backgroundColor: isDark ? TColors.dark : TColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: 400, maxHeight: 600),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon and Title
            if (widget.icon != null) ...[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: TColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: TColors.primary,
                  size: 28,
                ),
              ),
              SizedBox(height: 16),
            ],

            Text(
              widget.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: isDark ? TColors.white : TColors.black,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Select all that apply',
              style: TextStyle(
                color: isDark ? TColors.darkGrey : TColors.textSecondary,
                fontSize: 13,
              ),
            ),
            SizedBox(height: 20),

            // Options List
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.options.length,
                itemBuilder: (context, index) {
                  final option = widget.options[index];
                  final isSelected = selectedValues.contains(option);

                  return Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              selectedValues.remove(option);
                            } else {
                              selectedValues.add(option);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? TColors.primary.withOpacity(0.1)
                                : (isDark
                                ? TColors.darkGrey.withOpacity(0.15)
                                : TColors.lightGrey),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? TColors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isSelected
                                        ? TColors.primary
                                        : (isDark ? TColors.darkGrey : TColors.grey),
                                    width: 2,
                                  ),
                                  color: isSelected ? TColors.primary : Colors.transparent,
                                ),
                                child: isSelected
                                    ? Icon(
                                  Icons.check,
                                  size: 14,
                                  color: TColors.white,
                                )
                                    : null,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    fontSize: 15,
                                    color: isSelected
                                        ? TColors.primary
                                        : (isDark ? TColors.white : TColors.black),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 12),

            // Selected count badge
            if (selectedValues.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: TColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.tick_circle_bold,
                      size: 14,
                      color: TColors.white,
                    ),
                    SizedBox(width: 6),
                    Text(
                      '${selectedValues.length} selected',
                      style: TextStyle(
                        color: TColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: isDark ? TColors.white : TColors.black,
                      side: BorderSide(
                        color: isDark
                            ? TColors.darkGrey.withOpacity(0.5)
                            : TColors.grey.withOpacity(0.5),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Get.back(result: selectedValues),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: TColors.primary,
                      foregroundColor: TColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Confirm',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
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
}