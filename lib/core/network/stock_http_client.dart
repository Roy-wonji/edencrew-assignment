import 'dart:async';
import 'dart:io';

abstract interface class StockHttpClient {
  Future<List<int>> get(Uri uri);

  Future<void> close();
}

class DartIoStockHttpClient implements StockHttpClient {
  DartIoStockHttpClient({
    HttpClient? client,
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 10),
    int maxBytes = 2 * 1024 * 1024,
  }) : _client = client ?? HttpClient(),
       _headers = Map.unmodifiable(headers),
       _timeout = timeout,
       _maxBytes = maxBytes;

  final HttpClient _client;
  final Map<String, String> _headers;
  final Duration _timeout;
  final int _maxBytes;

  @override
  Future<List<int>> get(Uri uri) async {
    HttpClientRequest? request;
    StreamSubscription<List<int>>? subscription;
    Completer<List<int>>? bodyCompleter;
    var expired = false;
    final operation = () async {
      request = await _client.getUrl(uri);
      if (expired) {
        request!.abort();
        throw TimeoutException('GET $uri timed out after $_timeout');
      }

      for (final entry in _headers.entries) {
        request!.headers.set(entry.key, entry.value);
      }

      final response = await request!.close();
      if (expired) {
        throw TimeoutException('GET $uri timed out after $_timeout');
      }

      final bytes = <int>[];
      final completer = Completer<List<int>>();
      bodyCompleter = completer;
      subscription = response.listen(
        (chunk) {
          bytes.addAll(chunk);
          if (bytes.length > _maxBytes && !completer.isCompleted) {
            completer.completeError(
              HttpException('GET $uri exceeded $_maxBytes bytes'),
            );
            unawaited(
              subscription?.cancel().catchError((Object _) {
                return null;
              }),
            );
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }
        },
        onDone: () {
          if (completer.isCompleted) {
            return;
          }
          if (response.statusCode < 200 || response.statusCode >= 300) {
            completer.completeError(
              HttpException(
                'GET $uri failed with status ${response.statusCode}',
              ),
            );
            return;
          }
          completer.complete(bytes);
        },
        cancelOnError: true,
      );

      return completer.future.whenComplete(() {
        subscription = null;
        bodyCompleter = null;
      });
    }();

    return operation.timeout(
      _timeout,
      onTimeout: () {
        expired = true;
        request?.abort();
        final completer = bodyCompleter;
        if (completer != null && !completer.isCompleted) {
          completer.completeError(
            TimeoutException('GET $uri timed out after $_timeout'),
          );
        }

        final activeSubscription = subscription;
        subscription = null;
        if (activeSubscription != null) {
          unawaited(
            activeSubscription.cancel().catchError((Object _) {
              return null;
            }),
          );
        }
        throw TimeoutException('GET $uri timed out after $_timeout');
      },
    );
  }

  @override
  Future<void> close() async {
    _client.close(force: true);
  }
}
