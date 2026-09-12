import 'dart:async';

import 'package:edencrew_assignment_starter/app/action/app_action.dart';
import 'package:edencrew_assignment_starter/app/bootstrap.dart';
import 'package:edencrew_assignment_starter/app/effect/app_effect.dart';
import 'package:edencrew_assignment_starter/app/effect/effect_runner.dart';
import 'package:edencrew_assignment_starter/app/reducer/app_reducer.dart';
import 'package:edencrew_assignment_starter/app/state/app_state.dart';
import 'package:edencrew_assignment_starter/app/store/app_store.dart';
import 'package:edencrew_assignment_starter/core/storage/app_preferences.dart';
import 'package:edencrew_assignment_starter/core/time/scheduler.dart';
import 'package:edencrew_assignment_starter/domain/stock/entity/models.dart';
import 'package:edencrew_assignment_starter/domain/stock/interface/stock_repository.dart';
import 'package:edencrew_assignment_starter/feature/shared/state/app_tab.dart';
import 'package:edencrew_assignment_starter/feature/shared/state/favorite_change_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('search responses only update the latest matching request', () async {
    final repository = FakeStockRepository();
    final store = _createStore(repository);

    store.dispatch(const SearchQueryChanged('삼'));
    store.dispatch(const SearchQueryChanged('카'));

    repository.completeSearch('카', <Stock>[_kakao]);
    await _flush();
    expect(store.state.search.query, '카');
    expect(store.state.searchResults, <Stock>[_kakao]);

    repository.completeSearch('삼', <Stock>[_samsung]);
    await _flush();
    expect(store.state.search.query, '카');
    expect(store.state.searchResults, <Stock>[_kakao]);
  });

  test('search is debounced and recent searches are persisted', () async {
    final repository = FakeStockRepository();
    final scheduler = FakeScheduler();
    final preferences = MemoryAppPreferences();
    final store = _createStore(
      repository,
      scheduler: scheduler,
      preferences: preferences,
      searchDebounceDuration: const Duration(milliseconds: 300),
    );

    store.dispatch(const SearchQueryChanged('삼'));
    store.dispatch(const SearchQueryChanged('삼성'));
    expect(repository.searchCompleters, isEmpty);

    scheduler.triggerLast();
    expect(repository.searchCompleters.keys, <String>['삼성']);

    repository.completeSearch('삼성', <Stock>[_samsung]);
    await _flush();
    await _flush();

    expect(store.state.search.recentSearches, <String>['삼성']);
    expect(preferences.snapshot.recentSearches, <String>['삼성']);
  });

  test('preferences hydrate favorites, sort and recent searches', () async {
    final repository = FakeStockRepository();
    final preferences = MemoryAppPreferences(
      const AppPreferencesSnapshot(
        favoriteStocks: <Stock>[_samsung],
        watchlistSort: WatchlistSort.name,
        recentSearches: <String>['카카오'],
      ),
    );
    final store = _createStore(repository, preferences: preferences);

    store.dispatch(const AppStarted());
    await _flush();

    expect(store.state.favoriteStocks, <Stock>[_samsung]);
    expect(store.state.watchlistSort, WatchlistSort.name);
    expect(store.state.search.recentSearches, <String>['카카오']);
    expect(repository.quoteCalls.single, <String>[_samsung.symbol]);
  });

  test(
    'favorite stocks share one immutable source and refresh in one batch',
    () async {
      final repository = FakeStockRepository();
      final store = _createStore(repository);

      store.dispatch(
        const FavoriteToggled(_samsung, source: FavoriteChangeSource.search),
      );
      store.dispatch(
        const FavoriteToggled(_kakao, source: FavoriteChangeSource.detail),
      );

      expect(store.state.isFavorite(_samsung.id), isTrue);
      expect(store.state.isFavorite(_kakao.id), isTrue);

      store.dispatch(const WatchlistRefreshRequested());
      expect(repository.quoteCalls.last, <String>['005930', '035720']);

      store.dispatch(
        const FavoriteToggled(_samsung, source: FavoriteChangeSource.detail),
      );
      expect(store.state.isFavorite(_samsung.id), isFalse);
      expect(store.state.favoriteStocks, <Stock>[_kakao]);
    },
  );

  test(
    'quote failures mark symbols as failed until the next refresh succeeds',
    () async {
      final repository = FakeStockRepository()
        ..quoteError = Exception('blocked');
      final store = _createStore(repository);

      store.dispatch(
        const FavoriteToggled(_samsung, source: FavoriteChangeSource.watchlist),
      );
      await _flush();

      expect(store.state.quoteLoadingSymbols, isNot(contains(_samsung.symbol)));
      expect(store.state.quoteFailedSymbols, contains(_samsung.symbol));

      repository.quoteError = null;
      store.dispatch(const WatchlistRefreshRequested());
      await _flush();

      expect(store.state.quoteFailedSymbols, isNot(contains(_samsung.symbol)));
      expect(store.state.quotesBySymbol[_samsung.symbol], isNotNull);
    },
  );

  test('quote responses are guarded per symbol for overlapping batches', () {
    final first = appReducer(
      AppState(
        stocksById: <String, Stock>{_samsung.id: _samsung, _kakao.id: _kakao},
        favoriteIds: <String>{_samsung.id, _kakao.id},
      ),
      const WatchlistRefreshRequested(),
    );
    final second = appReducer(
      first.state.copyWith(
        stocksById: <String, Stock>{_kakao.id: _kakao, _naver.id: _naver},
        favoriteIds: <String>{_kakao.id, _naver.id},
      ),
      const WatchlistRefreshRequested(),
    );

    final firstEffect = first.effects.single as RefreshQuotesEffect;
    final secondEffect = second.effects.whereType<RefreshQuotesEffect>().single;
    var state = second.state;

    state = appReducer(
      state,
      QuotesSucceeded(
        requestIdsBySymbol: secondEffect.requestIdsBySymbol,
        symbols: secondEffect.symbols,
        quotes: <String, Quote>{
          _kakao.symbol: _quote(_kakao.symbol, current: 41000, previous: 40000),
          _naver.symbol: _quote(
            _naver.symbol,
            current: 210000,
            previous: 200000,
          ),
        },
      ),
    ).state;
    expect(state.quoteLoadingSymbols, contains(_samsung.symbol));
    expect(state.quoteLoadingSymbols, isNot(contains(_kakao.symbol)));
    expect(state.quoteLoadingSymbols, isNot(contains(_naver.symbol)));

    state = appReducer(
      state,
      QuotesSucceeded(
        requestIdsBySymbol: firstEffect.requestIdsBySymbol,
        symbols: firstEffect.symbols,
        quotes: <String, Quote>{
          _samsung.symbol: _quote(
            _samsung.symbol,
            current: 70000,
            previous: 69000,
          ),
          _kakao.symbol: _quote(_kakao.symbol, current: 30000, previous: 40000),
        },
      ),
    ).state;

    expect(state.quotesBySymbol[_samsung.symbol]?.current, 70000);
    expect(state.quotesBySymbol[_kakao.symbol]?.current, 41000);
    expect(state.quotesBySymbol[_naver.symbol]?.current, 210000);
    expect(state.quoteLoadingSymbols, isEmpty);
  });

  test('disjoint quote batches do not invalidate each other', () {
    final first = appReducer(
      AppState(
        stocksById: <String, Stock>{_samsung.id: _samsung},
        favoriteIds: <String>{_samsung.id},
      ),
      const WatchlistRefreshRequested(),
    );
    final second = appReducer(
      first.state,
      const FavoriteToggled(_kakao, source: FavoriteChangeSource.watchlist),
    );

    final firstEffect = first.effects.single as RefreshQuotesEffect;
    final secondEffect = second.effects.whereType<RefreshQuotesEffect>().single;
    var state = second.state;

    state = appReducer(
      state,
      QuotesSucceeded(
        requestIdsBySymbol: firstEffect.requestIdsBySymbol,
        symbols: firstEffect.symbols,
        quotes: <String, Quote>{
          _samsung.symbol: _quote(
            _samsung.symbol,
            current: 70000,
            previous: 69000,
          ),
        },
      ),
    ).state;
    expect(state.quotesBySymbol[_samsung.symbol]?.current, 70000);

    state = appReducer(
      state,
      QuotesSucceeded(
        requestIdsBySymbol: secondEffect.requestIdsBySymbol,
        symbols: secondEffect.symbols,
        quotes: <String, Quote>{
          _samsung.symbol: _quote(
            _samsung.symbol,
            current: 71000,
            previous: 69000,
          ),
          _kakao.symbol: _quote(_kakao.symbol, current: 41000, previous: 40000),
        },
      ),
    ).state;

    expect(state.quotesBySymbol[_samsung.symbol]?.current, 70000);
    expect(state.quotesBySymbol[_kakao.symbol]?.current, 41000);
    expect(state.quoteLoadingSymbols, isEmpty);
  });

  test(
    'metadata failure retains fallback stock and exposes a partial error',
    () {
      const fallback = Stock(symbol: '005930', name: '삼성', market: '국내');
      final registered = appReducer(
        const AppState(),
        const FavoriteToggled(fallback, source: FavoriteChangeSource.search),
      );

      final failed = appReducer(
        registered.state,
        const MetadataFailed(symbol: '005930', message: '종목 정보를 불러오지 못했습니다.'),
      ).state;

      expect(failed.stockById(fallback.id), fallback);
      expect(failed.metadataErrorMessage, '종목 정보를 불러오지 못했습니다.');
    },
  );

  test(
    'metadata hydrates fallback stock after favorite registration',
    () async {
      final repository = FakeStockRepository();
      final store = _createStore(repository);
      const fallback = Stock(symbol: '005930', name: '삼성', market: '국내');

      store.dispatch(
        const FavoriteToggled(fallback, source: FavoriteChangeSource.search),
      );
      await _flush();

      expect(repository.metadataCalls, <String>['005930']);
      expect(store.state.stockById(_samsung.id), _samsung);
      expect(store.state.favoriteStocks, <Stock>[_samsung]);
    },
  );

  test(
    'watchlist sorting puts missing quotes last and keeps stable tie breakers',
    () {
      final state = AppState(
        stocksById: <String, Stock>{
          _samsung.id: _samsung,
          _kakao.id: _kakao,
          _naver.id: _naver,
        },
        favoriteIds: <String>{_samsung.id, _kakao.id, _naver.id},
        quotesBySymbol: <String, Quote>{
          _samsung.symbol: _quote(
            _samsung.symbol,
            current: 70000,
            previous: 69000,
          ),
          _kakao.symbol: _quote(_kakao.symbol, current: 40000, previous: 41000),
        },
      );

      expect(state.favoriteStocks.map((Stock stock) => stock.symbol), <String>[
        '005930',
        '035720',
        '035420',
      ]);

      final byRate = state.copyWith(watchlistSort: WatchlistSort.changeRate);
      expect(byRate.favoriteStocks.map((Stock stock) => stock.symbol), <String>[
        '005930',
        '035720',
        '035420',
      ]);

      final byName = state.copyWith(watchlistSort: WatchlistSort.name);
      expect(byName.favoriteStocks.map((Stock stock) => stock.name), <String>[
        'NAVER',
        '삼성전자',
        '카카오',
      ]);
    },
  );

  test('notice expiration is guarded by notice id', () {
    final repository = FakeStockRepository();
    final scheduler = FakeScheduler();
    final store = _createStore(repository, scheduler: scheduler);

    store.dispatch(
      const FavoriteToggled(_samsung, source: FavoriteChangeSource.search),
    );
    final firstNotice = store.state.notice;

    store.dispatch(
      const FavoriteToggled(_kakao, source: FavoriteChangeSource.search),
    );
    final secondNotice = store.state.notice;

    expect(firstNotice, isNotNull);
    expect(secondNotice, isNotNull);
    expect(secondNotice!.id, isNot(firstNotice!.id));

    scheduler.trigger(firstNotice.id);
    expect(store.state.notice?.id, secondNotice.id);

    scheduler.trigger(secondNotice.id);
    expect(store.state.notice, isNull);
  });

  test('detail ignores stale history updates after period changes', () async {
    final repository = FakeStockRepository();
    final store = _createStore(repository);

    store.dispatch(const DetailOpened(_samsung));
    final firstRequestId = store.state.detail.requestId;

    store.dispatch(const DetailPeriodSelected(ChartPeriod.month3));
    final secondRequestId = store.state.detail.requestId;

    repository.emitHistory(_samsung.symbol, ChartPeriod.month1, <DailyPrice>[
      _daily(DateTime(2026, 9, 9), close: 70000),
    ]);
    await _flush();
    expect(store.state.detail.requestId, secondRequestId);
    expect(store.state.detail.prices, isEmpty);

    repository.emitHistory(_samsung.symbol, ChartPeriod.month3, <DailyPrice>[
      _daily(DateTime(2026, 9, 9), close: 70000),
      _daily(DateTime(2026, 9, 8), close: 69000),
    ]);
    await _flush();

    expect(store.state.detail.requestId, isNot(firstRequestId));
    expect(store.state.detail.period, ChartPeriod.month3);
    expect(store.state.detail.prices, hasLength(2));
  });

  test(
    'detail daily prices reveal more rows on bottom pagination request',
    () async {
      final repository = FakeStockRepository();
      final store = _createStore(repository);
      final prices = List<DailyPrice>.generate(
        45,
        (index) => _daily(
          DateTime(2026, 9, 10).subtract(Duration(days: index)),
          close: 70000 - index,
        ),
      );

      store.dispatch(const DetailOpened(_samsung));
      repository.emitHistory(_samsung.symbol, ChartPeriod.month1, prices);
      await _flush();

      expect(store.state.detail.visibleDailyPrices, hasLength(20));
      expect(store.state.detail.hasMoreDailyPrices, isTrue);

      store.dispatch(const DetailDailyPricesMoreRequested());
      expect(store.state.detail.visibleDailyPrices, hasLength(40));
      expect(store.state.detail.hasMoreDailyPrices, isTrue);

      store.dispatch(const DetailDailyPricesMoreRequested());
      expect(store.state.detail.visibleDailyPrices, hasLength(45));
      expect(store.state.detail.hasMoreDailyPrices, isFalse);
    },
  );

  test(
    'detail daily pagination resets when the selected period changes',
    () async {
      final repository = FakeStockRepository();
      final store = _createStore(repository);
      final prices = List<DailyPrice>.generate(
        45,
        (index) => _daily(
          DateTime(2026, 9, 10).subtract(Duration(days: index)),
          close: 70000 - index,
        ),
      );

      store.dispatch(const DetailOpened(_samsung));
      repository.emitHistory(_samsung.symbol, ChartPeriod.month1, prices);
      await _flush();
      store.dispatch(const DetailDailyPricesMoreRequested());
      expect(store.state.detail.visibleDailyPrices, hasLength(40));

      store.dispatch(const DetailPeriodSelected(ChartPeriod.month3));
      repository.emitHistory(_samsung.symbol, ChartPeriod.month3, prices);
      await _flush();

      expect(store.state.detail.period, ChartPeriod.month3);
      expect(store.state.detail.visibleDailyPrices, hasLength(20));
    },
  );

  test('closing detail cancels active history loading immediately', () async {
    final repository = FakeStockRepository();
    final store = _createStore(repository);

    store.dispatch(const DetailOpened(_samsung));
    await _flush();
    expect(repository.historyCancellations.single.call(), isFalse);

    store.dispatch(const DetailClosed());
    expect(repository.historyCancellations.single.call(), isTrue);

    repository.emitHistory(_samsung.symbol, ChartPeriod.month1, <DailyPrice>[
      _daily(DateTime(2026, 9, 9), close: 70000),
    ]);
    await _flush();

    expect(store.state.detail.isOpen, isFalse);
    expect(store.state.detail.prices, isEmpty);
  });

  test(
    'bootstrap wires store and disposes repository through composition',
    () async {
      final repository = FakeStockRepository();
      final composition = bootstrapApp(
        stockRepository: repository,
        preferences: MemoryAppPreferences(),
      );

      expect(composition.store.state.selectedTab, AppTab.watchlist);
      composition.dispose();
      await _flush();
      expect(repository.isClosed, isTrue);
    },
  );
}

AppStore _createStore(
  FakeStockRepository repository, {
  FakeScheduler? scheduler,
  AppPreferences? preferences,
  Duration searchDebounceDuration = Duration.zero,
}) {
  return AppStore(
    effectRunner: AppEffectRunner(
      repository: repository,
      scheduler: scheduler ?? FakeScheduler(),
      noticeDuration: Duration.zero,
      preferences: preferences ?? MemoryAppPreferences(),
      searchDebounceDuration: searchDebounceDuration,
    ),
  );
}

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
}

Quote _quote(String symbol, {required int current, required int previous}) {
  return Quote(
    symbol: symbol,
    current: current,
    previousClose: previous,
    open: previous,
    high: current,
    low: previous,
    volume: 1000,
    listedShares: 100,
  );
}

DailyPrice _daily(DateTime date, {required int close}) {
  return DailyPrice(
    date: date,
    close: close,
    open: close - 100,
    high: close + 100,
    low: close - 200,
    volume: 1000,
    change: 100,
  );
}

const _samsung = Stock(symbol: '005930', name: '삼성전자', market: '코스피');
const _kakao = Stock(symbol: '035720', name: '카카오', market: '코스피');
const _naver = Stock(symbol: '035420', name: 'NAVER', market: '코스피');

final class FakeStockRepository implements StockRepository {
  final searchCompleters = <String, Completer<List<Stock>>>{};
  final metadataCalls = <String>[];
  final quoteCalls = <List<String>>[];
  final quoteCompleters = <Completer<Map<String, Quote>>>[];
  final historyControllers = <String, StreamController<List<DailyPrice>>>{};
  final historyCancellations = <bool Function()>[];
  bool holdQuotes = false;
  Object? quoteError;
  bool isClosed = false;

  @override
  Future<List<Stock>> search(String query) {
    return searchCompleters
        .putIfAbsent(query, () => Completer<List<Stock>>())
        .future;
  }

  void completeSearch(String query, List<Stock> stocks) {
    searchCompleters[query]?.complete(stocks);
  }

  @override
  Future<Stock> metadata(String symbol) async {
    metadataCalls.add(symbol);
    return switch (symbol) {
      '005930' => _samsung,
      '035720' => _kakao,
      _ => Stock(symbol: symbol, name: symbol, market: '코스피'),
    };
  }

  @override
  Future<Map<String, Quote>> quotes(List<String> symbols) async {
    quoteCalls.add(List<String>.unmodifiable(symbols));
    final error = quoteError;
    if (error != null) {
      throw error;
    }
    if (holdQuotes) {
      final completer = Completer<Map<String, Quote>>();
      quoteCompleters.add(completer);
      return completer.future;
    }
    return <String, Quote>{
      for (final symbol in symbols)
        symbol: _quote(symbol, current: 70000, previous: 69000),
    };
  }

  void completeQuoteCall(int index, Map<String, Quote> quotes) {
    quoteCompleters[index].complete(quotes);
  }

  @override
  Stream<List<DailyPrice>> history(
    String symbol,
    ChartPeriod period, {
    bool Function()? isCancelled,
  }) {
    if (isCancelled != null) {
      historyCancellations.add(isCancelled);
    }
    return historyControllers
        .putIfAbsent(
          _historyKey(symbol, period),
          StreamController<List<DailyPrice>>.new,
        )
        .stream
        .where((_) => isCancelled?.call() != true);
  }

  void emitHistory(String symbol, ChartPeriod period, List<DailyPrice> prices) {
    historyControllers[_historyKey(symbol, period)]?.add(prices);
  }

  @override
  Future<void> close() async {
    isClosed = true;
    for (final controller in historyControllers.values) {
      await controller.close();
    }
  }

  String _historyKey(String symbol, ChartPeriod period) {
    return '$symbol:${period.name}';
  }
}

final class FakeScheduler implements AppScheduler {
  final _tasks = <int, FakeCancelableTask>{};

  @override
  CancelableTask schedule(Duration delay, void Function() callback) {
    final id = _tasks.length + 1;
    final task = FakeCancelableTask(callback);
    _tasks[id] = task;
    return task;
  }

  void trigger(int id) {
    _tasks[id]?.trigger();
  }

  void triggerLast() {
    _tasks[_tasks.keys.last]?.trigger();
  }

  @override
  void dispose() {
    for (final task in _tasks.values) {
      task.cancel();
    }
  }
}

final class FakeCancelableTask implements CancelableTask {
  FakeCancelableTask(this._callback);

  final void Function() _callback;
  bool _isCanceled = false;

  @override
  void cancel() {
    _isCanceled = true;
  }

  void trigger() {
    if (!_isCanceled) {
      _callback();
    }
  }
}
