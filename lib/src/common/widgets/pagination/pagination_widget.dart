import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../utils/constants/admin_colors.dart';
import '../../../utils/helpers/helper_functions.dart';

class PaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final int totalItems;
  final int itemsPerPage;
  final int startIndex;
  final int endIndex;

  const PaginationWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.totalItems,
    required this.itemsPerPage,
    required this.startIndex,
    required this.endIndex,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);
    final isWeb = THelperFunctions.screenWidth() > 600;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceColor(darkMode),
        border: Border(
          top: BorderSide(
            color: TAdminColors.getBorderColor(darkMode),
            width: 1,
          ),
        ),
      ),
      child: isWeb ? _buildWebPagination(darkMode) : _buildMobilePagination(darkMode),
    );
  }

  Widget _buildWebPagination(bool darkMode) {
    return Row(
      children: [
        // Results info
        Text(
          'Showing $startIndex-$endIndex of $totalItems entries',
          style: TextStyle(
            color: TAdminColors.getOnSurfaceVariantColor(darkMode),
            fontSize: 14,
          ),
        ),

        const Spacer(),

        // Pagination controls
        Row(
          children: [
            // First page button
            _buildPageButton(
              onPressed: currentPage > 1 ? () => onPageChanged(1) : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.arrow_left_3_bold, size: 14),
                  SizedBox(width: 4),
                  Text('First', style: TextStyle(fontSize: 12)),
                ],
              ),
              darkMode: darkMode,
            ),

            SizedBox(width: 8),

            // Previous button
            _buildPageButton(
              onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
              child: Icon(Iconsax.arrow_left_2_bold, size: 16),
              darkMode: darkMode,
            ),

            SizedBox(width: 12),

            // Page numbers
            ..._buildPageNumbers(darkMode),

            SizedBox(width: 12),

            // Next button
            _buildPageButton(
              onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
              child: Icon(Iconsax.arrow_right_2_bold, size: 16),
              darkMode: darkMode,
            ),

            SizedBox(width: 8),

            // Last page button
            _buildPageButton(
              onPressed: currentPage < totalPages ? () => onPageChanged(totalPages) : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Last', style: TextStyle(fontSize: 12)),
                  SizedBox(width: 4),
                  Icon(Iconsax.arrow_right_3_bold, size: 14),
                ],
              ),
              darkMode: darkMode,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobilePagination(bool darkMode) {
    return Column(
      children: [
        // Results info
        Text(
          'Showing $startIndex-$endIndex of $totalItems entries',
          style: TextStyle(
            color: TAdminColors.getOnSurfaceVariantColor(darkMode),
            fontSize: 14,
          ),
        ),

        SizedBox(height: 16),

        // Pagination controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // First page button
            _buildPageButton(
              onPressed: currentPage > 1 ? () => onPageChanged(1) : null,
              child: Icon(Iconsax.arrow_left_3_bold, size: 16),
              darkMode: darkMode,
            ),

            SizedBox(width: 8),

            // Previous button
            _buildPageButton(
              onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
              child: Icon(Iconsax.arrow_left_2_bold, size: 16),
              darkMode: darkMode,
            ),

            SizedBox(width: 16),

            // Current page info
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: TAdminColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: TAdminColors.primary.withOpacity(0.3)),
              ),
              child: Text(
                '$currentPage / $totalPages',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: TAdminColors.primary,
                ),
              ),
            ),

            SizedBox(width: 16),

            // Next button
            _buildPageButton(
              onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
              child: Icon(Iconsax.arrow_right_2_bold, size: 16),
              darkMode: darkMode,
            ),

            SizedBox(width: 8),

            // Last page button
            _buildPageButton(
              onPressed: currentPage < totalPages ? () => onPageChanged(totalPages) : null,
              child: Icon(Iconsax.arrow_right_3_bold, size: 16),
              darkMode: darkMode,
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildPageNumbers(bool darkMode) {
    List<Widget> pageNumbers = [];

    // Calculate visible page range
    int start = 1;
    int end = totalPages;

    if (totalPages > 7) {
      if (currentPage <= 4) {
        // Show first 5 pages + ... + last page
        start = 1;
        end = 5;
        pageNumbers.addAll(_buildPageRange(start, end, darkMode));
        pageNumbers.add(_buildEllipsis(darkMode));
        pageNumbers.add(_buildPageButton(
          onPressed: () => onPageChanged(totalPages),
          child: Text('$totalPages'),
          isSelected: currentPage == totalPages,
          darkMode: darkMode,
        ));
      } else if (currentPage >= totalPages - 3) {
        // Show first page + ... + last 5 pages
        pageNumbers.add(_buildPageButton(
          onPressed: () => onPageChanged(1),
          child: Text('1'),
          isSelected: currentPage == 1,
          darkMode: darkMode,
        ));
        pageNumbers.add(_buildEllipsis(darkMode));
        start = totalPages - 4;
        end = totalPages;
        pageNumbers.addAll(_buildPageRange(start, end, darkMode));
      } else {
        // Show first page + ... + current range + ... + last page
        pageNumbers.add(_buildPageButton(
          onPressed: () => onPageChanged(1),
          child: Text('1'),
          isSelected: currentPage == 1,
          darkMode: darkMode,
        ));
        pageNumbers.add(_buildEllipsis(darkMode));

        start = currentPage - 1;
        end = currentPage + 1;
        pageNumbers.addAll(_buildPageRange(start, end, darkMode));

        pageNumbers.add(_buildEllipsis(darkMode));
        pageNumbers.add(_buildPageButton(
          onPressed: () => onPageChanged(totalPages),
          child: Text('$totalPages'),
          isSelected: currentPage == totalPages,
          darkMode: darkMode,
        ));
      }
    } else {
      pageNumbers.addAll(_buildPageRange(start, end, darkMode));
    }

    return pageNumbers;
  }

  List<Widget> _buildPageRange(int start, int end, bool darkMode) {
    return List.generate(
      end - start + 1,
          (index) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 2),
        child: _buildPageButton(
          onPressed: () => onPageChanged(start + index),
          child: Text('${start + index}'),
          isSelected: currentPage == start + index,
          darkMode: darkMode,
        ),
      ),
    );
  }

  Widget _buildEllipsis(bool darkMode) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '...',
        style: TextStyle(
          color: TAdminColors.getOnSurfaceVariantColor(darkMode),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPageButton({
    required VoidCallback? onPressed,
    required Widget child,
    bool isSelected = false,
    required bool darkMode,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? TAdminColors.primary
                : (onPressed != null
                ? TAdminColors.getHoverColor(darkMode)
                : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? TAdminColors.primary
                  : (onPressed != null
                  ? TAdminColors.getBorderColor(darkMode)
                  : TAdminColors.getBorderColor(darkMode).withOpacity(0.5)),
            ),
          ),
          child: Center(
            child: DefaultTextStyle(
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (onPressed != null
                    ? TAdminColors.getOnSurfaceColor(darkMode)
                    : TAdminColors.getOnSurfaceVariantColor(darkMode).withOpacity(0.5)),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}