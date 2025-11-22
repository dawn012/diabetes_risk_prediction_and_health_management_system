import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../utils/constants/admin_colors.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../../utils/validators/achievement_validator.dart';
import '../../../achievement/models/achievement_model.dart';
import '../../controllers/achievement_management_controller.dart';

class EditAchievementDialog extends StatelessWidget {
  final AchievementModel achievement;
  final AchievementManagementController controller;

  const EditAchievementDialog({
    super.key,
    required this.achievement,
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
                    key: controller.editFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Field
                        _buildTitleField(darkMode),

                        SizedBox(height: 20),

                        // Description Field
                        _buildTextField(
                          label: 'Description',
                          controller: controller.editDescriptionController,
                          darkMode: darkMode,
                          maxLines: 3,
                          validator: (value) => AchievementValidator.validateDescription(value),
                        ),

                        SizedBox(height: 20),

                        // Achievement Type
                        _buildTypeSelector(darkMode),

                        SizedBox(height: 20),

                        // Icon Selector
                        _buildIconSelector(darkMode, isWeb),

                        SizedBox(height: 20),

                        // Levels Section
                        _buildLevelsSection(darkMode, isWeb),
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
            Iconsax.edit_bold,
            color: TAdminColors.primary,
            size: isWeb ? 28 : 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Edit Achievement',
              style: TextStyle(
                fontSize: isWeb ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: TAdminColors.getOnSurfaceColor(darkMode),
              ),
            ),
          ),
          IconButton(
            onPressed: () => Get.back(),
            icon: Icon(
              Iconsax.close_circle_bold,
              color: TAdminColors.getOnSurfaceVariantColor(darkMode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField(bool darkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievement Title',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: TAdminColors.getOnSurfaceColor(darkMode),
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller.editTitleController,
          validator: (value) {
            final basicError = AchievementValidator.validateAchievementTitle(value);
            if (basicError != null) return basicError;

            // duplication error
            if (controller.editTitleDuplicationError.value.isNotEmpty) {
              return controller.editTitleDuplicationError.value;
            }

            return null;
          },
          style: TextStyle(
            color: TAdminColors.getOnSurfaceColor(darkMode),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: TAdminColors.getSurfaceVariantColor(darkMode),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: TAdminColors.getBorderColor(darkMode),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: TAdminColors.getBorderColor(darkMode),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: TAdminColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: TAdminColors.error,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool darkMode,
    int maxLines = 1,
    String? Function(String?)? validator,
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
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
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
                color: TAdminColors.getBorderColor(darkMode),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: TAdminColors.getBorderColor(darkMode),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: TAdminColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: TAdminColors.error,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector(bool darkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievement Type',
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
            child: DropdownButton<AchievementType>(
              value: controller.editSelectedType.value,
              isExpanded: true,
              onChanged: (value) {
                if (value != null) {
                  controller.editSelectedType.value = value;
                }
              },
              items: [
                DropdownMenuItem(
                  value: AchievementType.periodic,
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.calendar_bold,
                        size: 18,
                        color: TAdminColors.warning,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Monthly Achievement',
                        style: TextStyle(
                          color: TAdminColors.getOnSurfaceColor(darkMode),
                        ),
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: AchievementType.permanent,
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.award_bold,
                        size: 18,
                        color: TAdminColors.primary,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Permanent Achievement',
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

  Widget _buildIconSelector(bool darkMode, bool isWeb) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievement Icon',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: TAdminColors.getOnSurfaceColor(darkMode),
          ),
        ),
        SizedBox(height: 8),

        // Preset Icons + Custom Icon
        Obx(() {
          final List<Widget> iconBoxes = [];

          // 首先添加当前选中的图标（确保它在最前面）
          final currentIconCodePoint = controller.editSelectedIconCodePoint.value;
          final isCurrentIconPreset = controller.editPresetIcons.contains(currentIconCodePoint);

          if (!isCurrentIconPreset && currentIconCodePoint != 0) {
            // 如果当前图标不是预设图标，添加为自定义图标
            iconBoxes.add(_buildIconBox(
              IconData(currentIconCodePoint, fontFamily: 'MaterialIcons'),
              currentIconCodePoint,
              darkMode,
              isCustom: true,
            ));
          }

          // 添加预设图标
          for (var codePoint in controller.editPresetIcons) {
            iconBoxes.add(_buildIconBox(
              IconData(codePoint, fontFamily: 'MaterialIcons'),
              codePoint,
              darkMode,
            ));
          }

          // 添加自定义图标（如果有且不是当前图标）
          if (controller.editCustomIconCodePoint.value != null &&
              controller.editCustomIconCodePoint.value != currentIconCodePoint) {
            iconBoxes.add(_buildIconBox(
              IconData(controller.editCustomIconCodePoint.value!, fontFamily: 'MaterialIcons'),
              controller.editCustomIconCodePoint.value!,
              darkMode,
              isCustom: true,
            ));
          }

          // 添加"Add Icon"按钮
          iconBoxes.add(_buildAddIconBox(darkMode));

          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: iconBoxes,
          );
        }),
      ],
    );
  }

  Widget _buildIconBox(IconData icon, int codePoint, bool darkMode, {bool isCustom = false}) {
    return Obx(() {
      final isSelected = controller.editSelectedIconCodePoint.value == codePoint;

      return GestureDetector(
        onTap: () {
          controller.editSelectedIconCodePoint.value = codePoint;
        },
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isSelected
                ? TAdminColors.primary.withOpacity(0.15)
                : TAdminColors.getSurfaceVariantColor(darkMode),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? TAdminColors.primary
                  : TAdminColors.getBorderColor(darkMode),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 28,
              color: isSelected
                  ? TAdminColors.primary
                  : TAdminColors.getOnSurfaceVariantColor(darkMode),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildAddIconBox(bool darkMode) {
    return GestureDetector(
      onTap: () => _showIconPicker(darkMode),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: TAdminColors.getSurfaceVariantColor(darkMode),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: TAdminColors.getBorderColor(darkMode),
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Icon(
            Iconsax.add_bold,
            size: 28,
            color: TAdminColors.primary,
          ),
        ),
      ),
    );
  }

  void _showIconPicker(bool darkMode) {
    final searchController = TextEditingController();
    final filteredIcons = <MapEntry<String, IconData>>[].obs;

    // Common Material Icons with their names
    final allIcons = <String, IconData>{
      'trophy': Icons.emoji_events,
      'star': Icons.star,
      'star_border': Icons.star_border,
      'star_half': Icons.star_half,
      'star_rate': Icons.star_rate,
      'heart': Icons.favorite,
      'heart_border': Icons.favorite_border,
      'fire': Icons.local_fire_department,
      'premium': Icons.workspace_premium,
      'medal': Icons.military_tech,
      'celebration': Icons.celebration,
      'verified': Icons.verified,
      'crown': Icons.diamond,
      'shield': Icons.shield,
      'bolt': Icons.bolt,
      'grade': Icons.grade,
      'emoji_emotions': Icons.emoji_emotions,
      'whatshot': Icons.whatshot,
      'trending_up': Icons.trending_up,
      'rocket': Icons.rocket_launch,
      'spa': Icons.spa,
      'fitness': Icons.fitness_center,
      'run': Icons.directions_run,
      'dining': Icons.local_dining,
      'sports': Icons.sports,
      'sports_soccer': Icons.sports_soccer,
      'sports_basketball': Icons.sports_basketball,
      'sports_football': Icons.sports_football,
      'music_note': Icons.music_note,
      'palette': Icons.palette,
      'camera': Icons.camera_alt,
      'book': Icons.book,
      'school': Icons.school,
      'lightbulb': Icons.lightbulb,
      'thumb_up': Icons.thumb_up,
      'flag': Icons.flag,
      'auto_awesome': Icons.auto_awesome,
      'layers': Icons.layers,
      'extension': Icons.extension,
      'beach': Icons.beach_access,
      'cake': Icons.cake,
      'coffee': Icons.local_cafe,
      'restaurant': Icons.restaurant,
      'hotel': Icons.hotel,
      'flight': Icons.flight,
      'code': Icons.code,
      'computer': Icons.computer,
      'phone': Icons.phone_iphone,
      'home': Icons.home,
      'work': Icons.work,
      'person': Icons.person,
      'group': Icons.group,
      'settings': Icons.settings,
      'done': Icons.done,
      'check_circle': Icons.check_circle,
      'flash_on': Icons.flash_on,
      'eco': Icons.eco,
      'nature': Icons.nature,
      'pets': Icons.pets,
      'face': Icons.face,
      'self_improvement': Icons.self_improvement,
      'psychology': Icons.psychology,
      'mood': Icons.mood,
      'insert_emoticon': Icons.insert_emoticon,
      'sentiment_satisfied': Icons.sentiment_satisfied,
    };

    // Initialize with all icons
    filteredIcons.value = allIcons.entries.toList();

    // Search filter
    void filterIcons(String query) {
      if (query.isEmpty) {
        filteredIcons.value = allIcons.entries.toList();
      } else {
        final lowercaseQuery = query.toLowerCase();
        filteredIcons.value = allIcons.entries
            .where((entry) => entry.key.toLowerCase().contains(lowercaseQuery))
            .toList();
      }
    }

    showDialog(
      context: Get.context!,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 500,
          height: 600,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: TAdminColors.getSurfaceColor(darkMode),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Iconsax.search_normal_bold,
                    color: TAdminColors.primary,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select Icon',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: TAdminColors.getOnSurfaceColor(darkMode),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(
                      Iconsax.close_circle_bold,
                      color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Search Field
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search icons...',
                  prefixIcon: Icon(Iconsax.search_normal_1_bold),
                  filled: true,
                  fillColor: TAdminColors.getSurfaceVariantColor(darkMode),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(
                  color: TAdminColors.getOnSurfaceColor(darkMode),
                ),
                onChanged: filterIcons,
              ),

              SizedBox(height: 16),

              // Icons Grid
              Expanded(
                child: Obx(() {
                  if (filteredIcons.isEmpty) {
                    return Center(
                      child: Text(
                        'No icons found',
                        style: TextStyle(
                          color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filteredIcons.length,
                    itemBuilder: (context, index) {
                      final iconEntry = filteredIcons[index];
                      final iconData = iconEntry.value;

                      return GestureDetector(
                        onTap: () {
                          // Replace or add custom icon
                          controller.editCustomIconCodePoint.value = iconData.codePoint;
                          controller.editSelectedIconCodePoint.value = iconData.codePoint;
                          Get.back();
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: TAdminColors.getSurfaceVariantColor(darkMode),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: TAdminColors.getBorderColor(darkMode),
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  iconData,
                                  size: 28,
                                  color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                                ),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              iconEntry.key,
                              style: TextStyle(
                                fontSize: 10,
                                color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelsSection(bool darkMode, bool isWeb) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievement Levels',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: TAdminColors.getOnSurfaceColor(darkMode),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Unit and level type cannot be changed. You can only modify criteria and points.',
          style: TextStyle(
            fontSize: 12,
            color: TAdminColors.getOnSurfaceVariantColor(darkMode),
            fontStyle: FontStyle.italic,
          ),
        ),
        SizedBox(height: 12),

        Obx(() => Column(
          children: controller.editLevels.asMap().entries.map((entry) {
            final index = entry.key;
            final level = entry.value;

            return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TAdminColors.getSurfaceVariantColor(darkMode),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: TAdminColors.getBorderColor(darkMode),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getLevelIcon(level.level),
                        size: 20,
                        color: _getLevelColor(level.level),
                      ),
                      SizedBox(width: 8),
                      Text(
                        level.level.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: TAdminColors.getOnSurfaceColor(darkMode),
                        ),
                      ),
                      Spacer(),
                      Text(
                        level.criteriaUnit,
                        style: TextStyle(
                          fontSize: 12,
                          color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Container(
                    height: 110,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildLevelField(
                            label: 'Criteria',
                            value: level.criteria.toString(),
                            onChanged: (value) {
                              final intValue = int.tryParse(value);
                              if (intValue != null) {
                                controller.updateLevelCriteria(index, intValue);
                              }
                            },
                            darkMode: darkMode,
                            validator: (value) => AchievementValidator.validateCriteria(int.tryParse(value ?? '')),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildLevelField(
                            label: 'Points',
                            value: level.points.toString(),
                            onChanged: (value) {
                              final intValue = int.tryParse(value);
                              if (intValue != null) {
                                controller.updateLevelPoints(index, intValue);
                              }
                            },
                            darkMode: darkMode,
                            validator: (value) => AchievementValidator.validatePoints(int.tryParse(value ?? '')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        )),
      ],
    );
  }

  Widget _buildLevelField({
    required String label,
    required String value,
    required Function(String) onChanged,
    required bool darkMode,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: TAdminColors.getOnSurfaceVariantColor(darkMode),
          ),
        ),
        SizedBox(height: 4),
        TextFormField(
          initialValue: value,
          keyboardType: TextInputType.number,
          onChanged: onChanged,
          validator: validator,
          inputFormatters: [
            // Only allow numbers
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: TextStyle(
            color: TAdminColors.getOnSurfaceColor(darkMode),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: TAdminColors.getSurfaceColor(darkMode),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: TAdminColors.getBorderColor(darkMode),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: TAdminColors.getBorderColor(darkMode),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: TAdminColors.primary,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: TAdminColors.error,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
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
              onPressed: () => Get.back(),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: isWeb ? 18 : 14),
              ),
              child: Text('Cancel'),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: controller.editIsLoading.value ? null : () => controller.handleSaveEdit(achievement),
              style: ElevatedButton.styleFrom(
                backgroundColor: TAdminColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isWeb ? 18 : 14),
              ),
              child: controller.editIsLoading.value
                  ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Text('Save Changes'),
            ),
          ),
        ],
      ),
    ));
  }

  IconData _getLevelIcon(AchievementLevel level) {
    switch (level) {
      case AchievementLevel.bronze:
        return Iconsax.medal_bold;
      case AchievementLevel.silver:
        return Iconsax.medal_star_bold;
      case AchievementLevel.gold:
        return Iconsax.crown_1_bold;
      default:
        return Iconsax.award_bold;
    }
  }

  Color _getLevelColor(AchievementLevel level) {
    switch (level) {
      case AchievementLevel.bronze:
        return const Color(0xFFCD7F32);
      case AchievementLevel.silver:
        return const Color(0xFFC0C0C0);
      case AchievementLevel.gold:
        return const Color(0xFFFFD700);
      default:
        return TAdminColors.primary;
    }
  }
}