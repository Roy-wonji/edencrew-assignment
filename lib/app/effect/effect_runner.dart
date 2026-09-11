import 'package:edencrew_assignment_starter/app/effect/app_effect.dart';
import 'package:edencrew_assignment_starter/core/state/app_action.dart';
import 'package:edencrew_assignment_starter/core/time/scheduler.dart';
import 'package:edencrew_assignment_starter/domain/stock/entity/models.dart';
import 'package:edencrew_assignment_starter/domain/stock/interface/stock_repository.dart';
import 'package:edencrew_assignment_starter/feature/detail/action/detail_action.dart';
import 'package:edencrew_assignment_starter/feature/search/action/search_action.dart';
import 'package:edencrew_assignment_starter/feature/shared/action/shared_action.dart';

typedef AppDispatch = void Function(AppAction action);

final class AppEffectRunner {
  AppEffectRunner({
    required StockRepository repository,
    required AppScheduler scheduler,
    Duration noticeDuration = const Duration(seconds: 2),
    void Function(Object error)? debugErrorSink,
  }) : _repository = repository,
       _scheduler = scheduler,
       _noticeDuration = noticeDuration,
       _debugErrorSink = debugErrorSink;

  final StockRepository _repository;
  final AppScheduler _scheduler;
  final Duration _noticeDuration;
  final void Function(Object error)? _debugErrorSink;

  CancelableTask? _noticeTask;
  _DetailCancellation? _detailCancellation;
  bool _isDisposed = false;

  void run(AppEffect effect, AppDispatch dispatch) {
    if (_isDisposed) {
      return;
    }

    switch (effect) {
      case RefreshQuotesEffect(:final requestIdsBySymbol, :final symbols):
        _refreshQuotes(requestIdsBySymbol, symbols, dispatch);
      case LoadMetadataEffect(:final symbol):
        _loadMetadata(symbol, dispatch);
      case SearchStocksEffect(:final requestId, :final query):
        _search(requestId, query, dispatch);
      case LoadDetailHistoryEffect(
        :final requestId,
        :final stock,
        :final period,
      ):
        _loadDetailHistory(requestId, stock, period, dispatch);
      case DismissNoticeEffect(:final noticeId):
        _scheduleNoticeDismiss(noticeId, dispatch);
      case CancelDetailHistoryEffect():
        _cancelDetailHistory();
    }
  }

  Future<void> dispose() async {
    _isDisposed = true;
    _noticeTask?.cancel();
    _detailCancellation?.cancel();
    _scheduler.dispose();
    await _repository.close();
  }

  Future<void> _refreshQuotes(
    Map<String, int> requestIdsBySymbol,
    List<String> symbols,
    AppDispatch dispatch,
  ) async {
    final uniqueSymbols = symbols.toSet().toList(growable: false);
    if (uniqueSymbols.isEmpty) {
      return;
    }

    try {
      final quotes = await _repository.quotes(uniqueSymbols);
      _dispatchIfAlive(
        dispatch,
        QuotesSucceeded(
          requestIdsBySymbol: requestIdsBySymbol,
          symbols: uniqueSymbols,
          quotes: quotes,
        ),
      );
    } on Object catch (error) {
      _debugLog(error);
      _dispatchIfAlive(
        dispatch,
        QuotesFailed(
          requestIdsBySymbol: requestIdsBySymbol,
          symbols: uniqueSymbols,
          message: '시세를 불러오지 못했습니다. 다시 시도해 주세요.',
        ),
      );
    }
  }

  Future<void> _loadMetadata(String symbol, AppDispatch dispatch) async {
    try {
      final stock = await _repository.metadata(symbol);
      _dispatchIfAlive(dispatch, MetadataSucceeded(stock));
    } on Object catch (error) {
      _debugLog(error);
      _dispatchIfAlive(
        dispatch,
        MetadataFailed(symbol: symbol, message: '종목 정보를 불러오지 못했습니다.'),
      );
    }
  }

  Future<void> _search(
    int requestId,
    String query,
    AppDispatch dispatch,
  ) async {
    try {
      final results = await _repository.search(query);
      _dispatchIfAlive(
        dispatch,
        SearchSucceeded(requestId: requestId, query: query, results: results),
      );
    } on Object catch (error) {
      _debugLog(error);
      _dispatchIfAlive(
        dispatch,
        SearchFailed(
          requestId: requestId,
          query: query,
          message: '검색 결과를 불러오지 못했습니다. 다시 시도해 주세요.',
        ),
      );
    }
  }

  Future<void> _loadDetailHistory(
    int requestId,
    Stock stock,
    ChartPeriod period,
    AppDispatch dispatch,
  ) async {
    _detailCancellation?.cancel();
    final cancellation = _DetailCancellation();
    _detailCancellation = cancellation;

    try {
      var latest = const <DailyPrice>[];
      await for (final prices in _repository.history(
        stock.symbol,
        period,
        isCancelled: cancellation.isCancelled,
      )) {
        if (cancellation.isCancelled()) {
          return;
        }
        latest = List<DailyPrice>.unmodifiable(prices);
        _dispatchIfAlive(
          dispatch,
          DetailHistoryUpdated(
            requestId: requestId,
            stockId: stock.id,
            period: period,
            prices: latest,
            isComplete: false,
          ),
        );
      }
      if (cancellation.isCancelled()) {
        return;
      }
      _dispatchIfAlive(
        dispatch,
        DetailHistoryUpdated(
          requestId: requestId,
          stockId: stock.id,
          period: period,
          prices: latest,
          isComplete: true,
        ),
      );
    } on Object catch (error) {
      _debugLog(error);
      if (cancellation.isCancelled()) {
        return;
      }
      _dispatchIfAlive(
        dispatch,
        DetailHistoryFailed(
          requestId: requestId,
          stockId: stock.id,
          period: period,
          message: '일별 시세를 불러오지 못했습니다. 다시 시도해 주세요.',
        ),
      );
    }
  }

  void _cancelDetailHistory() {
    _detailCancellation?.cancel();
    _detailCancellation = null;
  }

  void _scheduleNoticeDismiss(int noticeId, AppDispatch dispatch) {
    _noticeTask?.cancel();
    _noticeTask = _scheduler.schedule(
      _noticeDuration,
      () => _dispatchIfAlive(dispatch, NoticeExpired(noticeId)),
    );
  }

  void _dispatchIfAlive(AppDispatch dispatch, AppAction action) {
    if (!_isDisposed) {
      dispatch(action);
    }
  }

  void _debugLog(Object error) {
    _debugErrorSink?.call(error);
  }
}

final class _DetailCancellation {
  var _isCancelled = false;

  bool isCancelled() => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }
}
