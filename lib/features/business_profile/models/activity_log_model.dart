enum ActivityTimePeriod { day1, week1, month1, month3, month6, custom }

extension ActivityTimePeriodLabel on ActivityTimePeriod {
  String get label {
    switch (this) {
      case ActivityTimePeriod.day1:
        return '1 Day';
      case ActivityTimePeriod.week1:
        return '1 Week';
      case ActivityTimePeriod.month1:
        return '1 Month';
      case ActivityTimePeriod.month3:
        return '3 Months';
      case ActivityTimePeriod.month6:
        return '6 Months';
      case ActivityTimePeriod.custom:
        return 'Custom Range';
    }
  }
}

enum ActivityType { itemPurchased, itemSold, itemAddedModified, custAddedModified }

class ActivityLogEntry {
  final String id;
  final ActivityType type;
  final String title;
  final String subtitle;
  final double? amount;
  final DateTime timestamp;

  const ActivityLogEntry({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle = '',
    this.amount,
    required this.timestamp,
  });
}