import 'enums.dart';

class PhysiologicalPeriodConstants {
  PhysiologicalPeriodConstants._();

  /// 生理周期时间配置 (24小时制)
  static const Map<PhysiologicalTimePeriod, _PeriodTimeRange> _periodTimeRanges = {
    PhysiologicalTimePeriod.wakeUp: _PeriodTimeRange(
      startHour: 6,   // 6:00 AM
      endHour: 7,     // 7:00 AM
      displayName: 'Wake Up',
    ),
    PhysiologicalTimePeriod.beforeBreakfast: _PeriodTimeRange(
      startHour: 7,   // 7:00 AM
      endHour: 9,     // 9:00 AM
      displayName: 'Before Breakfast',
    ),
    PhysiologicalTimePeriod.afterBreakfast: _PeriodTimeRange(
      startHour: 9,   // 9:00 AM
      endHour: 11,    // 11:00 AM
      displayName: 'After Breakfast',
    ),
    PhysiologicalTimePeriod.beforeLunch: _PeriodTimeRange(
      startHour: 11,  // 11:00 AM
      endHour: 13,    // 1:00 PM
      displayName: 'Before Lunch',
    ),
    PhysiologicalTimePeriod.afterLunch: _PeriodTimeRange(
      startHour: 13,  // 1:00 PM
      endHour: 15,    // 3:00 PM
      displayName: 'After Lunch',
    ),
    PhysiologicalTimePeriod.beforeSnack: _PeriodTimeRange(
      startHour: 15,  // 3:00 PM
      endHour: 16,    // 4:00 PM
      displayName: 'Before Snack',
    ),
    PhysiologicalTimePeriod.afterSnack: _PeriodTimeRange(
      startHour: 16,  // 4:00 PM
      endHour: 17,    // 5:00 PM
      displayName: 'After Snack',
    ),
    PhysiologicalTimePeriod.beforeDinner: _PeriodTimeRange(
      startHour: 17,  // 5:00 PM
      endHour: 19,    // 7:00 PM
      displayName: 'Before Dinner',
    ),
    PhysiologicalTimePeriod.afterDinner: _PeriodTimeRange(
      startHour: 19,  // 7:00 PM
      endHour: 21,    // 9:00 PM
      displayName: 'After Dinner',
    ),
    PhysiologicalTimePeriod.bedtime: _PeriodTimeRange(
      startHour: 21,  // 11:00 PM
      endHour: 6,     // 4:00 AM (次日)
      displayName: 'Bedtime',
      isOvernight: true,
    ),
  };

  /// 根据时间获取对应的生理周期
  static PhysiologicalTimePeriod getPeriodForTime(DateTime dateTime) {
    final hour = dateTime.hour;

    for (final entry in _periodTimeRanges.entries) {
      final period = entry.key;
      final range = entry.value;

      if (range.isOvernight) {
        // 处理跨夜的时段 (23:00 - 4:00)
        if (hour >= range.startHour || hour < range.endHour) {
          return period;
        }
      } else {
        // 处理普通时段
        if (hour >= range.startHour && hour < range.endHour) {
          return period;
        }
      }
    }

    // 默认返回 bedtime (理论上不会执行到这里)
    return PhysiologicalTimePeriod.bedtime;
  }

  /// 获取生理周期的显示名称
  static String getDisplayName(PhysiologicalTimePeriod period) {
    return _periodTimeRanges[period]?.displayName ?? period.displayName;
  }

  /// 获取生理周期的时间范围描述
  static String getTimeRangeDescription(PhysiologicalTimePeriod period) {
    final range = _periodTimeRanges[period];
    if (range == null) return '';

    if (range.isOvernight) {
      return '${_formatHour(range.startHour)} - ${_formatHour(range.endHour)} (next day)';
    } else {
      return '${_formatHour(range.startHour)} - ${_formatHour(range.endHour)}';
    }
  }

  /// 获取所有生理周期及其时间范围
  static Map<PhysiologicalTimePeriod, String> getAllPeriodsWithTimeRanges() {
    final Map<PhysiologicalTimePeriod, String> result = {};

    for (final entry in _periodTimeRanges.entries) {
      final period = entry.key;
      final timeRange = getTimeRangeDescription(period);
      result[period] = timeRange;
    }

    return result;
  }

  /// 格式化小时为12小时制
  static String _formatHour(int hour) {
    if (hour == 0 || hour == 24) return '12:00 AM';
    if (hour == 12) return '12:00 PM';
    if (hour < 12) return '$hour:00 AM';
    return '${hour - 12}:00 PM';
  }

  /// 检查时间是否在某个生理周期内
  static bool isTimeInPeriod(DateTime dateTime, PhysiologicalTimePeriod period) {
    return getPeriodForTime(dateTime) == period;
  }

  /// 获取下一个生理周期
  static PhysiologicalTimePeriod? getNextPeriod(DateTime currentTime) {
    final currentPeriod = getPeriodForTime(currentTime);
    final allPeriods = PhysiologicalTimePeriod.values;
    final currentIndex = allPeriods.indexOf(currentPeriod);

    if (currentIndex != -1 && currentIndex < allPeriods.length - 1) {
      return allPeriods[currentIndex + 1];
    } else if (currentIndex == allPeriods.length - 1) {
      return allPeriods.first; // 循环到第一个
    }

    return null;
  }

  /// 检查是否是餐前时段
  static bool isBeforeMealPeriod(PhysiologicalTimePeriod period) {
    return period == PhysiologicalTimePeriod.beforeBreakfast ||
        period == PhysiologicalTimePeriod.beforeLunch ||
        period == PhysiologicalTimePeriod.beforeSnack ||
        period == PhysiologicalTimePeriod.beforeDinner;
  }

  /// 检查是否是餐后时段
  static bool isAfterMealPeriod(PhysiologicalTimePeriod period) {
    return period == PhysiologicalTimePeriod.afterBreakfast ||
        period == PhysiologicalTimePeriod.afterLunch ||
        period == PhysiologicalTimePeriod.afterSnack ||
        period == PhysiologicalTimePeriod.afterDinner;
  }
}

/// 生理周期时间范围数据类
class _PeriodTimeRange {
  final int startHour;
  final int endHour;
  final String displayName;
  final bool isOvernight;

  const _PeriodTimeRange({
    required this.startHour,
    required this.endHour,
    required this.displayName,
    this.isOvernight = false,
  });
}