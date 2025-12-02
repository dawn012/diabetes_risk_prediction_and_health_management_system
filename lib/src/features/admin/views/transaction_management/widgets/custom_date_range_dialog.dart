import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../utils/constants/admin_colors.dart';
import '../../../../../utils/formatters/formatter.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/transaction_management_controller.dart';

class CustomDateRangeDialog extends StatefulWidget {
  final TransactionManagementController controller;

  const CustomDateRangeDialog({
    super.key,
    required this.controller,
  });

  @override
  State<CustomDateRangeDialog> createState() => _CustomDateRangeDialogState();
}

class _CustomDateRangeDialogState extends State<CustomDateRangeDialog> {
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    startDate = widget.controller.startDate.value;
    endDate = widget.controller.endDate.value;
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);
    final isWeb = THelperFunctions.screenWidth() > 600;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isWeb ? 500 : 400,
        ),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: TAdminColors.getSurfaceColor(darkMode),
          borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: TAdminColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Iconsax.calendar_edit_bold,
                    color: TAdminColors.primary,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Select Date Range',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: TAdminColors.getOnSurfaceColor(darkMode),
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: () {
                    if (Get.context != null) {
                      Navigator.of(Get.context!, rootNavigator: true).pop(true);
                    }
                  },
                  icon: Icon(
                    Iconsax.close_circle_bold,
                    color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: TAdminColors.getSurfaceVariantColor(darkMode),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Description
            Text(
              'Select a custom date range to filter transactions',
              style: TextStyle(
                color: TAdminColors.getOnSurfaceVariantColor(darkMode),
              ),
            ),
            SizedBox(height: 24),

            // Start Date
            _buildDateField(
              label: 'Start Date',
              value: startDate,
              icon: Iconsax.calendar_1_bold,
              darkMode: darkMode,
              onTap: () => _selectStartDate(context),
            ),
            SizedBox(height: 16),

            // End Date
            _buildDateField(
              label: 'End Date',
              value: endDate,
              icon: Iconsax.calendar_2_bold,
              darkMode: darkMode,
              onTap: () => _selectEndDate(context),
            ),

            // Validation message
            if (startDate != null && endDate != null && startDate!.isAfter(endDate!))
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.warning_2_bold,
                      color: TAdminColors.error,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Start date must be before end date',
                      style: TextStyle(
                        fontSize: 12,
                        color: TAdminColors.error,
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 24),

            // Quick selection buttons
            Text(
              'Quick Select',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: TAdminColors.getOnSurfaceColor(darkMode),
              ),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickSelectChip('Last 7 Days', 7, darkMode),
                _buildQuickSelectChip('Last 30 Days', 30, darkMode),
                _buildQuickSelectChip('Last 90 Days', 90, darkMode),
                _buildQuickSelectChip('This Year', 365, darkMode),
              ],
            ),

            SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearDates,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Clear'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isValid ? _applyDateRange : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TAdminColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      disabledBackgroundColor: TAdminColors.primary.withOpacity(0.3),
                    ),
                    child: Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required IconData icon,
    required bool darkMode,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TAdminColors.getSurfaceVariantColor(darkMode),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: TAdminColors.getBorderColor(darkMode),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: TAdminColors.primary,
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value != null
                        ? TFormatter.formatDate(value)
                        : 'Select date',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: value != null
                          ? TAdminColors.getOnSurfaceColor(darkMode)
                          : TAdminColors.getOnSurfaceVariantColor(darkMode),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Iconsax.arrow_right_3_bold,
              size: 16,
              color: TAdminColors.getOnSurfaceVariantColor(darkMode),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSelectChip(String label, int days, bool darkMode) {
    return InkWell(
      onTap: () => _quickSelect(days),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: TAdminColors.getSurfaceVariantColor(darkMode),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: TAdminColors.getBorderColor(darkMode),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: TAdminColors.getOnSurfaceColor(darkMode),
          ),
        ),
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: TAdminColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: TAdminColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        endDate = picked;
      });
    }
  }

  void _quickSelect(int days) {
    setState(() {
      endDate = DateTime.now();
      startDate = endDate!.subtract(Duration(days: days));
    });
  }

  void _clearDates() {
    setState(() {
      startDate = null;
      endDate = null;
    });
  }

  bool get _isValid {
    if (startDate == null || endDate == null) return false;
    return !startDate!.isAfter(endDate!);
  }

  void _applyDateRange() {
    if (_isValid) {
      widget.controller.setCustomDateRange(startDate!, endDate!);
      Get.back();
    }
  }
}