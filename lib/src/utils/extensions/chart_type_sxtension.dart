import '../constants/enums.dart';

extension ChartTypeExtension on ChartType {
  String get displayName {
    switch (this) {
      case ChartType.line:
        return 'Line Chart';
      case ChartType.bar:
        return 'Bar Chart';
    }
  }

  String get description {
    switch (this) {
      case ChartType.line:
        return 'Shows trend over time with connected data points';
      case ChartType.bar:
        return 'Shows data comparison using vertical bars';
    }
  }
}