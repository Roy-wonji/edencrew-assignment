import 'dart:async';
import 'dart:convert';
import '../entity/models.dart';
import '../interface/stock_repository.dart';
import '../../../core/network/stock_http_client.dart';
import '../../../service/naver/endpoint/naver_endpoints.dart';
import '../../../service/naver/model/naver_stock_dto.dart';

class NaverStockRepository implements StockRepository {
  NaverStockRepository({
    required StockHttpClient httpClient,
    DateTime Function()? now,
  }) : _httpClient = httpClient,
       _now = now ?? DateTime.now,
       _cacheDay = _kstDay(now?.call() ?? DateTime.now());

  final StockHttpClient _httpClient;
  final DateTime Function() _now;
  final Map<String, Stock> _metadataCache = <String, Stock>{};
  final Map<String, Map<int, HistoryPage>> _historyCache =
      <String, Map<int, HistoryPage>>{};
  final Map<String, Future<HistoryPage>> _historyInflight =
      <String, Future<HistoryPage>>{};
  final Map<String, int> _lastPageBySymbol = <String, int>{};
  DateTime _cacheDay;
  int _cacheGeneration = 0;

  static final RegExp _domesticSymbolPattern = RegExp(r'^\d{6}$');

  @override
  Future<List<Stock>> search(String query) async {
    _ensureFreshCacheDay();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const <Stock>[];
    }

    final uri = NaverEndpoints.search(trimmed);
    final payload = _decodeUtf8(await _httpClient.get(uri));
    return NaverStockParsers.parseSearch(payload);
  }

  @override
  Future<Stock> metadata(String symbol) async {
    _ensureFreshCacheDay();
    _validateSymbol(symbol);
    final cached = _metadataCache[symbol];
    if (cached != null) {
      return cached;
    }

    final uri = NaverEndpoints.metadata(symbol);
    final payload = _decodeUtf8(await _httpClient.get(uri));
    final stock = NaverStockParsers.parseMetadata(
      payload,
      fallbackSymbol: symbol,
    );
    _metadataCache[symbol] = stock;
    return stock;
  }

  @override
  Future<Map<String, Quote>> quotes(List<String> symbols) async {
    _ensureFreshCacheDay();
    final uniqueSymbols = symbols.toSet().toList(growable: false);
    if (uniqueSymbols.isEmpty) {
      return const <String, Quote>{};
    }
    for (final symbol in uniqueSymbols) {
      _validateSymbol(symbol);
    }

    final uri = NaverEndpoints.quotes(uniqueSymbols);
    final payload = _decodeUtf8(await _httpClient.get(uri));
    return NaverStockParsers.parseQuotes(payload);
  }

  @override
  Stream<List<DailyPrice>> history(
    String symbol,
    ChartPeriod period, {
    bool Function()? isCancelled,
  }) async* {
    _ensureFreshCacheDay();
    _validateSymbol(symbol);

    final prices = <DailyPrice>[];
    for (var page = 1; page <= period.requiredPages; page += 1) {
      _ensureFreshCacheDay();
      if (isCancelled?.call() ?? false) {
        return;
      }

      final knownLastPage = _lastPageBySymbol[symbol];
      if (knownLastPage != null && page > knownLastPage) {
        return;
      }

      final beforeCount = prices.length;
      final historyPage = await _fetchHistoryPage(symbol, page);
      if (isCancelled?.call() ?? false) {
        return;
      }

      final merged = _mergeHistory(prices, historyPage.prices);
      prices
        ..clear()
        ..addAll(merged);
      _lastPageBySymbol[symbol] = historyPage.lastPage;

      final limited = prices.take(period.days).toList();
      yield List<DailyPrice>.unmodifiable(limited);

      if (page >= historyPage.lastPage ||
          limited.length >= period.days ||
          prices.length == beforeCount) {
        return;
      }
    }
  }

  @override
  Future<void> close() => _httpClient.close();

  Future<HistoryPage> _fetchHistoryPage(String symbol, int page) {
    _ensureFreshCacheDay();
    final cached = _historyCache[symbol]?[page];
    if (cached != null) {
      return Future<HistoryPage>.value(cached);
    }

    final generation = _cacheGeneration;
    final key = '$generation:$symbol:$page';
    final inFlight = _historyInflight[key];
    if (inFlight != null) {
      return inFlight;
    }

    final future = () async {
      final uri = NaverEndpoints.history(symbol, page);
      final bytes = await _httpClient.get(uri);
      final historyPage = NaverStockParsers.parseHistoryPage(
        bytes,
        symbol: symbol,
        page: page,
      );
      if (generation == _cacheGeneration) {
        _historyCache.putIfAbsent(symbol, () => <int, HistoryPage>{})[page] =
            historyPage;
      }
      return historyPage;
    }();

    _historyInflight[key] = future;
    return future.whenComplete(() {
      if (identical(_historyInflight[key], future)) {
        _historyInflight.remove(key);
      }
    });
  }

  void _ensureFreshCacheDay() {
    final today = _kstDay(_now());
    if (today == _cacheDay) {
      return;
    }

    _cacheDay = today;
    _cacheGeneration += 1;
    _metadataCache.clear();
    _historyCache.clear();
    _historyInflight.clear();
    _lastPageBySymbol.clear();
  }

  static List<DailyPrice> _mergeHistory(
    List<DailyPrice> current,
    List<DailyPrice> next,
  ) {
    final byDate = <String, DailyPrice>{
      for (final price in current) price.localDate: price,
    };
    for (final price in next) {
      byDate.putIfAbsent(price.localDate, () => price);
    }

    final merged = byDate.values.toList()
      ..sort((left, right) => right.localDate.compareTo(left.localDate));
    return merged;
  }

  static DateTime _kstDay(DateTime value) {
    final kst = value.toUtc().add(const Duration(hours: 9));
    return DateTime(kst.year, kst.month, kst.day);
  }

  static String _decodeUtf8(List<int> bytes) {
    return utf8.decode(bytes, allowMalformed: true);
  }

  static void _validateSymbol(String symbol) {
    if (!_domesticSymbolPattern.hasMatch(symbol)) {
      throw ArgumentError.value(symbol, 'symbol', '6 digit domestic symbol');
    }
  }
}
