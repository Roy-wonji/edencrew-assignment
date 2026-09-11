import 'package:edencrew_assignment_starter/domain/stock/entity/watchlist_sort.dart';
import 'package:edencrew_assignment_starter/feature/watchlist/action/watchlist_action.dart';

typedef WatchlistReducer =
    WatchlistSort Function(WatchlistSort state, WatchlistAction action);

WatchlistSort reduceWatchlistSort(WatchlistSort state, WatchlistAction action) {
  return switch (action) {
    WatchlistSortSelected(:final sort) => sort,
    WatchlistRefreshRequested() => state,
  };
}
