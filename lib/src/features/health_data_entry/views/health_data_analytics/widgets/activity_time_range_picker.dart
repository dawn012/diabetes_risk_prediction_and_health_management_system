import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';

class ActivityTimeRangePicker extends StatelessWidget {
  final String selectedRange;
  final Function(String) onRangeChanged;
  final bool isWeekView;

  const ActivityTimeRangePicker({
    super.key,
    required this.selectedRange,
    required this.onRangeChanged,
    required this.isWeekView,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace, vertical: TSizes.md),
      decoration: BoxDecoration(
        color: darkMode ? TColors.dark : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: darkMode ? TColors.darkGrey : TColors.borderPrimary,
            width: 1,
          ),
        ),
      ),
      child: GestureDetector(
        onTap: () => _showTimeRangePicker(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              selectedRange,
              style: TextStyle(
                color: TColors.primary,
                fontSize: TSizes.fontSizeLg,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: TSizes.xs),
            Icon(
              Icons.keyboard_arrow_down,
              color: TColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _showTimeRangePicker(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    if (isWeekView) {
      _showWeekRangePicker(context, darkMode);
    } else {
      _showMonthRangePicker(context, darkMode);
    }
  }

  void _showWeekRangePicker(BuildContext context, bool darkMode) {
    final weekOptions = _generateWeekOptions();
    final currentIndex = weekOptions.indexWhere((option) => option['display'] == selectedRange);
    int selectedIndex = currentIndex >= 0 ? currentIndex : 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: darkMode ? TColors.dark : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(TSizes.cardRadiusLg),
              topRight: Radius.circular(TSizes.cardRadiusLg),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(TSizes.defaultSpace),
                decoration: BoxDecoration(
                  color: TColors.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(TSizes.cardRadiusLg),
                    topRight: Radius.circular(TSizes.cardRadiusLg),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Week',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Date Range Display
              Container(
                padding: const EdgeInsets.all(TSizes.defaultSpace),
                child: Text(
                  weekOptions[selectedIndex]['dateRange']!,
                  style: TextStyle(
                    color: darkMode ? TColors.white : TColors.textPrimary,
                    fontSize: TSizes.fontSizeLg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Scrollable Week List
              Expanded(
                child: _buildScrollableWeekPicker(weekOptions, selectedIndex, darkMode, setState, (index) {
                  selectedIndex = index;
                }),
              ),

              // Action Buttons
              Container(
                padding: const EdgeInsets.all(TSizes.defaultSpace),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                          side: BorderSide(color: TColors.primary),
                        ),
                        child: Text(
                          'CANCEL',
                          style: TextStyle(
                            color: TColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: TSizes.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onRangeChanged(weekOptions[selectedIndex]['display']!);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                        ),
                        child: const Text(
                          'DONE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }

  Widget _buildScrollableWeekPicker(
      List<Map<String, String>> options,
      int currentSelected,
      bool darkMode,
      StateSetter setState,
      Function(int) onSelectionChanged
      ) {
    final controller = FixedExtentScrollController(initialItem: currentSelected);

    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 60,
      perspective: 0.005,
      diameterRatio: 1.2,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (index) {
        setState(() {
          onSelectionChanged(index);
        });
      },
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: options.length,
        builder: (context, index) {
          final isSelected = index == currentSelected;
          return Container(
            alignment: Alignment.center,
            child: Text(
              options[index]['display']!,
              style: TextStyle(
                color: isSelected
                    ? TColors.primary
                    : (darkMode ? TColors.white.withOpacity(0.5) : TColors.textSecondary),
                fontSize: isSelected ? TSizes.fontSizeLg : TSizes.fontSizeMd,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showMonthRangePicker(BuildContext context, bool darkMode) {
    final years = _generateValidYears();
    final months = _generateMonths();

    // Parse current selection to get initial indices
    final currentParts = selectedRange.split(' ');
    final currentMonth = currentParts.length > 0 ? currentParts[0] : 'Sep';
    final currentYear = currentParts.length > 1 ? currentParts[1] : '2025';

    int selectedYearIndex = years.indexOf(currentYear);
    int selectedMonthIndex = months.indexOf(currentMonth);

    if (selectedYearIndex == -1) selectedYearIndex = 0;
    if (selectedMonthIndex == -1) selectedMonthIndex = 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Get valid months for currently selected year
          final validMonths = _getValidMonthsForYear(years[selectedYearIndex], months);

          // Ensure selected month is valid for the current year
          if (!validMonths.contains(months[selectedMonthIndex])) {
            selectedMonthIndex = months.indexOf(validMonths.first);
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: darkMode ? TColors.dark : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(TSizes.cardRadiusLg),
                topRight: Radius.circular(TSizes.cardRadiusLg),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(TSizes.defaultSpace),
                  decoration: BoxDecoration(
                    color: TColors.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(TSizes.cardRadiusLg),
                      topRight: Radius.circular(TSizes.cardRadiusLg),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Year / Month',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Year/Month Selection
                Expanded(
                  child: Row(
                    children: [
                      // Years
                      Expanded(
                        child: _buildScrollableYearPicker(
                          years,
                          selectedYearIndex,
                          darkMode,
                          setState,
                          onChanged: (index) {
                            selectedYearIndex = index;
                            // When year changes, reset month to first valid month
                            final newValidMonths = _getValidMonthsForYear(years[selectedYearIndex], months);
                            selectedMonthIndex = months.indexOf(newValidMonths.first);
                          },
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 200,
                        color: darkMode ? TColors.darkGrey : TColors.borderPrimary,
                      ),
                      // Months
                      Expanded(
                        child: _buildScrollableMonthPicker(
                          validMonths,
                          validMonths.indexOf(months[selectedMonthIndex]),
                          darkMode,
                          setState,
                          onChanged: (index) {
                            selectedMonthIndex = months.indexOf(validMonths[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                Container(
                  padding: const EdgeInsets.all(TSizes.defaultSpace),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                            side: BorderSide(color: TColors.primary),
                          ),
                          child: Text(
                            'CANCEL',
                            style: TextStyle(
                              color: TColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: TSizes.md),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final newSelection = '${months[selectedMonthIndex]} ${years[selectedYearIndex]}';
                            Navigator.pop(context);
                            onRangeChanged(newSelection);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                          ),
                          child: const Text(
                            'DONE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScrollableYearPicker(
      List<String> options,
      int selectedIndex,
      bool darkMode,
      StateSetter setState,
      {required Function(int) onChanged}
      ) {
    final controller = FixedExtentScrollController(initialItem: selectedIndex);
    int currentSelected = selectedIndex;

    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 50,
      perspective: 0.005,
      diameterRatio: 1.2,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (index) {
        setState(() {
          currentSelected = index;
          onChanged(index);
        });
      },
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: options.length,
        builder: (context, index) {
          final isSelected = index == currentSelected;
          return Container(
            alignment: Alignment.center,
            child: Text(
              options[index],
              style: TextStyle(
                color: isSelected
                    ? TColors.primary
                    : (darkMode ? TColors.white.withOpacity(0.5) : TColors.textSecondary),
                fontSize: isSelected ? TSizes.fontSizeLg : TSizes.fontSizeMd,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScrollableMonthPicker(
      List<String> options,
      int selectedIndex,
      bool darkMode,
      StateSetter setState,
      {required Function(int) onChanged}
      ) {
    final controller = FixedExtentScrollController(initialItem: selectedIndex);
    int currentSelected = selectedIndex;

    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 50,
      perspective: 0.005,
      diameterRatio: 1.2,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (index) {
        setState(() {
          currentSelected = index;
          onChanged(index);
        });
      },
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: options.length,
        builder: (context, index) {
          final isSelected = index == currentSelected;
          return Container(
            alignment: Alignment.center,
            child: Text(
              options[index],
              style: TextStyle(
                color: isSelected
                    ? TColors.primary
                    : (darkMode ? TColors.white.withOpacity(0.5) : TColors.textSecondary),
                fontSize: isSelected ? TSizes.fontSizeLg : TSizes.fontSizeMd,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  List<Map<String, String>> _generateWeekOptions() {
    final now = DateTime.now();
    final List<Map<String, String>> options = [];

    // Start with current week (This Week)
    for (int i = 0; i < 12; i++) {
      final weekStart = now.subtract(Duration(days: now.weekday % 7 + (i * 7)));
      final weekEnd = weekStart.add(const Duration(days: 6));

      String display;
      if (i == 0) {
        display = 'This Week';
      } else if (i == 1) {
        display = 'Last Week';
      } else {
        // For other weeks, show the date range directly
        display = '${weekStart.month}/${weekStart.day} - ${weekEnd.month}/${weekEnd.day}';
      }

      options.add({
        'display': display,
        'dateRange': '${weekStart.month}/${weekStart.day}/${weekStart.year} - ${weekEnd.month}/${weekEnd.day}/${weekEnd.year}',
      });
    }

    return options;
  }

  List<String> _generateValidYears() {
    final currentYear = DateTime.now().year;
    final List<String> years = [];

    // Generate current year and 2 years back
    for (int i = 0; i < 3; i++) {
      years.add((currentYear - i).toString());
    }

    return years;
  }

  List<String> _generateMonths() {
    return [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
  }

  List<String> _getValidMonthsForYear(String year, List<String> allMonths) {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;
    final selectedYear = int.parse(year);

    if (selectedYear == currentYear) {
      // For current year, only show months up to current month
      return allMonths.sublist(0, currentMonth);
    } else {
      // For past years, show all months
      return allMonths;
    }
  }
}