import '../constants/enums.dart';

extension ReportPeriodExtension on ReportPeriod {
  String get displayName {
    switch (this) {
      case ReportPeriod.monthly:
        return 'Monthly';
      case ReportPeriod.yearly:
        return 'Yearly';
    }
  }

  String get description {
    switch (this) {
      case ReportPeriod.monthly:
        return 'View weekly data for a specific month';
      case ReportPeriod.yearly:
        return 'View monthly data for a specific year';
    }
  }
}