import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../common/widgets/appbar/appbar.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/update_single_field_controller.dart';

class EditSingleFieldScreen extends StatelessWidget {
  final String title;
  final String fieldName;
  final String currentValue;
  final TextInputType keyboardType;
  final String? prefix;
  final String? suffix;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;

  const EditSingleFieldScreen({
    super.key,
    required this.title,
    required this.fieldName,
    required this.currentValue,
    this.keyboardType = TextInputType.text,
    this.prefix,
    this.suffix,
    this.validator,
    this.inputFormatters,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    final singleFieldController = Get.put(UpdateSingleFieldController());

    // 初始化编辑字段状态
    singleFieldController.initEditField(
      title,
      fieldName,
      currentValue,
      keyboardType: keyboardType,
      prefix: prefix,
      suffix: suffix,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
    );

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await singleFieldController.checkEditFieldPopConditions();
          if (shouldPop) {
            singleFieldController.disposeEditField();
            Get.back();
          }
        }
      },
      child: Scaffold(
        appBar: TAppBar(
          showBackArrow: true,
          title: Text('Edit $title'),
          customBackAction: () async {
            final shouldPop = await singleFieldController.checkEditFieldPopConditions();
            if (shouldPop) {
              singleFieldController.disposeEditField();
              Get.back();
            }
          },
          actions: [
            Obx(() => IconButton(
              onPressed: singleFieldController.editFieldHasChanges.value &&
                  !singleFieldController.editFieldIsSaving.value
                  ? () => singleFieldController.saveEditField()
                  : null,
              icon: singleFieldController.editFieldIsSaving.value
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(TColors.success),
                ),
              )
                  : Icon(
                Iconsax.tick_circle_bold,
                color: singleFieldController.editFieldHasChanges.value
                    ? TColors.success
                    : (THelperFunctions.isDarkMode(context)
                    ? TColors.darkGrey
                    : TColors.grey),
              ),
              tooltip: 'Save',
            )),
          ],
        ),
        body: _buildBody(context, singleFieldController),
        bottomNavigationBar: _buildBottomNavigationBar(context, singleFieldController),
      ),
    );
  }

  Widget _buildBody(BuildContext context, UpdateSingleFieldController controller) {
    final isDark = THelperFunctions.isDarkMode(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Form(
          key: controller.editFieldFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(TSizes.md),
                decoration: BoxDecoration(
                  color: TColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
                  border: Border.all(
                    color: TColors.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.info_circle_bold,
                      color: TColors.primary,
                      size: 20,
                    ),
                    SizedBox(width: TSizes.sm),
                    Expanded(
                      child: Text(
                        'Changes will be saved when you tap the ✓ button above',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: TColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: TSizes.spaceBtwSections),

              TextFormField(
                controller: controller.editFieldController,
                focusNode: controller.editFieldFocusNode,
                keyboardType: keyboardType,
                validator: validator,
                inputFormatters: inputFormatters,
                maxLength: maxLength,
                decoration: InputDecoration(
                  labelText: title,
                  prefixText: prefix,
                  suffixText: suffix,
                  counterText: '',
                ),
              ),

              SizedBox(height: TSizes.spaceBtwItems),

              _buildHelperText(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, UpdateSingleFieldController controller) {
    final isDark = THelperFunctions.isDarkMode(context);

    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(TSizes.md),
        decoration: BoxDecoration(
          color: isDark ? TColors.dark : TColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Obx(() => SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: controller.editFieldHasChanges.value &&
                !controller.editFieldIsSaving.value
                ? () => controller.saveEditField()
                : null,
            child: controller.editFieldIsSaving.value
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(TColors.white),
              ),
            )
                : Text('Save Changes'),
          ),
        )),
      ),
    );
  }

  Widget _buildHelperText(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);

    String? helperText;
    switch (fieldName) {
      case 'username':
        helperText = '• 3-30 characters\n• Letters, numbers, and underscores only';
        break;
      case 'phoneNumber':
        helperText = '• Format: 01XXXXXXXXX\n• 10-11 digits\n• Malaysian phone number';
        break;
      case 'height':
        helperText = '• In centimeters (cm)\n• Between 50 and 300 cm';
        break;
    }

    if (helperText == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(TSizes.sm),
      decoration: BoxDecoration(
        color: isDark
            ? TColors.darkContainer
            : TColors.lightContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
      ),
      child: Text(
        helperText,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isDark ? TColors.darkGrey : TColors.textSecondary,
        ),
      ),
    );
  }
}