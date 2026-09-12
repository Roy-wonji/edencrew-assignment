import 'package:edencrew_assignment_starter/shared/design_system/stock_icon.dart';
import 'package:flutter/material.dart';
import 'package:edencrew_assignment_starter/feature/detail/view/detail_screen.dart';
import 'package:edencrew_assignment_starter/feature/search/view/search_screen.dart';
import 'package:edencrew_assignment_starter/feature/watchlist/view/watchlist_screen.dart';
import 'package:edencrew_assignment_starter/theme/theme.dart';
import 'package:edencrew_assignment_starter/app/action/app_action.dart';
import 'package:edencrew_assignment_starter/feature/shared/state/app_tab.dart';
import 'package:edencrew_assignment_starter/app/store/app_store.dart';
import 'package:edencrew_assignment_starter/feature/shared/state/favorite_change_source.dart';

class EdencrewAssignmentApp extends StatelessWidget {
  const EdencrewAssignmentApp({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: '관심종목',
    theme: AppTheme.dark,
    home: ListenableBuilder(
      listenable: store,
      builder: (context, _) => NavigatorPopHandler<void>(
        enabled: store.state.detail.isOpen,
        onPopWithResult: (_) => store.dispatch(const DetailClosed()),
        child: Navigator(
          pages: [
            MaterialPage<void>(
              key: const ValueKey('home'),
              child: _Home(store: store),
            ),
            if (store.state.detail.isOpen)
              MaterialPage<void>(
                key: const ValueKey('detail'),
                child: DetailScreen(
                  state: store.state.detail,
                  stock: store.state.stocksById[store.state.detail.stockId]!,
                  quote:
                      store.state.quotesBySymbol[store
                          .state
                          .stocksById[store.state.detail.stockId]!
                          .symbol],
                  isFavorite: store.state.isFavorite(
                    store.state.detail.stockId!,
                  ),
                  quoteLoading: store.state.quoteLoadingSymbols.contains(
                    store.state.stocksById[store.state.detail.stockId]!.symbol,
                  ),
                  quoteError:
                      store.state.quoteErrorMessage ??
                      store.state.metadataErrorMessage,
                  onBack: () => store.dispatch(const DetailClosed()),
                  onFavorite: () => store.dispatch(
                    FavoriteToggled(
                      store.state.stocksById[store.state.detail.stockId]!,
                      source: FavoriteChangeSource.detail,
                    ),
                  ),
                  onPeriod: (period) =>
                      store.dispatch(DetailPeriodSelected(period)),
                  onLoadMoreDailyPrices: () =>
                      store.dispatch(const DetailDailyPricesMoreRequested()),
                  onRetryQuote: () => store.dispatch(
                    DetailOpened(
                      store.state.stocksById[store.state.detail.stockId]!,
                    ),
                  ),
                ),
              ),
          ],
          onDidRemovePage: (page) {
            if (page.key == const ValueKey('detail') &&
                store.state.detail.isOpen) {
              store.dispatch(const DetailClosed());
            }
          },
        ),
      ),
    ),
  );
}

class _Home extends StatelessWidget {
  const _Home({required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) {
    final state = store.state;
    final notice = state.notice;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  IndexedStack(
                    index: state.selectedTab.index,
                    children: [
                      WatchlistScreen(
                        stocks: state.favoriteStocks,
                        quotes: state.quotesBySymbol,
                        loadingSymbols: state.quoteLoadingSymbols,
                        sort: state.watchlistSort,
                        errorMessage:
                            state.quoteErrorMessage ??
                            state.metadataErrorMessage,
                        onRefresh: () =>
                            store.dispatch(const WatchlistRefreshRequested()),
                        onSort: (sort) =>
                            store.dispatch(WatchlistSortSelected(sort)),
                        onOpen: (stock) => store.dispatch(DetailOpened(stock)),
                        onRemove: (stock) => store.dispatch(
                          FavoriteToggled(
                            stock,
                            source: FavoriteChangeSource.watchlist,
                          ),
                        ),
                      ),
                      SearchScreen(
                        state: state.search,
                        results: state.searchResults,
                        favoriteIds: state.favoriteIds,
                        onQuery: (query) =>
                            store.dispatch(SearchQueryChanged(query)),
                        onFavorite: (stock) => store.dispatch(
                          FavoriteToggled(
                            stock,
                            source: FavoriteChangeSource.search,
                          ),
                        ),
                        onOpen: (stock) => store.dispatch(DetailOpened(stock)),
                      ),
                    ],
                  ),
                  if (notice != null)
                    Positioned(
                      left: context.dimens.space4,
                      right: context.dimens.space4,
                      bottom: context.dimens.space3,
                      child: IgnorePointer(
                        child: Semantics(
                          liveRegion: true,
                          child: Container(
                            height: 46,
                            padding: EdgeInsets.symmetric(
                              horizontal: context.dimens.space4,
                              vertical: context.dimens.space3,
                            ),
                            decoration: BoxDecoration(
                              color: context.colors.surfaceOverlay,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x8C000000),
                                  offset: Offset(0, 8),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                StockIcon(
                                  notice.isFavorite
                                      ? StockIconType.starFilled
                                      : StockIconType.star,
                                  color: notice.isFavorite
                                      ? context.colors.favoriteActive
                                      : context.colors.textSecondary,
                                  size: 18,
                                ),
                                SizedBox(width: context.dimens.space2),
                                Flexible(
                                  child: Text(
                                    notice.message,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 18 / 13,
                                      fontWeight: FontWeight.w700,
                                      color: context.colors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              // Figma Tab bar: 63px, with the device safe area below it.
              height: 63 + MediaQuery.paddingOf(context).bottom,
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom,
              ),
              decoration: BoxDecoration(color: context.colors.surfaceRaised),
              child: Row(
                children: [
                  for (final tab in AppTab.values)
                    Expanded(
                      child: Semantics(
                        selected: state.selectedTab == tab,
                        child: InkWell(
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            store.dispatch(AppTabSelected(tab));
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              StockIcon(
                                tab == AppTab.watchlist
                                    ? state.selectedTab == tab
                                          ? StockIconType.starFilled
                                          : StockIconType.star
                                    : StockIconType.search,
                                size: 22,
                                color: state.selectedTab == tab
                                    ? context.colors.navActive
                                    : context.colors.navInactive,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                tab == AppTab.watchlist ? '관심' : '검색',
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 14 / 11,
                                  color: state.selectedTab == tab
                                      ? context.colors.navActive
                                      : context.colors.navInactive,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
