import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:get/get.dart';

import '../../../utils/constants/admin_colors.dart';
import '../../../utils/helpers/helper_functions.dart';

class DataTableColumn<T> extends GetxController {
  final String label;
  final String field;
  final double minWidth;
  final int flex;
  final bool sortable;
  final Widget Function(T item) builder;

  DataTableColumn({
    required this.label,
    required this.field,
    this.minWidth = 80, // 默认最小宽度
    this.flex = 1, // 默认权重
    required this.builder,
    this.sortable = true,
  });
}

class ReusableDataTable<T> extends StatelessWidget {
  final List<T> data;
  final List<DataTableColumn<T>> columns;
  final bool isLoading;
  final Function(bool)? onSelectAll;
  final RxList<T> selectedItems;
  final Function(T, bool)? onItemSelect;
  final String searchQuery;
  final int sortColumnIndex;
  final bool sortAscending;
  final Function(int, bool)? onSort;

  const ReusableDataTable({
    super.key,
    required this.data,
    required this.columns,
    this.isLoading = false,
    this.onSelectAll,
    required this.selectedItems,
    this.onItemSelect,
    this.searchQuery = '',
    this.sortColumnIndex = 0,
    this.sortAscending = true,
    this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    if (isLoading) {
      return _buildLoadingState(darkMode);
    }

    return Column(
      children: [
        // Header
        _buildTableHeader(context, darkMode),

        // Data rows or empty state
        Expanded(
          child: data.isEmpty
              ? _buildEmptyState(darkMode)
              : ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              final isEven = index % 2 == 0;

              return Obx(() {
                final isSelected = selectedItems.contains(item);
                return _buildDataRow(
                    context, item, isSelected, isEven, darkMode, index);
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(BuildContext context, bool darkMode) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: TAdminColors.getTableHeaderColor(darkMode),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(
          bottom: BorderSide(
            color: TAdminColors.getBorderColor(darkMode),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Select all checkbox
          if (onSelectAll != null)
            SizedBox(
              width: 60,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    final selectAllState = _getSelectAllState();
                    final newValue = selectAllState != true;
                    onSelectAll!(newValue);
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        checkboxTheme: CheckboxThemeData(
                          checkColor: WidgetStateProperty.all(Colors.white),
                          fillColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return TAdminColors.primary;
                            }
                            return Colors.transparent;
                          }),
                          side: WidgetStateBorderSide.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return BorderSide(color: TAdminColors.primary, width: 2);
                            }
                            return BorderSide(
                              color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                              width: 1.5,
                            );
                          }),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      child: Obx(() => Checkbox(
                        value: _getSelectAllState(),
                        tristate: true,
                        onChanged: (bool? value) {
                          if (value != null) {
                            onSelectAll!(value);
                          } else {
                            onSelectAll!(false);
                          }
                        },
                      ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Column headers - Fixed to respect minWidth
          Expanded(
            child: _buildColumnHeadersRow(darkMode),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeadersRow(bool darkMode) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidths = _calculateColumnWidths(constraints);

        return Row(
          children: columns.asMap().entries.map((entry) {
            final index = entry.key;
            final column = entry.value;

            return SizedBox(
              width: columnWidths[index],
              child: _buildColumnHeader(column, index, darkMode),
            );
          }).toList(),
        );
      },
    );
  }

  bool? _getSelectAllState() {
    if (data.isEmpty) return false;
    if (selectedItems.isEmpty) return false;
    if (selectedItems.length == data.length) return true;
    return null;
  }

  Widget _buildColumnHeader(DataTableColumn<T> column, int index, bool darkMode) {
    final isCurrentSort = sortColumnIndex == index;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: column.sortable && onSort != null
            ? () => onSort!(index, isCurrentSort ? !sortAscending : true)
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  column.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: TAdminColors.getOnSurfaceColor(darkMode),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (column.sortable) ...[
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: isCurrentSort && !sortAscending ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isCurrentSort ? Iconsax.arrow_up_3_bold : Iconsax.arrow_3_bold,
                    size: 16,
                    color: isCurrentSort
                        ? TAdminColors.primary
                        : TAdminColors.getOnSurfaceVariantColor(darkMode),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(BuildContext context, T item, bool isSelected, bool isEven, bool isDark, int index) {
    return Material(
      color: Colors.transparent,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: isSelected
              ? TAdminColors.primary.withOpacity(0.1)
              : (isEven
              ? TAdminColors.getTableRowColor(isDark)
              : TAdminColors.getTableRowColor(isDark).withOpacity(0.5)),
          border: Border(
            bottom: BorderSide(
              color: TAdminColors.getBorderColor(isDark).withOpacity(0.5),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Selection checkbox
            if (onItemSelect != null)
              SizedBox(
                width: 60,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      onItemSelect!(item, !isSelected);
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          checkboxTheme: CheckboxThemeData(
                            checkColor: WidgetStateProperty.all(Colors.white),
                            fillColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return TAdminColors.primary;
                              }
                              return Colors.transparent;
                            }),
                            side: WidgetStateBorderSide.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return BorderSide(color: TAdminColors.primary, width: 2);
                              }
                              return BorderSide(
                                color: TAdminColors.getOnSurfaceVariantColor(isDark),
                                width: 1.5,
                              );
                            }),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            if (value != null) {
                              onItemSelect!(item, value);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Data cells - Fixed to respect minWidth
            Expanded(
              child: InkWell(
                onTap: () {
                  // 行点击逻辑
                },
                child: _buildDataCellsRow(item, isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCellsRow(T item, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidths = _calculateColumnWidths(constraints);

        return Row(
          children: columns.asMap().entries.map((entry) {
            final index = entry.key;
            final column = entry.value;

            return SizedBox(
              width: columnWidths[index],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: column.builder(item),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// 根据 minWidth 和 flex 计算每个 column 的实际宽度
  List<double> _calculateColumnWidths(BoxConstraints constraints) {
    final availableWidth = constraints.maxWidth;
    final totalFlex = columns.fold<int>(0, (sum, col) => sum + col.flex);

    List<double> columnWidths = [];
    double remainingWidth = availableWidth;

    // Step 1: 先给 minWidth
    for (var column in columns) {
      final minWidth = column.minWidth;
      columnWidths.add(minWidth);
      remainingWidth -= minWidth;
    }

    // Step 2: 把多余的 space 按 flex 分配
    if (remainingWidth > 0) {
      for (int i = 0; i < columns.length; i++) {
        final flexRatio = columns[i].flex / totalFlex;
        final extraWidth = remainingWidth * flexRatio;
        columnWidths[i] += extraWidth;
      }
    }

    return columnWidths;
  }

  Widget _buildLoadingState(bool isDark) {
    return Expanded(
      child: Container(
        width: double.infinity,
        height: 400,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: TAdminColors.primary,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading data...',
              style: TextStyle(
                color: TAdminColors.getOnSurfaceVariantColor(isDark),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool darkMode) {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: TAdminColors.getBorderColor(darkMode).withOpacity(0.5),
                  width: 0.5,
                ),
              ),
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.document_bold,
                      size: 64,
                      color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No records found',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: TAdminColors.getOnSurfaceColor(darkMode),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      searchQuery.isNotEmpty
                          ? 'No results match your search criteria'
                          : 'There are no users to display',
                      style: TextStyle(
                        color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}