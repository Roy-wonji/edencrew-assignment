import 'package:edencrew_assignment_starter/domain/stock/use_case/sort_watchlist.dart';
import 'package:edencrew_assignment_starter/domain/stock/entity/models.dart';
import 'package:edencrew_assignment_starter/feature/detail/state/detail_state.dart';
import 'package:edencrew_assignment_starter/feature/search/state/search_state.dart';
import 'package:edencrew_assignment_starter/feature/shared/state/app_notice.dart';
import 'package:edencrew_assignment_starter/feature/shared/state/app_tab.dart';

final class AppState {
  const AppState({
    this.selectedTab = AppTab.watchlist,
    this.stocksById = const <String, Stock>{},
    this.favoriteIds = const <String>{},
    this.quotesBySymbol = const <String, Quote>{},
    this.quoteLoadingSymbols = const <String>{},
    this.quoteFailedSymbols = const <String>{},
    this.quoteRequestIdsBySymbol = const <String, int>{},
    this.nextQuoteRequestId = 1,
    this.watchlistSort = WatchlistSort.currentPrice,
    this.search = const SearchState(),
    this.detail = const DetailState(),
    this.notice,
    this.nextNoticeId = 1,
    this.quoteErrorMessage,
    this.metadataErrorMessage,
  });

  final AppTab selectedTab;
  final Map<String, Stock> stocksById;
  final Set<String> favoriteIds;
  final Map<String, Quote> quotesBySymbol;
  final Set<String> quoteLoadingSymbols;
  final Set<String> quoteFailedSymbols;
  final Map<String, int> quoteRequestIdsBySymbol;
  final int nextQuoteRequestId;
  final WatchlistSort watchlistSort;
  final SearchState search;
  final DetailState detail;
  final AppNotice? notice;
  final int nextNoticeId;
  final String? quoteErrorMessage;
  final String? metadataErrorMessage;

  Stock? stockById(String id) => stocksById[id];

  bool isFavorite(String stockId) => favoriteIds.contains(stockId);

  List<Stock> get searchResults {
    return search.resultIds
        .map((String id) => stocksById[id])
        .whereType<Stock>()
        .toList(growable: false);
  }

  List<Stock> get favoriteStocks => sortWatchlist(
    stocks: favoriteIds.map((id) => stocksById[id]).whereType<Stock>(),
    quotesBySymbol: quotesBySymbol,
    sort: watchlistSort,
  );

  AppState copyWith({
    AppTab? selectedTab,
    Map<String, Stock>? stocksById,
    Set<String>? favoriteIds,
    Map<String, Quote>? quotesBySymbol,
    Set<String>? quoteLoadingSymbols,
    Set<String>? quoteFailedSymbols,
    Map<String, int>? quoteRequestIdsBySymbol,
    int? nextQuoteRequestId,
    WatchlistSort? watchlistSort,
    SearchState? search,
    DetailState? detail,
    AppNotice? notice,
    int? nextNoticeId,
    String? quoteErrorMessage,
    String? metadataErrorMessage,
    bool clearNotice = false,
    bool clearQuoteErrorMessage = false,
    bool clearMetadataErrorMessage = false,
  }) {
    return AppState(
      selectedTab: selectedTab ?? this.selectedTab,
      stocksById: Map<String, Stock>.unmodifiable(
        stocksById ?? this.stocksById,
      ),
      favoriteIds: Set<String>.unmodifiable(favoriteIds ?? this.favoriteIds),
      quotesBySymbol: Map<String, Quote>.unmodifiable(
        quotesBySymbol ?? this.quotesBySymbol,
      ),
      quoteLoadingSymbols: Set<String>.unmodifiable(
        quoteLoadingSymbols ?? this.quoteLoadingSymbols,
      ),
      quoteFailedSymbols: Set<String>.unmodifiable(
        quoteFailedSymbols ?? this.quoteFailedSymbols,
      ),
      quoteRequestIdsBySymbol: Map<String, int>.unmodifiable(
        quoteRequestIdsBySymbol ?? this.quoteRequestIdsBySymbol,
      ),
      nextQuoteRequestId: nextQuoteRequestId ?? this.nextQuoteRequestId,
      watchlistSort: watchlistSort ?? this.watchlistSort,
      search: search ?? this.search,
      detail: detail ?? this.detail,
      notice: clearNotice ? null : notice ?? this.notice,
      nextNoticeId: nextNoticeId ?? this.nextNoticeId,
      quoteErrorMessage: clearQuoteErrorMessage
          ? null
          : quoteErrorMessage ?? this.quoteErrorMessage,
      metadataErrorMessage: clearMetadataErrorMessage
          ? null
          : metadataErrorMessage ?? this.metadataErrorMessage,
    );
  }
}
