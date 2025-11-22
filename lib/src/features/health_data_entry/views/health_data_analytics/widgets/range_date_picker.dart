import 'package:flutter/material.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';

class RangeDatePicker extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime, DateTime) onDateRangeChanged;
  final bool darkMode;

  const RangeDatePicker({
    super.key,
    this.startDate,
    this.endDate,
    required this.onDateRangeChanged,
    required this.darkMode,
  });

  @override
  State<RangeDatePicker> createState() => _RangeDatePickerState();
}

class _RangeDatePickerState extends State<RangeDatePicker> {
  late DateTime _startDate;
  late DateTime _endDate;
  DateTime? _selectedDate;
  bool _isSelectingStart = true;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate ?? DateTime.now().subtract(const Duration(days: 30));
    _endDate = widget.endDate ?? DateTime.now();
    _selectedDate = _startDate;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDate = DateTime(2020, 1, 1);

    return Column(
      children: [
        /// Selection Mode Indicator
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TSizes.sm,
            vertical: TSizes.sm, // Reduced padding
          ),
          margin: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.md),
          decoration: BoxDecoration(
            color: TColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(TSizes.sm),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isSelectingStart ? Icons.start : Icons.flag,
                size: 14,
                color: TColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                _isSelectingStart ? 'Selecting Start Date' : 'Selecting End Date',
                style: const TextStyle(
                  color: TColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        /// Month/Year Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.chevron_left,
                  color: _canNavigateToPreviousMonth(firstDate)
                      ? (widget.darkMode ? TColors.white : TColors.black)
                      : Colors.grey,
                ),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
                onPressed: _canNavigateToPreviousMonth(firstDate)
                    ? () {
                  setState(() {
                    _selectedDate = DateTime(
                      _selectedDate!.year,
                      _selectedDate!.month - 1,
                    );
                  });
                }
                    : null,
              ),
              Text(
                '${_getMonthName(_selectedDate!.month)} ${_selectedDate!.year}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: widget.darkMode ? TColors.white : TColors.black,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: _canNavigateToNextMonth(today)
                      ? (widget.darkMode ? TColors.white : TColors.black)
                      : Colors.grey,
                ),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
                onPressed: _canNavigateToNextMonth(today)
                    ? () {
                  setState(() {
                    _selectedDate = DateTime(
                      _selectedDate!.year,
                      _selectedDate!.month + 1,
                    );
                  });
                }
                    : null,
              ),
            ],
          ),
        ),

        /// Calendar Grid
        Expanded(
          child: _buildCalendarGrid(firstDate, today),
        ),

        /// Switch Button
        Padding(
          padding: const EdgeInsets.fromLTRB(TSizes.md, TSizes.xs, TSizes.md, TSizes.md),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _isSelectingStart = !_isSelectingStart;
                });
              },
              icon: Icon(
                _isSelectingStart ? Icons.flag : Icons.start,
                size: 14,
              ),
              label: Text(
                _isSelectingStart ? 'Switch to End Date' : 'Switch to Start Date',
                style: const TextStyle(fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: TColors.primary,
                side: const BorderSide(color: TColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _canNavigateToPreviousMonth(DateTime firstDate) {
    final previousMonth = DateTime(_selectedDate!.year, _selectedDate!.month - 1);
    return previousMonth.isAfter(firstDate.subtract(const Duration(days: 1)));
  }

  bool _canNavigateToNextMonth(DateTime lastDate) {
    final nextMonth = DateTime(_selectedDate!.year, _selectedDate!.month + 1);
    return nextMonth.isBefore(DateTime(lastDate.year, lastDate.month + 1));
  }

  Widget _buildCalendarGrid(DateTime firstDate, DateTime lastDate) {
    final year = _selectedDate!.year;
    final month = _selectedDate!.month;
    final firstDayOfMonth = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0);
    final startingWeekday = firstDayOfMonth.weekday % 7;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TSizes.sm),
      child: Column(
        children: [
          /// Weekday Headers
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((day) => Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: widget.darkMode ? TColors.grey : TColors.darkGrey,
                  ),
                ),
              ),
            ))
                .toList(),
          ),

          const SizedBox(height: 2),

          /// Days Grid
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate optimal cell size based on available space
                final cellWidth = constraints.maxWidth / 7;
                final cellHeight = (constraints.maxHeight - 8) / 6; // Account for spacing
                final cellSize = cellHeight.clamp(30.0, 50.0);

                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                    childAspectRatio: cellWidth / cellSize,
                  ),
                  itemCount: 42,
                  itemBuilder: (context, index) {
                    final day = index - startingWeekday + 1;
                    final currentDate = DateTime(year, month, day);

                    final isCurrentMonth = day > 0 && day <= lastDayOfMonth.day;
                    final isSelectable = currentDate.isAfter(firstDate.subtract(const Duration(days: 1))) &&
                        !currentDate.isAfter(lastDate);
                    final isStartDate = _isSameDay(currentDate, _startDate);
                    final isEndDate = _isSameDay(currentDate, _endDate);
                    final isInRange = currentDate.isAfter(_startDate) && currentDate.isBefore(_endDate);
                    final isToday = _isSameDay(currentDate, DateTime.now());

                    if (!isCurrentMonth) {
                      return const SizedBox.shrink();
                    }

                    return GestureDetector(
                      onTap: isSelectable
                          ? () {
                        setState(() {
                          if (_isSelectingStart) {
                            _startDate = currentDate;
                            if (_startDate.isAfter(_endDate)) {
                              _endDate = _startDate;
                            }
                            _isSelectingStart = false;
                          } else {
                            _endDate = currentDate;
                            if (_endDate.isBefore(_startDate)) {
                              final temp = _startDate;
                              _startDate = _endDate;
                              _endDate = temp;
                            }
                          }
                          widget.onDateRangeChanged(_startDate, _endDate);
                        });
                      }
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getDayBackgroundColor(
                            currentDate,
                            isStartDate,
                            isEndDate,
                            isInRange,
                            isCurrentMonth,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          border: isToday ? Border.all(color: TColors.primary, width: 1.5) : null,
                        ),
                        child: Center(
                          child: Text(
                            currentDate.day.toString(),
                            style: TextStyle(
                              color: _getDayTextColor(
                                currentDate,
                                isStartDate,
                                isEndDate,
                                isInRange,
                                isCurrentMonth,
                                isSelectable,
                              ),
                              fontWeight: isStartDate || isEndDate ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getDayBackgroundColor(
      DateTime date,
      bool isStartDate,
      bool isEndDate,
      bool isInRange,
      bool isCurrentMonth,
      ) {
    if (!isCurrentMonth) {
      return Colors.transparent;
    }
    if (isStartDate || isEndDate) {
      return TColors.primary;
    }
    if (isInRange) {
      return TColors.primary.withOpacity(0.2);
    }
    return Colors.transparent;
  }

  Color _getDayTextColor(
      DateTime date,
      bool isStartDate,
      bool isEndDate,
      bool isInRange,
      bool isCurrentMonth,
      bool isSelectable,
      ) {
    if (!isCurrentMonth) {
      return widget.darkMode ? TColors.grey : Colors.grey.shade400;
    }
    if (!isSelectable) {
      return widget.darkMode ? TColors.grey : Colors.grey.shade400;
    }
    if (isStartDate || isEndDate) {
      return Colors.white;
    }
    return widget.darkMode ? TColors.white : TColors.black;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}