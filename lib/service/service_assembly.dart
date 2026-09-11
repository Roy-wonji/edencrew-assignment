import 'package:get_it/get_it.dart';
import '../core/network/stock_http_client.dart';
import 'naver/endpoint/naver_endpoints.dart';

abstract final class ServiceAssembly {
  static void register(GetIt container, {StockHttpClient? httpClient}) {
    container.registerLazySingleton<StockHttpClient>(
      () =>
          httpClient ?? DartIoStockHttpClient(headers: NaverEndpoints.headers),
    );
  }
}
