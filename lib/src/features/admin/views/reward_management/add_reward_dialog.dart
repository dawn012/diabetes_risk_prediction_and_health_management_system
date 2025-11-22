import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../utils/constants/admin_colors.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/reward_management_controller.dart';

class AddRewardDialog extends StatelessWidget {
  final RewardManagementController controller;

  const AddRewardDialog({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);
    final isWeb = THelperFunctions.screenWidth() > 600;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isWeb ? 700 : 400,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: TAdminColors.getSurfaceColor(darkMode),
            borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              _buildHeader(darkMode, isWeb),

              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isWeb ? 24 : 20),
                  child: Form(
                    key: controller.addFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Field
                        _buildTextField(
                          label: 'Reward Title',
                          controller: controller.addTitleController,
                          darkMode: darkMode,
                          error: controller.addTitleError,
                          onChanged: (_) => controller.validateAddField('title'),
                        ),

                        SizedBox(height: 20),

                        // Description Field
                        _buildTextField(
                          label: 'Description',
                          controller: controller.addDescriptionController,
                          darkMode: darkMode,
                          maxLines: 3,
                          error: controller.addDescriptionError,
                          onChanged: (_) => controller.validateAddField('description'),
                        ),

                        SizedBox(height: 20),

                        // Reward Type Selector
                        _buildTypeSelector(darkMode),

                        SizedBox(height: 20),

                        // Cost Points and Quantity Row
                        _buildNumberFieldsRow(darkMode),

                        SizedBox(height: 20),

                        // Image Upload Section
                        _buildImageUploadSection(context, darkMode, isWeb),
                      ],
                    ),
                  ),
                ),
              ),

              // Footer
              _buildFooter(darkMode, isWeb),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool darkMode, bool isWeb) {
    return Container(
      padding: EdgeInsets.all(isWeb ? 24 : 20),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceVariantColor(darkMode),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isWeb ? 20 : 16),
          topRight: Radius.circular(isWeb ? 20 : 16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.add_circle_bold,
            color: TAdminColors.primary,
            size: isWeb ? 28 : 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Add New Reward',
              style: TextStyle(
                fontSize: isWeb ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: TAdminColors.getOnSurfaceColor(darkMode),
              ),
            ),
          ),
          IconButton(
            onPressed: () => controller.closeAddDialog(),
            icon: Icon(
              Iconsax.close_circle_bold,
              color: TAdminColors.getOnSurfaceVariantColor(darkMode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool darkMode,
    int maxLines = 1,
    TextInputType? keyboardType,
    required Rx<String?> error,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: TAdminColors.getOnSurfaceColor(darkMode),
          ),
        ),
        SizedBox(height: 8),
        Obx(() => TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: TextStyle(
            color: TAdminColors.getOnSurfaceColor(darkMode),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: TAdminColors.getSurfaceVariantColor(darkMode),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: error.value != null
                    ? TAdminColors.error
                    : TAdminColors.getBorderColor(darkMode),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: error.value != null
                    ? TAdminColors.error
                    : TAdminColors.getBorderColor(darkMode),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: error.value != null
                    ? TAdminColors.error
                    : TAdminColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: TAdminColors.error,
              ),
            ),
            errorText: error.value,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        )),
      ],
    );
  }

  Widget _buildNumberFieldsRow(bool darkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Labels Row
        Row(
          children: [
            Expanded(
              child: Text(
                'Cost Points',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: TAdminColors.getOnSurfaceColor(darkMode),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Available Quantity (Optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: TAdminColors.getOnSurfaceColor(darkMode),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),

        // Fields Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start, // 确保错误信息对齐
          children: [
            Expanded(
              child: _buildNumberField(
                label: 'Cost Points',
                controller: controller.addCostPointsController,
                darkMode: darkMode,
                error: controller.addCostPointsError,
                onChanged: (_) => controller.validateAddField('costPoints'),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildNumberField(
                label: 'Available Quantity (Optional)',
                controller: controller.addAvailableQuantityController,
                darkMode: darkMode,
                error: controller.addQuantityError,
                onChanged: (_) => controller.validateAddField('quantity'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    required bool darkMode,
    required Rx<String?> error,
    Function(String)? onChanged,
  }) {
    return Obx(() => TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly, // 只允许输入数字
      ],
      style: TextStyle(
        color: TAdminColors.getOnSurfaceColor(darkMode),
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: TAdminColors.getSurfaceVariantColor(darkMode),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: error.value != null
                ? TAdminColors.error
                : TAdminColors.getBorderColor(darkMode),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: error.value != null
                ? TAdminColors.error
                : TAdminColors.getBorderColor(darkMode),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: error.value != null
                ? TAdminColors.error
                : TAdminColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: TAdminColors.error,
          ),
        ),
        errorText: error.value,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        // 隐藏标签，因为我们在外面已经显示了
        labelText: null,
      ),
    ));
  }

  Widget _buildTypeSelector(bool darkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reward Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: TAdminColors.getOnSurfaceColor(darkMode),
          ),
        ),
        SizedBox(height: 8),
        Obx(() => Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: TAdminColors.getSurfaceVariantColor(darkMode),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: TAdminColors.getBorderColor(darkMode),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<RewardType>(
              value: controller.addSelectedType.value,
              isExpanded: true,
              hint: Text(
                'Select reward type',
                style: TextStyle(
                  color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                ),
              ),
              onChanged: (value) {
                if (value != null) {
                  controller.addSelectedType.value = value;
                }
              },
              items: [
                DropdownMenuItem(
                  value: RewardType.avatarFrame,
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.frame_bold,
                        size: 18,
                        color: TAdminColors.primary,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Avatar Frame',
                        style: TextStyle(
                          color: TAdminColors.getOnSurfaceColor(darkMode),
                        ),
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: RewardType.virtualItem,
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.medal_bold,
                        size: 18,
                        color: TAdminColors.warning,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Virtual Item',
                        style: TextStyle(
                          color: TAdminColors.getOnSurfaceColor(darkMode),
                        ),
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: RewardType.coupon,
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.ticket_discount_bold,
                        size: 18,
                        color: TAdminColors.success,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Coupon',
                        style: TextStyle(
                          color: TAdminColors.getOnSurfaceColor(darkMode),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              dropdownColor: TAdminColors.getSurfaceColor(darkMode),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildImageUploadSection(BuildContext context, bool darkMode, bool isWeb) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reward Image',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: TAdminColors.getOnSurfaceColor(darkMode),
          ),
        ),
        SizedBox(height: 8),
        Obx(() {
          if (controller.addSelectedImageBytes.value != null) {
            return _buildImagePreview(darkMode);
          } else {
            return _buildImageUploadButton(darkMode);
          }
        }),
        Obx(() {
          if (controller.addImageError.value != null) {
            return Padding(
              padding: const EdgeInsets.only(top: 8, left: 13),
              child: Text(
                controller.addImageError.value!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    height: 1.3,
                    fontWeight: FontWeight.w500
                ),
              ),
            );
          }
          return SizedBox.shrink();
        })
      ],
    );
  }

  Widget _buildImageUploadButton(bool darkMode) {
    return InkWell(
      onTap: () => controller.pickAddRewardImage(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: TAdminColors.getSurfaceVariantColor(darkMode),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: TAdminColors.getBorderColor(darkMode),
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.gallery_add_bold,
                size: 48,
                color: TAdminColors.primary,
              ),
              SizedBox(height: 12),
              Text(
                'Click to upload image',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: TAdminColors.getOnSurfaceColor(darkMode),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'PNG, JPG, WebP (Max 5MB)',
                style: TextStyle(
                  fontSize: 12,
                  color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(bool darkMode) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceVariantColor(darkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: TAdminColors.getBorderColor(darkMode),
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.memory(
                controller.addSelectedImageBytes.value!,
                height: 140,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => controller.pickAddRewardImage(),
                  icon: Icon(Iconsax.edit_bold, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: TAdminColors.warning.withOpacity(0.9),
                    foregroundColor: Colors.white,
                  ),
                  tooltip: 'Change image',
                ),
                SizedBox(width: 8),
                IconButton(
                  onPressed: () => controller.removeAddImage(),
                  icon: Icon(Iconsax.trash_bold, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: TAdminColors.error.withOpacity(0.9),
                    foregroundColor: Colors.white,
                  ),
                  tooltip: 'Remove image',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool darkMode, bool isWeb) {
    return Obx(() => Container(
      padding: EdgeInsets.all(isWeb ? 24 : 20),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceVariantColor(darkMode),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(isWeb ? 20 : 16),
          bottomRight: Radius.circular(isWeb ? 20 : 16),
        ),
        border: Border(
          top: BorderSide(
            color: TAdminColors.getBorderColor(darkMode),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => controller.closeAddDialog(),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: isWeb ? 18 : 14),
              ),
              child: Text('Cancel'),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: controller.addIsLoading.value
                  ? null
                  : () => controller.handleAddReward(),
              style: ElevatedButton.styleFrom(
                backgroundColor: TAdminColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isWeb ? 18 : 14),
              ),
              child: controller.addIsLoading.value
                  ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Text('Add Reward'),
            ),
          ),
        ],
      ),
    ));
  }
}