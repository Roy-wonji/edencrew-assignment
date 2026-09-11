import '../entity/models.dart';

List<Stock> sortWatchlist({
  required Iterable<Stock> stocks,
  required Map<String, Quote> quotesBySymbol,
  required WatchlistSort sort,
}) {
  final favorites = stocks.toList();

  int byNameThenSymbol(Stock left, Stock right) {
    final name = left.name.compareTo(right.name);
    if (name != 0) {
      return name;
    }
    return left.symbol.compareTo(right.symbol);
  }

  favorites.sort((Stock left, Stock right) {
    final leftQuote = quotesBySymbol[left.symbol];
    final rightQuote = quotesBySymbol[right.symbol];
    switch (sort) {
      case WatchlistSort.name:
        return byNameThenSymbol(left, right);
      case WatchlistSort.currentPrice:
        if (leftQuote == null && rightQuote == null) {
          return byNameThenSymbol(left, right);
        }
        if (leftQuote == null) {
          return 1;
        }
        if (rightQuote == null) {
          return -1;
        }
        final price = rightQuote.current.compareTo(leftQuote.current);
        if (price != 0) {
          return price;
        }
        return byNameThenSymbol(left, right);
      case WatchlistSort.changeRate:
        if (leftQuote == null && rightQuote == null) {
          return byNameThenSymbol(left, right);
        }
        if (leftQuote == null) {
          return 1;
        }
        if (rightQuote == null) {
          return -1;
        }
        final leftRate = leftQuote.changeRate;
        final rightRate = rightQuote.changeRate;
        if (leftRate == null && rightRate == null) {
          return byNameThenSymbol(left, right);
        }
        if (leftRate == null) {
          return 1;
        }
        if (rightRate == null) {
          return -1;
        }
        final rate = rightRate.compareTo(leftRate);
        if (rate != 0) {
          return rate;
        }
        return byNameThenSymbol(left, right);
    }
  });

  return List<Stock>.unmodifiable(favorites);
}
