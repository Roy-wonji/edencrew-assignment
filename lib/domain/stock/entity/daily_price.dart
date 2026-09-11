class DailyPrice {
  const DailyPrice({
    required this.date,
    required this.close,
    required this.open,
    required this.high,
    required this.low,
    required this.volume,
    required this.change,
  });

  final DateTime date;
  final int close;
  final int open;
  final int high;
  final int low;
  final int volume;
  final int change;

  String get localDate {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year$month$day';
  }
}
