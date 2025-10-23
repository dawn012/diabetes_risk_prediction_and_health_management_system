import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';

class PeriodFilter extends StatelessWidget {
  final String selectedValue;
  final Function(String) onValueChanged;
  final List<String> options;

  const PeriodFilter({
    super.key,
    required this.selectedValue,
    required this.onValueChanged,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // This is just a utility class
  }

  static void show({
    required BuildContext context,
    required String selectedValue,
    required Function(String) onValueChanged,
    required List<String> options,
  }) {
    final darkMode = THelperFunctions.isDarkMode(context);

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: darkMode ? TColors.dark : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(TSizes.cardRadiusLg),
            topRight: Radius.circular(TSizes.cardRadiusLg),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Header
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
                    'Trend Filter',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            /// Filter Options
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = option == selectedValue;

                    return ListTile(
                      title: Text(
                        option,
                        style: TextStyle(
                          color: darkMode ? TColors.white : TColors.black,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: TColors.primary.withOpacity(0.1),
                      onTap: () {
                        onValueChanged(option);
                        Get.back();
                      },
                      trailing: isSelected
                          ? const Icon(Icons.check, color: TColors.primary)
                          : null,
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: TSizes.defaultSpace),
          ],
        ),
      ),
    );
  }
}