import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/helpers/helper_functions.dart';

class StressInfoDialog extends StatelessWidget {
  const StressInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);
    final isWeb = THelperFunctions.screenWidth() > 600;

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
                      Icons.info_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Understand Your Stress Level',
                      style: TextStyle(
                        fontSize: 20,
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
                    // WHO Descriptions Section
                    _buildSectionTitle(
                      'WHO Descriptions',
                      Icons.health_and_safety,
                      darkMode,
                    ),
                    SizedBox(height: 16),

                    _buildStressLevelCard(
                      emoji: '😌',
                      level: 'Low Stress',
                      description:
                      'Able to self-regulate, daily life and work function normally.',
                      color: Colors.green,
                      darkMode: darkMode,
                    ),

                    SizedBox(height: 12),

                    _buildStressLevelCard(
                      emoji: '😐',
                      level: 'Moderate Stress',
                      description:
                      'Occasionally anxious or fatigued, may need relaxation and adjustment.',
                      color: Colors.orange,
                      darkMode: darkMode,
                    ),

                    SizedBox(height: 12),

                    _buildStressLevelCard(
                      emoji: '😰',
                      level: 'High Stress',
                      description:
                      'Prolonged high stress, may experience anxiety, sleep disturbances, or other health issues.',
                      color: Colors.red,
                      darkMode: darkMode,
                    ),

                    SizedBox(height: 16),

                    // Source badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: darkMode
                            ? TColors.darkerGrey.withOpacity(0.3)
                            : TColors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            size: 14,
                            color: TColors.primary,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Source: WHO',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: darkMode ? TColors.white : TColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 32),

                    // Online Stress Test Section
                    _buildSectionTitle(
                      'Online Stress Test',
                      Icons.quiz,
                      darkMode,
                    ),
                    SizedBox(height: 16),

                    // Test description
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: darkMode
                            ? TColors.darkerGrey.withOpacity(0.3)
                            : TColors.lightBlueColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: TColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You can assess your stress using the Perceived Stress Scale (PSS-10):',
                            style: TextStyle(
                              fontSize: 14,
                              color: darkMode ? TColors.white : TColors.black,
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: 12),
                          _buildScoreRange('Low Stress', '0–13', Colors.green, darkMode),
                          SizedBox(height: 8),
                          _buildScoreRange('Moderate Stress', '14–26', Colors.orange, darkMode),
                          SizedBox(height: 8),
                          _buildScoreRange('High Stress', '27–40', Colors.red, darkMode),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    // Test link button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final url = 'https://www.bemindfulonline.com/test-your-stress';
                          if (await canLaunchUrlString(url)) {
                            await launchUrlString(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        icon: Icon(Icons.open_in_new, size: 18),
                        label: Text('Take the Stress Test'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Note
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: TColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: TColors.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: TColors.warning,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Note: The PSS-10 is a standardized 10-item questionnaire widely used in research and clinical settings. Scores from this external test are for reference only.',
                              style: TextStyle(
                                fontSize: 12,
                                color: darkMode
                                    ? TColors.darkGrey
                                    : TColors.darkerGrey,
                                height: 1.5,
                              ),
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

  Widget _buildSectionTitle(String title, IconData icon, bool darkMode) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: TColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: TColors.primary,
          ),
        ),
        SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: darkMode ? TColors.white : TColors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildStressLevelCard({
    required String emoji,
    required String level,
    required String description,
    required Color color,
    required bool darkMode,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            emoji,
            style: TextStyle(fontSize: 28),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRange(String level, String range, Color color, bool darkMode) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8),
        Text(
          '$level: ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: darkMode ? TColors.white : TColors.black,
          ),
        ),
        Text(
          range,
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static void show() {
    Get.dialog(
      const StressInfoDialog(),
      barrierDismissible: true,
    );
  }
}