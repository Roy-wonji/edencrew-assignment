import 'dart:convert';

import 'package:edencrew_assignment_starter/domain/stock/entity/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class AppPreferences {
  Future<AppPreferencesSnapshot> load();

  Future<void> save(AppPreferencesSnapshot snapshot);
}

final class AppPreferencesSnapshot {
  const AppPreferencesSnapshot({
    this.favoriteStocks = const <Stock>[],
    this.watchlistSort = WatchlistSort.currentPrice,
    this.recentSearches = const <String>[],
  });

  final List<Stock> favoriteStocks;
  final WatchlistSort watchlistSort;
  final List<String> recentSearches;
}

final class SharedPreferencesAppPreferences implements AppPreferences {
  const SharedPreferencesAppPreferences();

  static const _favoriteStocksKey = 'favoriteStocks.v1';
  static const _watchlistSortKey = 'watchlistSort.v1';
  static const _recentSearchesKey = 'recentSearches.v1';

  @override
  Future<AppPreferencesSnapshot> load() async {
    final preferences = await SharedPreferences.getInstance();
    return AppPreferencesSnapshot(
      favoriteStocks: _decodeStocks(
        preferences.getStringList(_favoriteStocksKey) ?? const <String>[],
      ),
      watchlistSort: _decodeSort(preferences.getString(_watchlistSortKey)),
      recentSearches:
          preferences.getStringList(_recentSearchesKey) ?? const <String>[],
    );
  }

  @override
  Future<void> save(AppPreferencesSnapshot snapshot) async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait(<Future<Object>>[
      preferences.setStringList(
        _favoriteStocksKey,
        snapshot.favoriteStocks.map(_encodeStock).toList(growable: false),
      ),
      preferences.setString(_watchlistSortKey, snapshot.watchlistSort.name),
      preferences.setStringList(_recentSearchesKey, snapshot.recentSearches),
    ]);
  }

  static List<Stock> _decodeStocks(List<String> values) {
    final stocks = <Stock>[];
    for (final value in values) {
      try {
        final json = jsonDecode(value) as Map<String, Object?>;
        final symbol = json['symbol'] as String?;
        final name = json['name'] as String?;
        final market = json['market'] as String?;
        if (symbol == null || name == null || market == null) {
          continue;
        }
        stocks.add(Stock(symbol: symbol, name: name, market: market));
      } on Object {
        continue;
      }
    }
    return List<Stock>.unmodifiable(stocks);
  }

  static String _encodeStock(Stock stock) => jsonEncode(<String, String>{
    'symbol': stock.symbol,
    'name': stock.name,
    'market': stock.market,
  });

  static WatchlistSort _decodeSort(String? value) {
    return WatchlistSort.values.firstWhere(
      (sort) => sort.name == value,
      orElse: () => WatchlistSort.currentPrice,
    );
  }
}

final class MemoryAppPreferences implements AppPreferences {
  MemoryAppPreferences([this.snapshot = const AppPreferencesSnapshot()]);

  AppPreferencesSnapshot snapshot;

  @override
  Future<AppPreferencesSnapshot> load() async => snapshot;

  @override
  Future<void> save(AppPreferencesSnapshot snapshot) async {
    this.snapshot = snapshot;
  }
}
