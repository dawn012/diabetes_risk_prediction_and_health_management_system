import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/helpers/helper_functions.dart';

class SleepInfoDialog extends StatelessWidget {
  const SleepInfoDialog({super.key, this.age});

  final int? age;

  // Determine which age group should be highlighted
  String? _getHighlightedAgeGroup(int? age) {
    if (age == null) return null;

    if (age >= 6 && age <= 12) {
      return 'School Age (6–12 years)';
    } else if (age >= 13 && age <= 17) {
      return 'Teen (13–17 years)';
    } else if (age >= 18 && age <= 60) {
      return 'Adult (18–60 years)';
    } else if (age >= 61 && age <= 64) {
      return 'Adult (61–64 years)';
    } else if (age >= 65) {
      return 'Adult (65 years and older)';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);
    final isWeb = THelperFunctions.screenWidth() > 600;

    final userAge = age;
    final highlightedGroup = _getHighlightedAgeGroup(userAge);

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
                  colors: [
                    TColors.primary,
                    TColors.primary.withOpacity(0.8),
                  ],
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
                      Icons.bedtime,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Recommended Sleep Duration',
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
                        color: TColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: TColors.info.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: TColors.info,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Sleep needs vary by age. Here are the recommended sleep durations according to CDC.',
                              style: TextStyle(
                                fontSize: 14,
                                color: darkMode ? TColors.white : TColors.black,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Age Groups - Simplified
                    _buildAgeGroupCard(
                      ageGroup: 'School Age (6–12 years)',
                      recommended: '9–12 hours',
                      icon: Icons.menu_book,
                      color: Colors.blue,
                      darkMode: darkMode,
                      isHighlighted: highlightedGroup == 'School Age (6–12 years)',
                    ),

                    SizedBox(height: 12),

                    _buildAgeGroupCard(
                      ageGroup: 'Teen (13–17 years)',
                      recommended: '8–10 hours',
                      icon: Icons.person,
                      color: Colors.cyan,
                      darkMode: darkMode,
                      isHighlighted: highlightedGroup == 'Teen (13–17 years)',
                    ),

                    SizedBox(height: 12),

                    _buildAgeGroupCard(
                      ageGroup: 'Adult (18–60 years)',
                      recommended: '7 or more hours',
                      icon: Icons.work,
                      color: Colors.green,
                      darkMode: darkMode,
                      isHighlighted: highlightedGroup == 'Adult (18–60 years)',
                    ),

                    SizedBox(height: 12),

                    _buildAgeGroupCard(
                      ageGroup: 'Adult (61–64 years)',
                      recommended: '7–9 hours',
                      icon: Icons.work,
                      color: Colors.green,
                      darkMode: darkMode,
                      isHighlighted: highlightedGroup == 'Adult (61–64 years)',
                    ),

                    SizedBox(height: 12),

                    _buildAgeGroupCard(
                      ageGroup: 'Adult (65 years and older)',
                      recommended: '7–8 hours',
                      icon: Icons.elderly,
                      color: Colors.teal,
                      darkMode: darkMode,
                      isHighlighted: highlightedGroup == 'Adult (65 years and older)',
                    ),

                    SizedBox(height: 24),

                    // Source Badge - Redesigned
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            TColors.primary.withOpacity(0.1),
                            TColors.secondary.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: TColors.primary.withOpacity(0.3),
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
                                  color: TColors.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.verified,
                                  size: 18,
                                  color: TColors.primary,
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
                                            ? TColors.darkGrey
                                            : TColors.darkerGrey,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'CDC',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: TColors.primary,
                                      ),
                                    ),
                                    Text(
                                      'Centers for Disease Control\nand Prevention',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: darkMode
                                            ? TColors.white
                                            : TColors.black,
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
                                  ? TColors.darkerGrey.withOpacity(0.3)
                                  : Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  size: 16,
                                  color: TColors.warning,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Individual sleep needs may vary. Consistently getting less sleep than recommended may affect your health.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: darkMode
                                          ? TColors.darkGrey
                                          : TColors.darkerGrey,
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
                        ? TColors.darkerGrey.withOpacity(0.3)
                        : TColors.grey.withOpacity(0.3),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkMode
                        ? TColors.darkerGrey.withOpacity(0.5)
                        : TColors.grey.withOpacity(0.3),
                    foregroundColor: darkMode ? TColors.white : TColors.black,
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

  Widget _buildAgeGroupCard({
    required String ageGroup,
    required String recommended,
    required IconData icon,
    required Color color,
    required bool darkMode,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted
            ? color.withOpacity(0.15)
            : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? color : color.withOpacity(0.3),
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color,
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
                          color: darkMode ? TColors.white : TColors.black,
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
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Your Age',
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
                    Icon(Icons.star, size: 14, color: color),
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
                                color: color,
                              ),
                            ),
                            TextSpan(
                              text: recommended,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: color,
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

  static Future<void> show({int? age}) async {
    Get.dialog(
      SleepInfoDialog(age: age),
      barrierDismissible: true,
    );
  }
}