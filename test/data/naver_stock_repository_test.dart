import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:edencrew_assignment_starter/domain/stock/repository/naver_stock_repository.dart';
import 'package:edencrew_assignment_starter/core/network/stock_http_client.dart';
import 'package:edencrew_assignment_starter/domain/stock/interface/stock_repository.dart';
import 'package:edencrew_assignment_starter/service/naver/model/naver_stock_dto.dart';
import 'package:edencrew_assignment_starter/domain/stock/entity/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NaverStockParsers', () {
    test('filters domestic six digit search results', () {
      final stocks = NaverStockParsers.parseSearch(
        jsonEncode({
          'items': [
            {
              'code': '005930',
              'name': '삼성전자',
              'category': 'stock',
              'typeName': 'KOSPI',
              'typeCode': 'KOSPI',
              'nationCode': 'KOR',
              'url': '/domestic/stock/005930/total',
            },
            {
              'code': 'AAPL',
              'name': 'Apple',
              'category': 'stock',
              'typeName': 'NASDAQ',
              'typeCode': 'NASDAQ',
              'nationCode': 'USA',
              'url': '/worldstock/stock/AAPL.O/total',
            },
            {
              'code': '123',
              'name': '짧은 코드',
              'category': 'stock',
              'typeName': 'KOSPI',
              'typeCode': 'KOSPI',
              'nationCode': 'KOR',
              'url': '/domestic/stock/123/total',
            },
            {
              'code': '000001',
              'name': '상해종합',
              'category': 'index',
              'typeName': 'SHANGHAI',
              'typeCode': 'SHANGHAI',
              'nationCode': 'CHN',
              'url': '/worldstock/index/000001',
            },
          ],
        }),
      );

      expect(stocks, hasLength(1));
      expect(stocks.single.id, 'domestic:005930');
      expect(stocks.single.name, '삼성전자');
      expect(stocks.single.market, '코스피');
    });

    test('DTOs convert valid payloads to entities', () {
      final searchDto = NaverSearchStockDto.fromJson({
        'code': '000660',
        'name': 'SK하이닉스',
        'category': 'stock',
        'typeName': '코스피',
        'typeCode': 'KOSPI',
        'nationCode': 'KOR',
        'url': '/domestic/stock/000660/total',
      });
      final quoteDto = NaverQuoteDto.fromJson({
        'cd': '000660',
        'nv': '270,000',
        'pcv': '269,000',
        'ov': '268,000',
        'hv': '271,000',
        'lv': '267,000',
        'aq': '123',
      });
      final metadataDto = NaverMetadataDto.fromJson({
        'symbolCode': '000660',
        'stockName': 'SK하이닉스',
        'stockExchangeNameKor': '코스피',
      }, fallbackSymbol: '000660');

      expect(
        searchDto.toEntity(),
        const Stock(symbol: '000660', name: 'SK하이닉스', market: '코스피'),
      );
      expect(quoteDto.toEntity().marketCap, isNull);
      expect(metadataDto.toEntity().market, '코스피');
    });

    test('parses realtime quotes by symbol', () {
      final quotes = NaverStockParsers.parseQuotes(
        jsonEncode({
          'result': {
            'areas': [
              {
                'name': 'SERVICE_ITEM',
                'datas': [
                  {
                    'cd': '005930',
                    'nv': 81000,
                    'pcv': 80000,
                    'ov': 80500,
                    'hv': 82000,
                    'lv': 79900,
                    'aq': 12345678,
                    'countOfListedStock': 5969782550,
                  },
                ],
              },
            ],
          },
        }),
      );

      final quote = quotes['005930'];
      expect(quote, isNotNull);
      expect(quote!.change, 1000);
      expect(quote.changeRate, closeTo(0.0125, 0.0001));
      expect(quote.marketCap, 81000 * 5969782550);
    });

    test('parses daily price html from ASCII structure only', () {
      final page = NaverStockParsers.parseHistoryPage(
        utf8.encode(_historyHtml(lastPage: 12)),
        symbol: '005930',
        page: 1,
      );

      expect(page.lastPage, 12);
      expect(page.prices, hasLength(2));
      expect(page.prices.first.localDate, '20260910');
      expect(page.prices.first.close, 81000);
      expect(page.prices.first.change, -1000);
      expect(page.prices.first.volume, 12345678);
    });

    test('rejects malformed and error daily html', () {
      expect(
        () => NaverStockParsers.parseHistoryPage(
          utf8.encode('<html><!-- ERROR --><div class="error_content"></div>'),
          symbol: '005930',
          page: 1,
        ),
        throwsA(isA<StockParseException>()),
      );
      expect(
        () => NaverStockParsers.parseHistoryPage(
          utf8.encode('<html><body>not a table</body></html>'),
          symbol: '005930',
          page: 1,
        ),
        throwsA(isA<StockParseException>()),
      );
    });

    test('allows valid empty daily price table', () {
      final page = NaverStockParsers.parseHistoryPage(
        utf8.encode(_emptyHistoryHtml()),
        symbol: '005930',
        page: 1,
      );

      expect(page.lastPage, 1);
      expect(page.prices, isEmpty);
    });

    test('parses checked-in Naver response samples', () {
      final search = NaverStockParsers.parseSearch(
        File('assets/mock/naver_search_samsung.json').readAsStringSync(),
      );
      final metadata = NaverStockParsers.parseMetadata(
        File('assets/mock/naver_metadata_005930.json').readAsStringSync(),
        fallbackSymbol: '005930',
      );
      final quotes = NaverStockParsers.parseQuotes(
        utf8.decode(
          File(
            'assets/mock/naver_realtime_005930_000660.json',
          ).readAsBytesSync(),
          allowMalformed: true,
        ),
      );
      final history = NaverStockParsers.parseHistoryPage(
        File('assets/mock/naver_sise_day_005930_page1.html').readAsBytesSync(),
        symbol: '005930',
        page: 1,
      );

      expect(search.map((stock) => stock.symbol), contains('005930'));
      expect(metadata.name, '삼성전자');
      expect(quotes.keys, containsAll(<String>['005930', '000660']));
      expect(history.prices, isNotEmpty);
      expect(history.lastPage, 756);
    });

    test('throws when required quote numeric fields are missing', () {
      expect(
        () => NaverStockParsers.parseQuotes(
          jsonEncode({
            'datas': [
              {
                'cd': '005930',
                'nv': 10,
                'pcv': 9,
                'ov': 10,
                'hv': 11,
                'aq': 100,
              },
            ],
          }),
        ),
        throwsA(isA<StockParseException>()),
      );
    });
  });

  group('NaverStockRepository', () {
    test('builds batch quote request', () async {
      final client = _FakeHttpClient({
        'polling.finance.naver.com/api/realtime': jsonEncode({
          'result': {
            'areas': [
              {
                'datas': [
                  {
                    'cd': '005930',
                    'nv': 10,
                    'pcv': 9,
                    'ov': 10,
                    'hv': 11,
                    'lv': 8,
                    'aq': 100,
                  },
                  {
                    'cd': '000660',
                    'nv': 20,
                    'pcv': 21,
                    'ov': 21,
                    'hv': 22,
                    'lv': 19,
                    'aq': 200,
                  },
                ],
              },
            ],
          },
        }),
      });
      final repository = NaverStockRepository(httpClient: client);

      final quotes = await repository.quotes(['005930', '000660', '005930']);

      expect(quotes.keys, containsAll(<String>['005930', '000660']));
      expect(client.requestedUris, hasLength(1));
      expect(
        client.requestedUris.single.queryParameters['query'],
        'SERVICE_ITEM:005930,000660',
      );
    });

    test('streams cached daily history pages incrementally', () async {
      final client = _FakeHttpClient({
        'finance.naver.com/item/sise_day.naver?page=1&code=005930':
            _historyHtml(lastPage: 2),
        'finance.naver.com/item/sise_day.naver?page=2&code=005930':
            _historyHtml(
              lastPage: 2,
              firstDate: '2026.09.08',
              firstClose: '79,500',
              secondDate: '2026.09.07',
              secondClose: '79,000',
            ),
      });
      final repository = NaverStockRepository(httpClient: client);

      final firstLoad = await repository
          .history('005930', ChartPeriod.month1)
          .toList();
      final secondLoad = await repository
          .history('005930', ChartPeriod.month1)
          .toList();

      expect(firstLoad, hasLength(2));
      expect(firstLoad.first, hasLength(2));
      expect(firstLoad.last, hasLength(4));
      expect(firstLoad.first.first.change, -1000);
      expect(secondLoad.last, hasLength(4));
      expect(client.requestedUris, hasLength(2));
    });

    test('stops history when next page adds no new trading day', () async {
      final client = _FakeHttpClient({
        'finance.naver.com/item/sise_day.naver?page=1&code=005930':
            _historyHtml(lastPage: 5),
        'finance.naver.com/item/sise_day.naver?page=2&code=005930':
            _historyHtml(lastPage: 5),
      });
      final repository = NaverStockRepository(httpClient: client);

      final loads = await repository
          .history('005930', ChartPeriod.month1)
          .toList();

      expect(loads, hasLength(2));
      expect(loads.last, hasLength(2));
      expect(client.requestedUris, hasLength(2));
    });

    test('invalidates history cache on KST day rollover', () async {
      var now = DateTime.utc(2026, 9, 9, 14, 59);
      final client = _FakeHttpClient({
        'finance.naver.com/item/sise_day.naver?page=1&code=005930':
            _historyHtml(lastPage: 1),
      });
      final repository = NaverStockRepository(
        httpClient: client,
        now: () => now,
      );

      await repository.history('005930', ChartPeriod.month1).toList();
      await repository.history('005930', ChartPeriod.month1).toList();
      now = DateTime.utc(2026, 9, 9, 15);
      await repository.history('005930', ChartPeriod.month1).toList();

      expect(client.requestedUris, hasLength(2));
    });

    test('dedupes concurrent history page requests in flight', () async {
      final client = _DelayedHttpClient(
        _historyHtml(lastPage: 1),
        delay: const Duration(milliseconds: 10),
      );
      final repository = NaverStockRepository(httpClient: client);

      final loads = await Future.wait([
        repository.history('005930', ChartPeriod.month1).toList(),
        repository.history('005930', ChartPeriod.month1).toList(),
      ]);

      expect(loads.first.single, hasLength(2));
      expect(loads.last.single, hasLength(2));
      expect(client.requestedUris, hasLength(1));
    });

    test('does not emit history when cancelled after delayed fetch', () async {
      var cancelled = false;
      final client = _DelayedHttpClient(
        _historyHtml(lastPage: 1),
        delay: const Duration(milliseconds: 10),
        onBeforeReturn: () {
          cancelled = true;
        },
      );
      final repository = NaverStockRepository(httpClient: client);

      final loads = await repository
          .history('005930', ChartPeriod.month1, isCancelled: () => cancelled)
          .toList();

      expect(loads, isEmpty);
      expect(client.requestedUris, hasLength(1));
    });

    test('old rollover generation cannot poison fresh history cache', () async {
      var now = DateTime.utc(2026, 9, 9, 14, 59);
      final firstResponse = Completer<String>();
      final secondResponse = Completer<String>();
      final client = _QueuedHttpClient({
        'finance.naver.com/item/sise_day.naver?page=1&code=005930': [
          firstResponse,
          secondResponse,
        ],
      });
      final repository = NaverStockRepository(
        httpClient: client,
        now: () => now,
      );

      final staleLoad = repository
          .history('005930', ChartPeriod.month1)
          .toList();
      await _waitForRequests(client.requestedUris, 1);
      now = DateTime.utc(2026, 9, 9, 15);
      final freshLoad = repository
          .history('005930', ChartPeriod.month1)
          .toList();
      await _waitForRequests(client.requestedUris, 2);

      secondResponse.complete(_historyHtml(lastPage: 1, firstClose: '90,000'));
      expect((await freshLoad).single.first.close, 90000);

      firstResponse.complete(_historyHtml(lastPage: 1, firstClose: '70,000'));
      expect((await staleLoad).single.first.close, 70000);

      final cachedFreshLoad = await repository
          .history('005930', ChartPeriod.month1)
          .toList();
      expect(cachedFreshLoad.single.first.close, 90000);
      expect(client.requestedUris, hasLength(2));
    });
  });
}

String _emptyHistoryHtml() {
  return '''
<html>
  <body>
    <table class="type2">
      <tr>
        <th>날짜</th>
        <th>종가</th>
        <th>전일비</th>
        <th>시가</th>
        <th>고가</th>
        <th>저가</th>
        <th>거래량</th>
      </tr>
    </table>
  </body>
</html>
''';
}

String _historyHtml({
  required int lastPage,
  String firstDate = '2026.09.10',
  String firstClose = '81,000',
  String secondDate = '2026.09.09',
  String secondClose = '80,000',
}) {
  return '''
<html>
  <body>
    <table>
      <tr>
        <td class="date">$firstDate</td>
        <td class="num">$firstClose</td>
        <td class="num"><em class="bu_p bu_pdn"></em><span class="nv01">1,000</span></td>
        <td class="num">80,500</td>
        <td class="num">82,000</td>
        <td class="num">79,900</td>
        <td class="num">12,345,678</td>
      </tr>
      <tr>
        <td class="date">$secondDate</td>
        <td class="num">$secondClose</td>
        <td class="num">500</td>
        <td class="num">79,800</td>
        <td class="num">80,500</td>
        <td class="num">79,300</td>
        <td class="num">9,876,543</td>
      </tr>
    </table>
    <table>
      <td class="pgRR"><a href="/item/sise_day.naver?code=005930&page=$lastPage">맨뒤</a></td>
    </table>
  </body>
</html>
''';
}

class _FakeHttpClient implements StockHttpClient {
  _FakeHttpClient(this.responses);

  final Map<String, String> responses;
  final List<Uri> requestedUris = <Uri>[];

  @override
  Future<List<int>> get(Uri uri) async {
    requestedUris.add(uri);
    final key = _key(uri);
    final response = responses[key];
    if (response == null) {
      throw StateError('Missing fake response for $key');
    }
    return utf8.encode(response);
  }

  @override
  Future<void> close() async {}

  static String _key(Uri uri) {
    final path = '${uri.host}${uri.path}';
    if (uri.host == 'finance.naver.com') {
      return '$path?page=${uri.queryParameters['page']}&code=${uri.queryParameters['code']}';
    }
    return path;
  }
}

class _DelayedHttpClient implements StockHttpClient {
  _DelayedHttpClient(this.response, {required this.delay, this.onBeforeReturn});

  final String response;
  final Duration delay;
  final void Function()? onBeforeReturn;
  final List<Uri> requestedUris = <Uri>[];

  @override
  Future<List<int>> get(Uri uri) async {
    requestedUris.add(uri);
    await Future<void>.delayed(delay);
    onBeforeReturn?.call();
    return utf8.encode(response);
  }

  @override
  Future<void> close() async {}
}

class _QueuedHttpClient implements StockHttpClient {
  _QueuedHttpClient(this.responses);

  final Map<String, List<Completer<String>>> responses;
  final List<Uri> requestedUris = <Uri>[];

  @override
  Future<List<int>> get(Uri uri) async {
    requestedUris.add(uri);
    final queue = responses[_FakeHttpClient._key(uri)];
    if (queue == null || queue.isEmpty) {
      throw StateError(
        'Missing queued response for ${_FakeHttpClient._key(uri)}',
      );
    }
    final response = await queue.removeAt(0).future;
    return utf8.encode(response);
  }

  @override
  Future<void> close() async {}
}

Future<void> _waitForRequests(List<Uri> requests, int count) async {
  for (var attempt = 0; attempt < 50; attempt += 1) {
    if (requests.length >= count) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  throw StateError('Timed out waiting for $count requests');
}
