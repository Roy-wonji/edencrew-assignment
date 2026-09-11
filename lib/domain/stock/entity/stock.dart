class Stock {
  const Stock({required this.symbol, required this.name, required this.market});

  final String symbol;
  final String name;
  final String market;

  String get id => 'domestic:$symbol';

  Stock copyWith({String? symbol, String? name, String? market}) {
    return Stock(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      market: market ?? this.market,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Stock &&
            runtimeType == other.runtimeType &&
            symbol == other.symbol &&
            name == other.name &&
            market == other.market;
  }

  @override
  int get hashCode => Object.hash(symbol, name, market);
}
