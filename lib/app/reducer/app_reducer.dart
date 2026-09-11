import 'package:edencrew_assignment_starter/app/effect/app_effect.dart';
import 'package:edencrew_assignment_starter/app/state/app_state.dart';
import 'package:edencrew_assignment_starter/core/state/app_action.dart';
import 'package:edencrew_assignment_starter/domain/stock/entity/models.dart';
import 'package:edencrew_assignment_starter/feature/detail/action/detail_action.dart';
import 'package:edencrew_assignment_starter/feature/detail/reducer/detail_reducer.dart';
import 'package:edencrew_assignment_starter/feature/search/action/search_action.dart';
import 'package:edencrew_assignment_starter/feature/search/reducer/search_reducer.dart';
import 'package:edencrew_assignment_starter/feature/shared/action/shared_action.dart';
import 'package:edencrew_assignment_starter/feature/shared/state/app_notice.dart';
import 'package:edencrew_assignment_starter/feature/shared/state/favorite_change_source.dart';
import 'package:edencrew_assignment_starter/feature/watchlist/action/watchlist_action.dart';
import 'package:edencrew_assignment_starter/feature/watchlist/reducer/watchlist_reducer.dart';

typedef AppReducer = ReduceResult Function(AppState state, AppAction action);

final class ReduceResult {
  const ReduceResult(this.state, [this.effects = const <AppEffect>[]]);

  final AppState state;
  final List<AppEffect> effects;
}

ReduceResult appReducer(AppState state, AppAction action) =>
    const ComposedAppReducer().call(state, action);

final class ComposedAppReducer {
  const ComposedAppReducer({
    this.search = reduceSearch,
    this.detail = reduceDetail,
    this.watchlist = reduceWatchlistSort,
  });
  final SearchReducer search;
  final DetailReducer detail;
  final WatchlistReducer watchlist;

  ReduceResult call(AppState state, AppAction action) {
    switch (action) {
      case AppStarted():
        return _refreshFavorites(state);
      case AppTabSelected(:final tab):
        return ReduceResult(state.copyWith(selectedTab: tab));
      case WatchlistRefreshRequested():
        return _refreshFavorites(state);
      case WatchlistAction():
        return ReduceResult(
          state.copyWith(watchlistSort: watchlist(state.watchlistSort, action)),
        );
      case FavoriteToggled(:final stock, :final source):
        return _toggleFavorite(state, stock, source);
      case QuotesSucceeded(
        :final requestIdsBySymbol,
        :final symbols,
        :final quotes,
      ):
        return _quotesSucceeded(state, requestIdsBySymbol, symbols, quotes);
      case QuotesFailed(
        :final requestIdsBySymbol,
        :final symbols,
        :final message,
      ):
        return _quotesFailed(state, requestIdsBySymbol, symbols, message);
      case MetadataSucceeded(:final stock):
        return _metadataSucceeded(state, stock);
      case MetadataFailed(:final message):
        return ReduceResult(state.copyWith(metadataErrorMessage: message));
      case SearchQueryChanged(:final query):
        return _queryChanged(state, action, query);
      case SearchSucceeded(:final results):
        return _searchResult(state, action, results);
      case SearchFailed():
        return ReduceResult(
          state.copyWith(search: search(state.search, action)),
        );
      case DetailOpened(:final stock):
        return _openDetail(state, action, stock);
      case DetailClosed():
        return ReduceResult(
          state.copyWith(detail: detail(state.detail, action)),
          const <AppEffect>[CancelDetailHistoryEffect()],
        );
      case DetailPeriodSelected(:final period):
        return _selectDetailPeriod(state, action, period);
      case DetailHistoryUpdated():
        return ReduceResult(
          state.copyWith(detail: detail(state.detail, action)),
        );
      case DetailHistoryFailed():
        return ReduceResult(
          state.copyWith(detail: detail(state.detail, action)),
        );
      case NoticeExpired(:final noticeId):
        if (state.notice?.id != noticeId) {
          return ReduceResult(state);
        }
        return ReduceResult(state.copyWith(clearNotice: true));
    }

    return ReduceResult(state);
  }

  ReduceResult _refreshFavorites(AppState state) {
    final symbols = state.favoriteStocks
        .map((Stock stock) => stock.symbol)
        .toList(growable: false);
    if (symbols.isEmpty) {
      return ReduceResult(state.copyWith(clearQuoteErrorMessage: true));
    }

    final quoteRequest = _nextQuoteRequest(state, symbols);
    return ReduceResult(
      state.copyWith(
        quoteRequestIdsBySymbol: quoteRequest.requestIdsBySymbol,
        nextQuoteRequestId: quoteRequest.nextRequestId,
        quoteLoadingSymbols: <String>{...state.quoteLoadingSymbols, ...symbols},
        quoteFailedSymbols: <String>{...state.quoteFailedSymbols}
          ..removeAll(symbols),
        clearQuoteErrorMessage: true,
      ),
      <AppEffect>[
        RefreshQuotesEffect(
          requestIdsBySymbol: quoteRequest.effectRequestIds,
          symbols: symbols,
        ),
      ],
    );
  }

  ReduceResult _toggleFavorite(
    AppState state,
    Stock stock,
    FavoriteChangeSource source,
  ) {
    final stocksById = <String, Stock>{...state.stocksById, stock.id: stock};
    final favoriteIds = <String>{...state.favoriteIds};
    final wasFavorite = favoriteIds.contains(stock.id);
    if (wasFavorite) {
      favoriteIds.remove(stock.id);
    } else {
      favoriteIds.add(stock.id);
    }

    var nextState = state.copyWith(
      stocksById: stocksById,
      favoriteIds: favoriteIds,
    );
    final effects = <AppEffect>[];
    if (!wasFavorite && !state.quotesBySymbol.containsKey(stock.symbol)) {
      final quoteRequest = _nextQuoteRequest(nextState, <String>[stock.symbol]);
      nextState = nextState.copyWith(
        quoteRequestIdsBySymbol: quoteRequest.requestIdsBySymbol,
        nextQuoteRequestId: quoteRequest.nextRequestId,
        quoteLoadingSymbols: <String>{
          ...nextState.quoteLoadingSymbols,
          stock.symbol,
        },
        quoteFailedSymbols: <String>{...nextState.quoteFailedSymbols}
          ..remove(stock.symbol),
      );
      effects.add(
        RefreshQuotesEffect(
          requestIdsBySymbol: quoteRequest.effectRequestIds,
          symbols: <String>[stock.symbol],
        ),
      );
    }
    if (!wasFavorite) {
      effects.add(LoadMetadataEffect(stock.symbol));
    }

    if (source == FavoriteChangeSource.search) {
      final noticeId = nextState.nextNoticeId;
      final isFavorite = !wasFavorite;
      nextState = nextState.copyWith(
        notice: AppNotice(
          id: noticeId,
          message: isFavorite ? '관심이 등록되었습니다' : '관심이 해제되었습니다',
          isFavorite: isFavorite,
        ),
        nextNoticeId: noticeId + 1,
      );
      effects.add(DismissNoticeEffect(noticeId));
    }

    return ReduceResult(nextState, effects);
  }

  ReduceResult _quotesSucceeded(
    AppState state,
    Map<String, int> requestIdsBySymbol,
    List<String> symbols,
    Map<String, Quote> quotes,
  ) {
    final matchingSymbols = _matchingQuoteSymbols(
      state,
      requestIdsBySymbol,
      symbols,
    );
    if (matchingSymbols.isEmpty) {
      return ReduceResult(state);
    }

    final nextQuotes = <String, Quote>{...state.quotesBySymbol};
    for (final symbol in matchingSymbols) {
      final quote = quotes[symbol];
      if (quote != null) {
        nextQuotes[symbol] = quote;
      }
    }

    return ReduceResult(
      state.copyWith(
        quotesBySymbol: nextQuotes,
        quoteLoadingSymbols: <String>{...state.quoteLoadingSymbols}
          ..removeAll(matchingSymbols),
        quoteFailedSymbols: <String>{...state.quoteFailedSymbols}
          ..removeAll(matchingSymbols),
        clearQuoteErrorMessage: true,
      ),
    );
  }

  ReduceResult _quotesFailed(
    AppState state,
    Map<String, int> requestIdsBySymbol,
    List<String> symbols,
    String message,
  ) {
    final matchingSymbols = _matchingQuoteSymbols(
      state,
      requestIdsBySymbol,
      symbols,
    );
    if (matchingSymbols.isEmpty) {
      return ReduceResult(state);
    }

    return ReduceResult(
      state.copyWith(
        quoteLoadingSymbols: <String>{...state.quoteLoadingSymbols}
          ..removeAll(matchingSymbols),
        quoteFailedSymbols: <String>{
          ...state.quoteFailedSymbols,
          ...matchingSymbols,
        },
        quoteErrorMessage: message,
      ),
    );
  }

  ReduceResult _metadataSucceeded(AppState state, Stock stock) {
    final previous = state.stocksById[stock.id];
    if (previous == stock) {
      return ReduceResult(state);
    }

    return ReduceResult(
      state.copyWith(
        stocksById: <String, Stock>{...state.stocksById, stock.id: stock},
        clearMetadataErrorMessage: true,
      ),
    );
  }

  ReduceResult _queryChanged(
    AppState state,
    SearchQueryChanged action,
    String query,
  ) {
    final search = this.search(state.search, action);
    if (query.trim().isEmpty) {
      return ReduceResult(state.copyWith(search: search));
    }

    return ReduceResult(state.copyWith(search: search), <AppEffect>[
      SearchStocksEffect(requestId: search.requestId, query: query.trim()),
    ]);
  }

  ReduceResult _searchResult(
    AppState state,
    SearchAction action,
    List<Stock> results,
  ) {
    final search = this.search(state.search, action);
    if (identical(search, state.search)) {
      return ReduceResult(state);
    }

    final stocksById = <String, Stock>{...state.stocksById};
    for (final stock in results) {
      stocksById[stock.id] = stock;
    }

    return ReduceResult(state.copyWith(stocksById: stocksById, search: search));
  }

  ReduceResult _openDetail(AppState state, DetailOpened action, Stock stock) {
    final detail = this.detail(state.detail, action);
    var nextState = state.copyWith(
      stocksById: <String, Stock>{...state.stocksById, stock.id: stock},
      detail: detail,
    );
    final effects = <AppEffect>[];

    if (!state.quotesBySymbol.containsKey(stock.symbol)) {
      final quoteRequest = _nextQuoteRequest(nextState, <String>[stock.symbol]);
      nextState = nextState.copyWith(
        quoteRequestIdsBySymbol: quoteRequest.requestIdsBySymbol,
        nextQuoteRequestId: quoteRequest.nextRequestId,
        quoteLoadingSymbols: <String>{
          ...nextState.quoteLoadingSymbols,
          stock.symbol,
        },
        quoteFailedSymbols: <String>{...nextState.quoteFailedSymbols}
          ..remove(stock.symbol),
      );
      effects.add(
        RefreshQuotesEffect(
          requestIdsBySymbol: quoteRequest.effectRequestIds,
          symbols: <String>[stock.symbol],
        ),
      );
    }

    effects
      ..add(LoadMetadataEffect(stock.symbol))
      ..add(
        LoadDetailHistoryEffect(
          requestId: detail.requestId,
          stock: stock,
          period: detail.period,
        ),
      );

    return ReduceResult(nextState, effects);
  }

  ReduceResult _selectDetailPeriod(
    AppState state,
    DetailPeriodSelected action,
    ChartPeriod period,
  ) {
    final stock = state.detail.stockId == null
        ? null
        : state.stocksById[state.detail.stockId];
    if (stock == null) {
      return ReduceResult(state);
    }

    final detail = this.detail(state.detail, action);
    return ReduceResult(state.copyWith(detail: detail), <AppEffect>[
      LoadDetailHistoryEffect(
        requestId: detail.requestId,
        stock: stock,
        period: period,
      ),
    ]);
  }

  _QuoteRequest _nextQuoteRequest(AppState state, List<String> symbols) {
    final nextRequestId = state.nextQuoteRequestId;
    final requestIdsBySymbol = <String, int>{...state.quoteRequestIdsBySymbol};
    for (var index = 0; index < symbols.length; index += 1) {
      requestIdsBySymbol[symbols[index]] = nextRequestId + index;
    }
    return _QuoteRequest(
      requestIdsBySymbol: requestIdsBySymbol,
      effectRequestIds: <String, int>{
        for (final symbol in symbols) symbol: requestIdsBySymbol[symbol]!,
      },
      nextRequestId: nextRequestId + symbols.length,
    );
  }

  List<String> _matchingQuoteSymbols(
    AppState state,
    Map<String, int> requestIdsBySymbol,
    List<String> symbols,
  ) {
    return symbols
        .where((symbol) {
          return state.quoteRequestIdsBySymbol[symbol] ==
              requestIdsBySymbol[symbol];
        })
        .toList(growable: false);
  }
}

final class _QuoteRequest {
  const _QuoteRequest({
    required this.requestIdsBySymbol,
    required this.effectRequestIds,
    required this.nextRequestId,
  });

  final Map<String, int> requestIdsBySymbol;
  final Map<String, int> effectRequestIds;
  final int nextRequestId;
}
