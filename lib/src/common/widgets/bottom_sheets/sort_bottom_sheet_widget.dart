import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';

class SortBottomSheetWidget extends StatelessWidget {
  final List<String> sortOptions;
  final RxString selectedSortOption;
  final Function(String) onSortOptionChanged;
  final String Function(String) getSortOptionLabel;
  final bool darkMode;

  const SortBottomSheetWidget({
    super.key,
    required this.sortOptions,
    required this.selectedSortOption,
    required this.onSortOptionChanged,
    required this.getSortOptionLabel,
    required this.darkMode,
  });

  static void show(
      BuildContext context, {
        required List<String> sortOptions,
        required RxString selectedSortOption,
        required Function(String) onSortOptionChanged,
        required String Function(String) getSortOptionLabel,
        required bool darkMode,
      }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SortBottomSheetWidget(
        sortOptions: sortOptions,
        selectedSortOption: selectedSortOption,
        onSortOptionChanged: onSortOptionChanged,
        getSortOptionLabel: getSortOptionLabel,
        darkMode: darkMode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: darkMode ? TColors.dark : TColors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(TSizes.cardRadiusLg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: TSizes.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: darkMode ? TColors.darkGrey : TColors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(TSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sort By',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkMode ? TColors.white : TColors.dark,
                  ),
                ),
                const SizedBox(height: TSizes.md),
                ...sortOptions.map((option) {
                  return Obx(() => ListTile(
                    leading: Radio<String>(
                      value: option,
                      groupValue: selectedSortOption.value,
                      onChanged: (value) {
                        onSortOptionChanged(value!);
                        Navigator.pop(context);
                      },
                      activeColor: TColors.primary,
                    ),
                    title: Text(
                      getSortOptionLabel(option),
                      style: TextStyle(
                        color: darkMode ? TColors.white : TColors.dark,
                      ),
                    ),
                    onTap: () {
                      onSortOptionChanged(option);
                      Navigator.pop(context);
                    },
                  ));
                }).toList(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}