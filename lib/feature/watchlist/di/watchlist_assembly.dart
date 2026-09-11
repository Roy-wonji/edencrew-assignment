import 'package:get_it/get_it.dart';
import '../reducer/watchlist_reducer.dart';

abstract final class WatchlistAssembly {
  static void register(GetIt container) {
    container.registerSingleton<WatchlistReducer>(reduceWatchlistSort);
  }
}
