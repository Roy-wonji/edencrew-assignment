import '../entity/models.dart';

abstract interface class StockRepository {
  Future<List<Stock>> search(String query);

  Future<Stock> metadata(String symbol);

  Future<Map<String, Quote>> quotes(List<String> symbols);

  Stream<List<DailyPrice>> history(
    String symbol,
    ChartPeriod period, {
    bool Function()? isCancelled,
  });

  Future<void> close();
}

class StockRepositoryException implements Exception {
  const StockRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'StockRepositoryException: $message';
}

class StockParseException extends StockRepositoryException {
  const StockParseException(super.message);
}
