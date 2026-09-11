import 'package:edencrew_assignment_starter/core/state/app_action.dart';
import 'package:edencrew_assignment_starter/domain/stock/entity/watchlist_sort.dart';

sealed class WatchlistAction implements AppAction {
  const WatchlistAction();
}

final class WatchlistSortSelected extends WatchlistAction {
  const WatchlistSortSelected(this.sort);

  final WatchlistSort sort;
}

final class WatchlistRefreshRequested extends WatchlistAction {
  const WatchlistRefreshRequested();
}
