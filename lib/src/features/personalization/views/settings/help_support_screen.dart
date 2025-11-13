import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _expandedIndex;

  final List<Map<String, dynamic>> _faqData = [
    {
      'category': TTexts.generalQuestions,
      'icon': Iconsax.info_circle_bold,
      'color': TColors.info,
      'questions': [
        {
          'question': 'What can this app do?',
          'answer':
          'DiaTrack helps you record blood glucose, blood pressure, weight, body fat, and daily physical activities. It predicts diabetes risk based on comprehensive health data and provides personalized health recommendations along with a premium meal suggestion service.',
        },
        {
          'question': 'Can this app diagnose diabetes?',
          'answer':
          'No. This app only provides diabetes risk prediction and health management guidance. It cannot replace professional medical diagnosis or treatment. Always consult with qualified healthcare professionals for medical decisions.',
        },
        {
          'question': 'How are prediction results calculated?',
          'answer':
          'Our AI model analyzes multiple data points including weight, height, blood glucose, daily activity duration, stress levels, sleep duration, water intake, medication adherence, and diet quality to generate your diabetes risk score.',
        },
        {
          'question': 'What do the risk scores mean?',
          'answer':
          'Risk scores are presented as:\n\n• 0-30: Low Risk\n• 31-60: Moderate Risk\n• 61+: High Risk\n\nHigher scores indicate greater diabetes risk. Remember, these are estimates for awareness, not diagnoses.',
        },
        {
          'question': 'Why do my results differ from my doctor\'s diagnosis?',
          'answer':
          'Our predictions are based on data analysis and machine learning algorithms for reference only. Doctors consider additional clinical and physiological factors in their diagnoses, which may lead to different conclusions.',
        },
        {
          'question': 'How often should I update my data?',
          'answer':
          'We recommend updating your blood glucose, blood pressure, exercise, and sleep data daily for the most accurate trend analysis and risk predictions.',
        },
      ],
    },
    {
      'category': TTexts.accountSecurity,
      'icon': Iconsax.shield_tick_bold,
      'color': TColors.success,
      'questions': [
        {
          'question': 'How do I record health data?',
          'answer':
          'Navigate to the respective recording page (Blood Glucose, Blood Pressure, Weight & Body Fat, etc.), enter your measurements with the time, and save. It\'s that simple!',
        },
        {
          'question': 'What is the meal recommendation feature?',
          'answer':
          'Our meal recommendation system provides personalized healthy meal suggestions based on your risk score, dietary preferences, and allergy information. This is a premium subscription feature available to paid users.',
        },
        {
          'question': 'What are Periodic Achievements?',
          'answer':
          'The app awards periodic achievements based on your health data recording and activity goals. The achievement system resets monthly to help you maintain consistent healthy habits.',
        },
      ],
    },
    {
      'category': TTexts.dataPrivacy,
      'icon': Iconsax.lock_bold,
      'color': TColors.error,
      'questions': [
        {
          'question': 'Is my health data secure?',
          'answer':
          'Yes! All data is encrypted during storage and transmission. Only you can access your personal health information. We follow industry-standard security practices to protect your privacy.',
        },
        {
          'question': 'Will my data be shared with third parties?',
          'answer':
          'No. Unless you explicitly authorize it, the system will not share your data with any third parties. Your privacy is our top priority.',
        },
        {
          'question': 'How can I delete my account and data?',
          'answer':
          'Go to Settings > Account and select "Delete Account". All your data will be permanently deleted and cannot be recovered. Please ensure you\'ve exported any data you wish to keep before deletion.',
        },
      ],
    },
    {
      'category': TTexts.technicalSupport,
      'icon': Iconsax.setting_2_bold,
      'color': TColors.warning,
      'questions': [
        {
          'question': 'What should I do if I encounter technical issues?',
          'answer':
          'Please go to Help & Support > Contact Us, or send an email to ${TTexts.supportEmail}. Our support team will respond as quickly as possible to resolve your issue.',
        },
      ],
    },
  ];

  List<Map<String, dynamic>> get _filteredFAQs {
    if (_searchQuery.isEmpty) return _faqData;

    return _faqData.map((category) {
      final filteredQuestions = (category['questions'] as List).where((q) {
        final question = q['question'].toString().toLowerCase();
        final answer = q['answer'].toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return question.contains(query) || answer.contains(query);
      }).toList();

      if (filteredQuestions.isEmpty) return null;

      return {
        ...category,
        'questions': filteredQuestions,
      };
    }).whereType<Map<String, dynamic>>().toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: darkMode ? TColors.dark : TColors.light,
      appBar: TAppBar(
        title: Text(TTexts.helpSupportTitle),
        showBackArrow: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    TColors.primary.withOpacity(0.15),
                    TColors.secondary.withOpacity(0.05),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: TColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Iconsax.message_question_bold,
                          size: 40,
                          color: TColors.primary,
                        ),
                      ),
                      const SizedBox(width: TSizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              TTexts.helpSupportTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium!
                                  .copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              TTexts.helpSupportSubtitle,
                              style:
                              Theme.of(context).textTheme.bodyMedium!.apply(
                                color: darkMode
                                    ? TColors.darkGrey
                                    : TColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Search Bar with enhanced styling
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: darkMode
                          ? Colors.black.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: TTexts.searchFAQ,
                    hintStyle: TextStyle(
                      color: darkMode ? TColors.darkGrey : TColors.textSecondary,
                    ),
                    prefixIcon: Container(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Iconsax.search_normal_bold,
                        color: TColors.primary,
                        size: 22,
                      ),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear, color: TColors.darkGrey),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                        : null,
                    filled: true,
                    fillColor: darkMode ? TColors.darkContainer : TColors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: TSizes.md,
                      vertical: TSizes.md,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(TSizes.borderRadiusLg),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(TSizes.borderRadiusLg),
                      borderSide: BorderSide(
                        color: darkMode
                            ? TColors.darkerGrey
                            : TColors.borderPrimary,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(TSizes.borderRadiusLg),
                      borderSide: BorderSide(
                        color: TColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: TSizes.spaceBtwSections),

            // FAQ Categories with enhanced design
            ..._filteredFAQs.asMap().entries.map((entry) {
              final categoryIndex = entry.key;
              final category = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Header with enhanced styling
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: TSizes.defaultSpace),
                    child: Container(
                      padding: const EdgeInsets.all(TSizes.md),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (category['color'] as Color).withOpacity(0.15),
                            (category['color'] as Color).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
                        border: Border.all(
                          color: (category['color'] as Color).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                              (category['color'] as Color).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              category['icon'] as IconData,
                              color: category['color'] as Color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: TSizes.md),
                          Expanded(
                            child: Text(
                              category['category'] as String,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge!
                                  .copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                              (category['color'] as Color).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${(category['questions'] as List).length}',
                              style: TextStyle(
                                color: category['color'] as Color,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: TSizes.md),

                  // Questions with enhanced styling
                  ...((category['questions'] as List)
                      .asMap()
                      .entries
                      .map((qEntry) {
                    final questionIndex = qEntry.key;
                    final question = qEntry.value;
                    final globalIndex = categoryIndex * 100 + questionIndex;
                    final isExpanded = _expandedIndex == globalIndex;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TSizes.defaultSpace,
                        vertical: TSizes.xs / 2,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: darkMode
                              ? TColors.darkContainer
                              : TColors.white,
                          borderRadius:
                          BorderRadius.circular(TSizes.cardRadiusLg),
                          border: Border.all(
                            color: isExpanded
                                ? (category['color'] as Color)
                                : (darkMode
                                ? TColors.darkerGrey
                                : TColors.borderPrimary),
                            width: isExpanded ? 2 : 1,
                          ),
                          boxShadow: isExpanded
                              ? [
                            BoxShadow(
                              color: (category['color'] as Color)
                                  .withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                              : [
                            BoxShadow(
                              color: darkMode
                                  ? Colors.black.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _expandedIndex =
                                isExpanded ? null : globalIndex;
                              });
                            },
                            borderRadius:
                            BorderRadius.circular(TSizes.cardRadiusLg),
                            child: Padding(
                              padding: const EdgeInsets.all(TSizes.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: category['color'] as Color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: TSizes.sm),
                                      Expanded(
                                        child: Text(
                                          question['question'] as String,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium!
                                              .copyWith(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                            color: isExpanded
                                                ? (category['color']
                                            as Color)
                                                : null,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                      AnimatedRotation(
                                        turns: isExpanded ? 0.5 : 0,
                                        duration:
                                        const Duration(milliseconds: 200),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: isExpanded
                                                ? (category['color'] as Color)
                                                .withOpacity(0.1)
                                                : Colors.transparent,
                                            borderRadius:
                                            BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.keyboard_arrow_down,
                                            color: isExpanded
                                                ? (category['color'] as Color)
                                                : (darkMode
                                                ? TColors.darkGrey
                                                : TColors.textSecondary),
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  AnimatedCrossFade(
                                    firstChild: const SizedBox.shrink(),
                                    secondChild: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: TSizes.md),
                                        Container(
                                          height: 1,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                (category['color'] as Color)
                                                    .withOpacity(0.3),
                                                (category['color'] as Color)
                                                    .withOpacity(0.0),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: TSizes.md),
                                        Container(
                                          padding: const EdgeInsets.all(TSizes.sm),
                                          decoration: BoxDecoration(
                                            color: (category['color'] as Color)
                                                .withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(
                                                TSizes.borderRadiusMd),
                                          ),
                                          child: Text(
                                            question['answer'] as String,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium!
                                                .apply(
                                              color: darkMode
                                                  ? TColors.darkGrey
                                                  : TColors.textSecondary,
                                              heightFactor: 1.6,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    crossFadeState: isExpanded
                                        ? CrossFadeState.showSecond
                                        : CrossFadeState.showFirst,
                                    duration: const Duration(milliseconds: 200),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList()),

                  const SizedBox(height: TSizes.spaceBtwSections),
                ],
              );
            }).toList(),

            // Enhanced Contact Section
            Padding(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(TSizes.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      TColors.primary.withOpacity(0.15),
                      TColors.secondary.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                  border: Border.all(
                    color: TColors.primary.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: TColors.primary.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                TColors.primary,
                                TColors.primary.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: TColors.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Iconsax.message_bold,
                            color: TColors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: TSizes.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                TTexts.contactUs,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge!
                                    .copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                TTexts.contactUsSubtitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .apply(
                                  color: darkMode
                                      ? TColors.darkGrey
                                      : TColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: TSizes.spaceBtwItems),

                    // Contact Items
                    _buildContactItem(
                      context: context,
                      icon: Icons.email,
                      title: 'Email',
                      value: TTexts.supportEmail,
                      onTap: () => _launchEmail(TTexts.supportEmail),
                      darkMode: darkMode,
                    ),

                    const SizedBox(height: TSizes.sm),

                    _buildContactItem(
                      context: context,
                      icon: Iconsax.call_bold,
                      title: 'Phone',
                      value: TTexts.supportPhone,
                      onTap: () => _launchPhone(TTexts.supportPhone),
                      darkMode: darkMode,
                    ),

                    const SizedBox(height: TSizes.sm),

                    _buildContactItem(
                      context: context,
                      icon: Iconsax.clock_bold,
                      title: 'Business Hours',
                      value: TTexts.businessHours,
                      darkMode: darkMode,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: TSizes.defaultSpace),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
    required bool darkMode,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(TSizes.md),
        decoration: BoxDecoration(
          color: darkMode
              ? TColors.darkContainer.withOpacity(0.5)
              : TColors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: darkMode
                ? TColors.darkerGrey.withOpacity(0.3)
                : TColors.borderPrimary.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: TColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: TColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: TSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall!.apply(
                      color:
                      darkMode ? TColors.darkGrey : TColors.textSecondary,
                      fontWeightDelta: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: onTap != null ? TColors.primary : null,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: TColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: TColors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final uri = 'mailto:$email';
    if (await canLaunchUrlString(uri)) {
      await launchUrlString(uri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final uri = 'tel:${phone.replaceAll(RegExp(r'[^\d+]'), '')}';
    if (await canLaunchUrlString(uri)) {
      await launchUrlString(uri);
    }
  }
}