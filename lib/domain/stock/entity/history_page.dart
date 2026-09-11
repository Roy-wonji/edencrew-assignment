import 'daily_price.dart';

class HistoryPage {
  const HistoryPage({
    required this.symbol,
    required this.page,
    required this.lastPage,
    required this.prices,
  });

  final String symbol;
  final int page;
  final int lastPage;
  final List<DailyPrice> prices;
}
