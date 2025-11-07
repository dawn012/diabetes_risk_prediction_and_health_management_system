import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/helpers/helper_functions.dart';

class WaterInfoDialog extends StatelessWidget {
  const WaterInfoDialog({super.key, this.age, this.gender});

  final int? age;
  final String? gender;

  // Determine which age group should be highlighted based on age and gender
  String? _getHighlightedAgeGroup(int? age, String? gender) {
    if (age == null || gender == null) return null;

    final isMale = gender.toLowerCase().contains('male') ||
        gender.toLowerCase().contains('boy') ||
        gender.toLowerCase().contains('man');
    final isFemale = gender.toLowerCase().contains('female') ||
        gender.toLowerCase().contains('girl') ||
        gender.toLowerCase().contains('woman');

    if (age >= 9 && age <= 13) {
      if (isMale) return 'Boys 9–13 years';
      if (isFemale) return 'Girls 9–13 years';
    } else if (age >= 14 && age <= 18) {
      if (isMale) return 'Boys 14–18 years';
      if (isFemale) return 'Girls 14–18 years';
    } else if (age >= 19) {
      if (isMale) return 'Men 19 years+';
      if (isFemale) return 'Women 19 years+';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);
    final isWeb = THelperFunctions.screenWidth() > 600;

    final userAge = age;
    final highlightedGroup = _getHighlightedAgeGroup(userAge, gender);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isWeb ? 500 : double.infinity,
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: darkMode ? TColors.dark : TColors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: darkMode
                      ? [Color(0xFF1E88E5), Color(0xFF1565C0)]
                      : [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.local_drink,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Recommended Water Intake',
                      style: TextStyle(
                        fontSize: isWeb ? 20 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Introduction
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: darkMode
                            ? Color(0xFF1E3A5F).withOpacity(0.4)
                            : Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: darkMode
                              ? Color(0xFF42A5F5).withOpacity(0.3)
                              : Color(0xFF90CAF9).withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: darkMode ? Color(0xFF64B5F6) : Color(0xFF1976D2),
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Water needs vary by age and gender. Here are the recommended daily water intake according to Better Health Channel.',
                              style: TextStyle(
                                fontSize: 14,
                                color: darkMode ? Color(0xFFE1E1E1) : Color(0xFF424242),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Boys/Men Section
                    _buildSectionHeader('Boys', Icons.male, darkMode),

                    SizedBox(height: 12),

                    _buildAgeGroupCard(
                      ageGroup: 'Boys 9–13 years',
                      recommended: '1.6 litres (about 7 cups)',
                      icon: Icons.child_care,
                      colorIndex: 0,
                      darkMode: darkMode,
                      isHighlighted: highlightedGroup == 'Boys 9–13 years',
                      isMale: true,
                    ),

                    SizedBox(height: 8),

                    _buildAgeGroupCard(
                      ageGroup: 'Boys 14–18 years',
                      recommended: '1.9 litres (about 8 cups)',
                      icon: Icons.emoji_people,
                      colorIndex: 1,
                      darkMode: darkMode,
                      isHighlighted: highlightedGroup == 'Boys 14–18 years',
                      isMale: true,
                    ),

                    SizedBox(height: 8),

                    _buildAgeGroupCard(
                      ageGroup: 'Men 19 years+',
                      recommended: '2.6 litres (about 11 cups)',
                      icon: Icons.person,
                      colorIndex: 2,
                      darkMode: darkMode,
                      isHighlighted: highlightedGroup == 'Men 19 years+',
                      isMale: true,
                    ),

                    SizedBox(height: 24),

                    // Girls/Women Section
                    _buildSectionHeader('Girls', Icons.female, darkMode),

                    SizedBox(height: 12),

                    _buildAgeGroupCard(
                      ageGroup: 'Girls 9–13 years',
                      recommended: '1.4 litres (about 6 cups)',
                      icon: Icons.child_friendly,
                      colorIndex: 0,
                      darkMode: darkMode,
                      isHighlighted: highlightedGroup == 'Girls 9–13 years',
                      isMale: false,
                    ),

                    SizedBox(height: 8),

                    _buildAgeGroupCard(
                      ageGroup: 'Girls 14–18 years',
                      recommended: '1.6 litres (about 7 cups)',
                      icon: Icons.emoji_people,
                      colorIndex: 1,
                      darkMode: darkMode,
                      isHighlighted: highlightedGroup == 'Girls 14–18 years',
                      isMale: false,
                    ),

                    SizedBox(height: 8),

                    _buildAgeGroupCard(
                      ageGroup: 'Women 19 years+',
                      recommended: '2.1 litres (about 9 cups)',
                      icon: Icons.person,
                      colorIndex: 2,
                      darkMode: darkMode,
                      isHighlighted: highlightedGroup == 'Women 19 years+',
                      isMale: false,
                    ),

                    SizedBox(height: 24),

                    // Source Badge
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: darkMode
                              ? [
                            Color(0xFF1E3A5F).withOpacity(0.4),
                            Color(0xFF1A2F4A).withOpacity(0.4),
                          ]
                              : [
                            Color(0xFFE3F2FD),
                            Color(0xFFBBDEFB),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: darkMode
                              ? Color(0xFF42A5F5).withOpacity(0.3)
                              : Color(0xFF90CAF9).withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: darkMode
                                      ? Color(0xFF1E88E5).withOpacity(0.3)
                                      : Color(0xFF64B5F6).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.verified,
                                  size: 18,
                                  color: darkMode ? Color(0xFF64B5F6) : Color(0xFF1976D2),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Verified Source',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: darkMode
                                            ? Color(0xFFB0B0B0)
                                            : Color(0xFF757575),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Better Health Channel',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: darkMode ? Color(0xFF64B5F6) : Color(0xFF1976D2),
                                      ),
                                    ),
                                    Text(
                                      'Victoria State Government',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: darkMode
                                            ? Color(0xFFE1E1E1)
                                            : Color(0xFF424242),
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: darkMode
                                  ? Color(0xFF2C2C2C).withOpacity(0.5)
                                  : Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  size: 16,
                                  color: darkMode ? Color(0xFFFFB74D) : Color(0xFFF57C00),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Individual water needs may vary based on activity level, climate, and health conditions.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: darkMode
                                          ? Color(0xFFB0B0B0)
                                          : Color(0xFF616161),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: darkMode
                        ? Color(0xFF424242)
                        : Color(0xFFE0E0E0),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkMode
                        ? Color(0xFF424242)
                        : Color(0xFFF5F5F5),
                    foregroundColor: darkMode ? Color(0xFFE1E1E1) : Color(0xFF212121),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Got it',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 获取颜色方案
  Map<String, Color> _getColorScheme(bool isMale, int colorIndex, bool darkMode) {
    if (isMale) {
      // 男性使用蓝色系
      if (darkMode) {
        final colors = [
          {'bg': Color(0xFF1E3A5F), 'border': Color(0xFF2196F3), 'icon': Color(0xFF64B5F6), 'text': Color(0xFF90CAF9)},
          {'bg': Color(0xFF1A2F4A), 'border': Color(0xFF1E88E5), 'icon': Color(0xFF42A5F5), 'text': Color(0xFF64B5F6)},
          {'bg': Color(0xFF0D1F35), 'border': Color(0xFF1976D2), 'icon': Color(0xFF2196F3), 'text': Color(0xFF42A5F5)},
        ];
        return colors[colorIndex];
      } else {
        final colors = [
          {'bg': Color(0xFFE3F2FD), 'border': Color(0xFF2196F3), 'icon': Color(0xFF1976D2), 'text': Color(0xFF1565C0)},
          {'bg': Color(0xFFBBDEFB), 'border': Color(0xFF1E88E5), 'icon': Color(0xFF1565C0), 'text': Color(0xFF0D47A1)},
          {'bg': Color(0xFF90CAF9), 'border': Color(0xFF1976D2), 'icon': Color(0xFF0D47A1), 'text': Color(0xFF01579B)},
        ];
        return colors[colorIndex];
      }
    } else {
      // 女性使用紫色/粉色系
      if (darkMode) {
        final colors = [
          {'bg': Color(0xFF3A1E5F), 'border': Color(0xFFAB47BC), 'icon': Color(0xFFBA68C8), 'text': Color(0xFFCE93D8)},
          {'bg': Color(0xFF2F1A4A), 'border': Color(0xFF9C27B0), 'icon': Color(0xFFAB47BC), 'text': Color(0xFFBA68C8)},
          {'bg': Color(0xFF1F0D35), 'border': Color(0xFF8E24AA), 'icon': Color(0xFF9C27B0), 'text': Color(0xFFAB47BC)},
        ];
        return colors[colorIndex];
      } else {
        final colors = [
          {'bg': Color(0xFFF3E5F5), 'border': Color(0xFFAB47BC), 'icon': Color(0xFF8E24AA), 'text': Color(0xFF7B1FA2)},
          {'bg': Color(0xFFE1BEE7), 'border': Color(0xFF9C27B0), 'icon': Color(0xFF7B1FA2), 'text': Color(0xFF6A1B9A)},
          {'bg': Color(0xFFCE93D8), 'border': Color(0xFF8E24AA), 'icon': Color(0xFF6A1B9A), 'text': Color(0xFF4A148C)},
        ];
        return colors[colorIndex];
      }
    }
  }

  Widget _buildSectionHeader(String title, IconData icon, bool darkMode) {
    final isMale = title == 'Boys';
    final color = isMale
        ? (darkMode ? Color(0xFF64B5F6) : Color(0xFF1976D2))
        : (darkMode ? Color(0xFFBA68C8) : Color(0xFF8E24AA));

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: darkMode
            ? color.withOpacity(0.2)
            : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: darkMode
              ? color.withOpacity(0.4)
              : color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeGroupCard({
    required String ageGroup,
    required String recommended,
    required IconData icon,
    required int colorIndex,
    required bool darkMode,
    required bool isMale,
    bool isHighlighted = false,
  }) {
    final colorScheme = _getColorScheme(isMale, colorIndex, darkMode);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted
            ? colorScheme['bg']!.withOpacity(darkMode ? 0.4 : 0.5)
            : colorScheme['bg']!.withOpacity(darkMode ? 0.25 : 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted
              ? colorScheme['border']!
              : colorScheme['border']!.withOpacity(darkMode ? 0.3 : 0.4),
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme['icon']!.withOpacity(darkMode ? 0.2 : 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: colorScheme['icon']!,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ageGroup,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: darkMode ? Color(0xFFE1E1E1) : Color(0xFF212121),
                        ),
                      ),
                    ),
                    if (isHighlighted)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme['border']!,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Your Profile',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.water_drop,
                      size: 14,
                      color: colorScheme['text']!,
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Recommended: ',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: darkMode ? Color(0xFFB0B0B0) : Color(0xFF616161),
                              ),
                            ),
                            TextSpan(
                              text: recommended,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: colorScheme['text']!,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> show({int? age, String? gender}) async {
    Get.dialog(
      WaterInfoDialog(age: age, gender: gender),
      barrierDismissible: true,
    );
  }
}