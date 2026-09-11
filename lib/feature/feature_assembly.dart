import 'package:get_it/get_it.dart';
import 'detail/di/detail_assembly.dart';
import 'search/di/search_assembly.dart';
import 'watchlist/di/watchlist_assembly.dart';

abstract final class FeatureAssembly {
  static void register(GetIt container) {
    WatchlistAssembly.register(container);
    SearchAssembly.register(container);
    DetailAssembly.register(container);
  }
}
