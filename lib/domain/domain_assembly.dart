import 'package:get_it/get_it.dart';
import '../core/network/stock_http_client.dart';
import '../core/time/clock.dart';
import 'stock/interface/stock_repository.dart';
import 'stock/repository/naver_stock_repository.dart';

abstract final class DomainAssembly {
  static void register(GetIt container, {StockRepository? stockRepository}) {
    container.registerLazySingleton<StockRepository>(
      () =>
          stockRepository ??
          NaverStockRepository(
            httpClient: container<StockHttpClient>(),
            now: container<AppClock>().now,
          ),
    );
  }
}
