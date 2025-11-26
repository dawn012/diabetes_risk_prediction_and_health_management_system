import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../common/loaders/loaders.dart';
import '../../../../data/repositories/community/post_report_repository.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../../utils/validators/report_validator.dart';

class ReportPostDialog extends StatefulWidget {
  final String postId;

  const ReportPostDialog({
    super.key,
    required this.postId,
  });

  @override
  State<ReportPostDialog> createState() => _ReportPostDialogState();
}

class _ReportPostDialogState extends State<ReportPostDialog> {
  final _formKey = GlobalKey<FormState>();
  final _additionalNoteController = TextEditingController();
  final _reportRepo = Get.put(PostReportRepository());

  ReportReason? _selectedReason;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _additionalNoteController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedReason == null) {
      TLoaders.warningSnackBar(
        title: 'Select Reason',
        message: 'Please select a reason for reporting',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final error = await _reportRepo.submitReport(
        postId: widget.postId,
        reason: _selectedReason!,
        additionalNote: _selectedReason == ReportReason.other
            ? _additionalNoteController.text.trim()
            : null,
      );

      if (error != null) {
        TLoaders.warningSnackBar(
          title: 'Already Reported',
          message: error,
        );
      } else {
        TLoaders.successSnackBar(
          title: 'Report Submitted',
          message: 'Thank you for helping keep our community safe.',
        );
        if (Get.context != null) {
          Navigator.of(Get.context!, rootNavigator: true).pop(true);
        }
      }
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to submit report. Please try again.',
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    final isWeb = THelperFunctions.screenWidth() > 600;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: isWeb ? 500 : double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: isDark ? TColors.dark : TColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              _buildHeader(isDark),

              Divider(
                color: isDark ? TColors.darkGrey : TColors.grey,
                height: 1,
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info message
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: TColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: TColors.info.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.info_circle_bold,
                              color: TColors.info,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Help us understand what\'s wrong with this post',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? TColors.lightGrey : TColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Reason selection
                      Text(
                        'Select a reason',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? TColors.white : TColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 12),

                      ...ReportReason.values.map((reason) {
                        return _buildReasonOption(reason, isDark);
                      }).toList(),

                      // Additional note for "Other" reason
                      if (_selectedReason == ReportReason.other) ...[
                        SizedBox(height: 24),
                        Text(
                          'Additional details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? TColors.white : TColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          controller: _additionalNoteController,
                          maxLines: 4,
                          maxLength: 500,
                          decoration: InputDecoration(
                            hintText: 'Please provide more details...',
                            hintStyle: TextStyle(
                              color: isDark ? TColors.darkGrey : TColors.textSecondary,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? TColors.darkGrey.withOpacity(0.3)
                                : TColors.lightGrey,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? TColors.darkGrey.withOpacity(0.5)
                                    : TColors.grey,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: TColors.primary,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: TColors.error,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: TColors.error,
                                width: 2,
                              ),
                            ),
                          ),
                          style: TextStyle(
                            color: isDark ? TColors.white : TColors.textPrimary,
                          ),
                          validator: (value) => ReportValidator.validateAdditionalNote(
                            value,
                            _selectedReason,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              Divider(
                color: isDark ? TColors.darkGrey : TColors.grey,
                height: 1,
              ),

              // Footer buttons
              _buildFooter(isDark, isWeb),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: TColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.warning_2_bold,
              color: TColors.error,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report Post',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? TColors.white : TColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Help us keep the community safe',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? TColors.darkGrey : TColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Get.back(),
            icon: Icon(
              Iconsax.close_circle_bold,
              color: isDark ? TColors.darkGrey : TColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonOption(ReportReason reason, bool isDark) {
    final isSelected = _selectedReason == reason;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedReason = reason;
              if (reason != ReportReason.other) {
                _additionalNoteController.clear();
              }
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? TColors.primary.withOpacity(0.1)
                  : (isDark ? TColors.darkGrey.withOpacity(0.3) : TColors.lightGrey),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? TColors.primary
                    : (isDark ? TColors.darkGrey : TColors.grey),
                width: isSelected ? 2 : 1,
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
                    reason.displayName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? TColors.primary
                          : (isDark ? TColors.white : TColors.textPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDark, bool isWeb) {
    return Container(
      padding: EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : () => Get.back(),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: isDark ? TColors.darkGrey : TColors.grey,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? TColors.white : TColors.textPrimary,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.error,
                foregroundColor: TColors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: TColors.error.withOpacity(0.5),
              ),
              child: _isSubmitting
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(TColors.white),
                ),
              )
                  : Text(
                'Submit Report',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}