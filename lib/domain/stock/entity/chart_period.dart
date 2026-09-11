enum ChartPeriod {
  month1(days: 20, requiredPages: 2, label: '1개월'),
  month3(days: 60, requiredPages: 6, label: '3개월'),
  month6(days: 120, requiredPages: 12, label: '6개월'),
  year1(days: 245, requiredPages: 25, label: '1년');

  const ChartPeriod({
    required this.days,
    required this.requiredPages,
    required this.label,
  });

  final int days;
  final int requiredPages;
  final String label;
}
