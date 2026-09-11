String number(num value) {
  final parts = value.round().abs().toString().split('');
  final output = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < parts.length; i++) {
    if (i > 0 && (parts.length - i) % 3 == 0) output.write(',');
    output.write(parts[i]);
  }
  return output.toString();
}

String signedNumber(int value) => '${value > 0 ? '+' : ''}${number(value)}';
String percent(double? rate) => rate == null
    ? '—'
    : '${rate > 0 ? '+' : ''}${(rate * 100).toStringAsFixed(2)}%';
String compactVolume(int value) =>
    value >= 1000 ? '${number(value ~/ 1000)}천' : number(value);
String compactCap(int? value) {
  if (value == null) return '—';
  if (value >= 1000000000000) return '${number(value ~/ 1000000000000)}조';
  if (value >= 100000000) return '${number(value ~/ 100000000)}억';
  return number(value);
}

String tradingDate(DateTime value) =>
    '${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')}';
