import 'dart:convert';
import '../../../domain/stock/entity/models.dart';
import '../../../domain/stock/interface/stock_repository.dart';

class NaverSearchStockDto {
  const NaverSearchStockDto({
    required this.code,
    required this.name,
    required this.typeCode,
    required this.typeName,
    required this.url,
    required this.nationCode,
    required this.category,
  });

  final String code;
  final String name;
  final String typeCode;
  final String typeName;
  final String url;
  final String nationCode;
  final String category;

  factory NaverSearchStockDto.fromJson(Map<String, Object?> json) {
    return NaverSearchStockDto(
      code: _requiredString(json, 'code'),
      name: _requiredString(json, 'name'),
      typeCode: _optionalString(json, 'typeCode'),
      typeName: _optionalString(json, 'typeName'),
      url: _optionalString(json, 'url'),
      nationCode: _optionalString(json, 'nationCode'),
      category: _optionalString(json, 'category'),
    );
  }

  bool get isDomesticStock {
    final normalizedCategory = category.toLowerCase();
    final normalizedNation = nationCode.toUpperCase();
    final normalizedType = typeCode.toUpperCase();
    final normalizedUrl = url.toLowerCase();

    return RegExp(r'^\d{6}$').hasMatch(code) &&
        normalizedCategory == 'stock' &&
        (normalizedNation == 'KOR' || normalizedNation == 'KR') &&
        _isDomesticMarket(normalizedType, typeName) &&
        normalizedUrl.contains('/domestic/stock/');
  }

  Stock toEntity() {
    return Stock(symbol: code, name: name, market: _marketName(typeName));
  }
}

class NaverMetadataDto {
  const NaverMetadataDto({
    required this.symbolCode,
    required this.stockName,
    required this.stockExchangeNameKor,
  });

  final String symbolCode;
  final String stockName;
  final String stockExchangeNameKor;

  factory NaverMetadataDto.fromJson(
    Map<String, Object?> json, {
    required String fallbackSymbol,
  }) {
    return NaverMetadataDto(
      symbolCode: _optionalString(json, 'symbolCode').isEmpty
          ? fallbackSymbol
          : _optionalString(json, 'symbolCode'),
      stockName: _optionalString(json, 'stockName').isEmpty
          ? fallbackSymbol
          : _optionalString(json, 'stockName'),
      stockExchangeNameKor: _optionalString(json, 'stockExchangeNameKor'),
    );
  }

  Stock toEntity() {
    return Stock(
      symbol: symbolCode,
      name: stockName,
      market: _marketName(stockExchangeNameKor),
    );
  }
}

class NaverQuoteDto {
  const NaverQuoteDto({
    required this.symbol,
    required this.current,
    required this.previousClose,
    required this.open,
    required this.high,
    required this.low,
    required this.volume,
    required this.listedShares,
  });

  final String symbol;
  final int current;
  final int previousClose;
  final int open;
  final int high;
  final int low;
  final int volume;
  final int? listedShares;

  factory NaverQuoteDto.fromJson(Map<String, Object?> json) {
    return NaverQuoteDto(
      symbol: _requiredString(json, 'cd'),
      current: NaverStockParsers._requiredNumber(json, 'nv', 'closePrice'),
      previousClose: NaverStockParsers._requiredNumber(
        json,
        'pcv',
        'previousClosePrice',
      ),
      open: NaverStockParsers._requiredNumber(json, 'ov', 'openPrice'),
      high: NaverStockParsers._requiredNumber(json, 'hv', 'highPrice'),
      low: NaverStockParsers._requiredNumber(json, 'lv', 'lowPrice'),
      volume: NaverStockParsers._requiredNumber(
        json,
        'aq',
        'accumulatedTradingVolume',
      ),
      listedShares: NaverStockParsers._optionalNumber(
        json['countOfListedStock'],
      ),
    );
  }

  Quote toEntity() {
    return Quote(
      symbol: symbol,
      current: current,
      previousClose: previousClose,
      open: open,
      high: high,
      low: low,
      volume: volume,
      listedShares: listedShares,
    );
  }
}

class NaverDailyPriceDto {
  const NaverDailyPriceDto({
    required this.date,
    required this.close,
    required this.change,
    required this.open,
    required this.high,
    required this.low,
    required this.volume,
  });

  final DateTime date;
  final int close;
  final int change;
  final int open;
  final int high;
  final int low;
  final int volume;

  factory NaverDailyPriceDto.fromHtmlRow(String rowHtml) {
    final cells = RegExp(
      r'<td[^>]*>(.*?)</td>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(rowHtml).map((cell) => cell.group(1) ?? '').toList();

    final values = cells
        .map(NaverStockParsers._stripTags)
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    if (values.length < 7 || !NaverStockParsers._isDate(values.first)) {
      throw const StockParseException('Not a daily price row');
    }

    return NaverDailyPriceDto(
      date: NaverStockParsers._date(values[0]),
      close: NaverStockParsers._number(values[1]),
      change: _signedChange(cells[2], values[2]),
      open: NaverStockParsers._number(values[3]),
      high: NaverStockParsers._number(values[4]),
      low: NaverStockParsers._number(values[5]),
      volume: NaverStockParsers._number(values[6]),
    );
  }

  DailyPrice toEntity() {
    return DailyPrice(
      date: date,
      close: close,
      open: open,
      high: high,
      low: low,
      volume: volume,
      change: change,
    );
  }
}

class NaverStockParsers {
  NaverStockParsers._();

  static List<Stock> parseSearch(String payload) {
    final decoded = _jsonDecodeLoose(payload);
    final seen = <String>{};
    return _collectMaps(decoded)
        .where((item) => item.containsKey('code') && item.containsKey('name'))
        .map(NaverSearchStockDto.fromJson)
        .where((dto) => dto.isDomesticStock)
        .map((dto) => dto.toEntity())
        .where((stock) => seen.add(stock.symbol))
        .toList(growable: false);
  }

  static Stock parseMetadata(String payload, {required String fallbackSymbol}) {
    final decoded = _jsonDecodeLoose(payload);
    final map = _collectMaps(decoded).firstWhere(
      (item) =>
          item.containsKey('symbolCode') ||
          item.containsKey('stockName') ||
          item.containsKey('stockExchangeNameKor'),
      orElse: () => throw const StockParseException('Metadata DTO missing'),
    );
    return NaverMetadataDto.fromJson(
      map,
      fallbackSymbol: fallbackSymbol,
    ).toEntity();
  }

  static Map<String, Quote> parseQuotes(String payload) {
    final decoded = _jsonDecodeLoose(payload);
    final datas = _collectMaps(decoded).where((item) {
      return item.containsKey('cd') &&
          (item.containsKey('nv') || item.containsKey('closePrice'));
    });

    return <String, Quote>{
      for (final dto in datas.map(NaverQuoteDto.fromJson))
        dto.symbol: dto.toEntity(),
    };
  }

  static HistoryPage parseHistoryPage(
    List<int> bytes, {
    required String symbol,
    required int page,
  }) {
    final html = _decodeAsciiStructure(bytes);
    if (_isErrorHtml(html)) {
      throw const StockParseException('Naver daily price returned error HTML');
    }
    if (!html.toLowerCase().contains('<table')) {
      throw const StockParseException('Malformed daily price HTML');
    }

    final rows = RegExp(
      r'<tr[^>]*>(.*?)</tr>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(html);

    final prices = <DailyPrice>[];
    for (final row in rows) {
      try {
        prices.add(
          NaverDailyPriceDto.fromHtmlRow(row.group(1) ?? '').toEntity(),
        );
      } on StockParseException {
        continue;
      }
    }

    return HistoryPage(
      symbol: symbol,
      page: page,
      lastPage: _lastPage(html),
      prices: List<DailyPrice>.unmodifiable(prices),
    );
  }

  static Object? _jsonDecodeLoose(String payload) {
    final trimmed = payload.trim();
    final looksLikeJsonp =
        trimmed.startsWith(RegExp(r'[A-Za-z_$]')) &&
        trimmed.contains('(') &&
        trimmed.endsWith(')');
    final jsonText = looksLikeJsonp
        ? trimmed.substring(trimmed.indexOf('(') + 1, trimmed.lastIndexOf(')'))
        : trimmed;
    return jsonDecode(jsonText);
  }

  static List<Map<String, Object?>> _collectMaps(Object? value) {
    final maps = <Map<String, Object?>>[];
    void visit(Object? node) {
      if (node is Map) {
        final normalized = <String, Object?>{
          for (final entry in node.entries) entry.key.toString(): entry.value,
        };
        maps.add(normalized);
        for (final child in normalized.values) {
          visit(child);
        }
      } else if (node is Iterable) {
        for (final child in node) {
          visit(child);
        }
      }
    }

    visit(value);
    return maps;
  }

  static int _number(Object? raw) {
    if (raw == null) {
      throw const StockParseException('Missing numeric value');
    }
    if (raw is num) {
      return raw.round();
    }

    final text = raw.toString().replaceAll(RegExp(r'[^0-9.-]'), '');
    if (text.isEmpty || text == '-' || text == '.') {
      throw StockParseException('Invalid numeric value: $raw');
    }
    return double.parse(text).round();
  }

  static int _requiredNumber(
    Map<String, Object?> item,
    String primaryKey,
    String fallbackKey,
  ) {
    final value = item[primaryKey] ?? item[fallbackKey];
    if (value == null) {
      throw StockParseException('Missing required quote field: $primaryKey');
    }
    return _number(value);
  }

  static int? _optionalNumber(Object? value) {
    if (value == null) {
      return null;
    }
    return _number(value);
  }

  static String _decodeAsciiStructure(List<int> bytes) {
    return String.fromCharCodes(bytes.map((byte) => byte < 128 ? byte : 32));
  }

  static String _stripTags(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _isDate(String value) {
    return RegExp(r'^\d{4}\.\d{2}\.\d{2}$').hasMatch(value);
  }

  static DateTime _date(String value) {
    final parts = value.split('.');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  static int _lastPage(String html) {
    final pages = RegExp(r'(?:[?&]|&amp;)page=(\d+)', caseSensitive: false)
        .allMatches(html)
        .map((match) => int.parse(match.group(1)!))
        .toList(growable: false);
    if (pages.isEmpty) {
      return 1;
    }
    return pages.reduce((left, right) => left > right ? left : right);
  }
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key]?.toString().trim();
  if (value == null || value.isEmpty) {
    throw StockParseException('Missing required string: $key');
  }
  return value;
}

String _optionalString(Map<String, Object?> json, String key) {
  return json[key]?.toString().trim() ?? '';
}

String _marketName(Object? raw) {
  final value = raw?.toString().trim() ?? '';
  final lower = value.toLowerCase();
  if (lower.contains('kospi') || value.contains('코스피')) {
    return '코스피';
  }
  if (lower.contains('kosdaq') || value.contains('코스닥')) {
    return '코스닥';
  }
  if (lower.contains('konex') || value.contains('코넥스')) {
    return '코넥스';
  }
  return value.isEmpty ? '국내' : value;
}

bool _isDomesticMarket(String typeCode, String typeName) {
  final market = '$typeCode $typeName'.toLowerCase();
  return market.contains('kospi') ||
      market.contains('kosdaq') ||
      market.contains('konex') ||
      market.contains('코스피') ||
      market.contains('코스닥') ||
      market.contains('코넥스');
}

int _signedChange(String changeCellHtml, String text) {
  final value = NaverStockParsers._number(text).abs();
  final lower = changeCellHtml.toLowerCase();
  if (lower.contains('bu_pdn') ||
      lower.contains('nv01') ||
      lower.contains('down')) {
    return -value;
  }
  if (lower.contains('bu_pup') ||
      lower.contains('nv02') ||
      lower.contains('up')) {
    return value;
  }
  return value;
}

bool _isErrorHtml(String html) {
  final lower = html.toLowerCase();
  return lower.contains('<!-- error -->') ||
      lower.contains('error_content') ||
      lower.contains('not found');
}
