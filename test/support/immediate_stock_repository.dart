import 'package:edencrew_assignment_starter/domain/stock/interface/stock_repository.dart';
import 'package:edencrew_assignment_starter/domain/stock/entity/models.dart';

class ImmediateStockRepository implements StockRepository {
  static const samsung = Stock(symbol: '005930', name: '삼성전자', market: '코스피');
  @override
  Future<List<Stock>> search(String query) async =>
      query.contains('없음') ? [] : [samsung];
  @override
  Future<Stock> metadata(String symbol) async => samsung;
  @override
  Future<Map<String, Quote>> quotes(List<String> symbols) async => {
    for (final symbol in symbols)
      symbol: Quote(
        symbol: symbol,
        current: 179700,
        previousClose: 180100,
        open: 172100,
        high: 181700,
        low: 172000,
        volume: 29113466,
        listedShares: 5919637922,
      ),
  };
  @override
  Stream<List<DailyPrice>> history(
    String symbol,
    ChartPeriod period, {
    bool Function()? isCancelled,
  }) async* {
    yield List.generate(
      period.days,
      (index) => DailyPrice(
        date: DateTime(2026, 9, 10).subtract(Duration(days: index)),
        close: 179700 - index * 100,
        open: 179500 - index * 100,
        high: 180000 - index * 100,
        low: 179000 - index * 100,
        volume: 1000000,
        change: 200,
      ),
    );
  }

  @override
  Future<void> close() async {}
}
