import 'dart:async';
import 'dart:io';

import 'package:edencrew_assignment_starter/core/network/stock_http_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DartIoStockHttpClient', () {
    test('sends configured headers and returns response body', () async {
      final server = await _TestServer.start((request) async {
        expect(request.headers.value('x-test-header'), 'edencrew');
        request.response.add([1, 2, 3]);
        await request.response.close();
      });
      final client = DartIoStockHttpClient(
        headers: const {'x-test-header': 'edencrew'},
      );
      addTearDown(client.close);
      addTearDown(server.close);

      final body = await client.get(server.uri('/success'));

      expect(body, [1, 2, 3]);
      expect(server.requestCount, 1);
    });

    test('throws HttpException for non-2xx responses', () async {
      final server = await _TestServer.start((request) async {
        request.response.statusCode = HttpStatus.serviceUnavailable;
        await request.response.close();
      });
      final client = DartIoStockHttpClient();
      addTearDown(client.close);
      addTearDown(server.close);

      await expectLater(
        client.get(server.uri('/unavailable')),
        throwsA(isA<HttpException>()),
      );
    });

    test(
      'throws HttpException and aborts when response exceeds byte limit',
      () async {
        final server = await _TestServer.start((request) async {
          request.response.add([1, 2]);
          await request.response.flush();
          request.response.add([3, 4]);
          await request.response.close();
        });
        final client = DartIoStockHttpClient(maxBytes: 3);
        addTearDown(client.close);
        addTearDown(server.close);

        await expectLater(
          client.get(server.uri('/oversize')),
          throwsA(isA<HttpException>()),
        );
      },
    );

    test('times out hanging response', () async {
      final responseStarted = Completer<void>();
      final server = await _TestServer.start((request) async {
        request.response.add([1]);
        await request.response.flush();
        responseStarted.complete();
      });
      final client = DartIoStockHttpClient(
        timeout: const Duration(milliseconds: 30),
      );
      addTearDown(client.close);
      addTearDown(server.close);

      final response = client.get(server.uri('/hang'));
      await responseStarted.future.timeout(const Duration(seconds: 1));
      await expectLater(response, throwsA(isA<TimeoutException>()));
    });
  });
}

class _TestServer {
  _TestServer(this._server);

  final HttpServer _server;
  final List<Future<void>> _pendingHandlers = <Future<void>>[];
  final List<Object> _handlerErrors = <Object>[];
  var _requestCount = 0;

  int get requestCount => _requestCount;

  static Future<_TestServer> start(
    Future<void> Function(HttpRequest request) handler,
  ) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final testServer = _TestServer(server);
    server.listen((request) {
      testServer._requestCount += 1;
      testServer._pendingHandlers.add(
        handler(request).catchError((Object error) {
          testServer._handlerErrors.add(error);
        }),
      );
    });
    return testServer;
  }

  Uri uri(String path) {
    return Uri.http('${_server.address.address}:${_server.port}', path);
  }

  Future<void> close() async {
    await _server.close(force: true);
    await Future.wait(_pendingHandlers);
    if (_handlerErrors.isNotEmpty) {
      Error.throwWithStackTrace(_handlerErrors.first, StackTrace.current);
    }
  }
}
