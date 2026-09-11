class Quote {
  const Quote({
    required this.symbol,
    required this.current,
    required this.previousClose,
    required this.open,
    required this.high,
    required this.low,
    required this.volume,
    this.listedShares,
  });

  final String symbol;
  final int current;
  final int previousClose;
  final int open;
  final int high;
  final int low;
  final int volume;
  final int? listedShares;

  int get change => current - previousClose;

  double? get changeRate {
    if (previousClose == 0) {
      return null;
    }
    return change / previousClose;
  }

  int? get marketCap {
    final shares = listedShares;
    if (shares == null) {
      return null;
    }
    return current * shares;
  }

  bool get isUp => change > 0;
  bool get isDown => change < 0;
  bool get isFlat => change == 0;
}
