import 'dart:async';

import 'package:http/http.dart' as http;

import 'app_logger.dart';

/// [http.Client] wrapper that owns native-client shutdown semantics.
///
/// `package:http` clients define closing with active requests as undefined. For
/// platform clients backed by native callbacks, especially CupertinoClient,
/// closing at the wrong time can leave callbacks racing a torn-down Dart bridge.
/// This wrapper tracks requests until their response stream finishes, aborts
/// active requests during shutdown, and only closes the inner client once the
/// active set has drained.
class ManagedHttpClient extends http.BaseClient {
  ManagedHttpClient(this._inner, {required this.debugLabel}) {
    _instances.add(this);
  }

  static final Set<ManagedHttpClient> _instances = <ManagedHttpClient>{};

  static Future<void> closeAllGracefully({Duration drainTimeout = const Duration(seconds: 5)}) async {
    await Future.wait(
      _instances.toList().map((client) => client.closeGracefully(drainTimeout: drainTimeout)),
      eagerError: false,
    );
  }

  final http.Client _inner;
  final String debugLabel;
  final Set<_TrackedRequest> _active = <_TrackedRequest>{};

  bool _closing = false;
  bool _innerClosed = false;
  Future<void>? _closeFuture;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (_closing) {
      throw http.ClientException('HTTP client is closing', request.url);
    }

    final tracked = _TrackedRequest(request.url);
    _active.add(tracked);
    try {
      final abortableRequest = _wrapRequest(request, tracked.abortTrigger);
      final response = await _inner.send(abortableRequest);
      return _wrapResponse(response, tracked);
    } catch (_) {
      _complete(tracked);
      rethrow;
    }
  }

  Future<void> closeGracefully({Duration drainTimeout = const Duration(seconds: 2)}) {
    _closing = true;
    if (_innerClosed) return Future<void>.value();

    final existing = _closeFuture;
    if (existing != null) return existing;

    final future = _closeGracefully(drainTimeout);
    _closeFuture = future;
    unawaited(
      future.then<void>(
        (_) {
          if (!_innerClosed && identical(_closeFuture, future)) {
            _closeFuture = null;
          }
        },
        onError: (Object _, StackTrace _) {
          if (!_innerClosed && identical(_closeFuture, future)) {
            _closeFuture = null;
          }
        },
      ),
    );
    return future;
  }

  @override
  void close() {
    unawaited(closeGracefully());
  }

  Future<void> _closeGracefully(Duration drainTimeout) async {
    await _abortActive();

    if (_active.isNotEmpty) {
      try {
        await Future.wait(_active.map((request) => request.done), eagerError: false).timeout(drainTimeout);
      } on TimeoutException {
        appLogger.w('HTTP client drain timed out', error: {'client': debugLabel, 'activeRequests': _active.length});
      }
    }

    _tryCloseInner();
    if (!_innerClosed) {
      appLogger.w(
        'HTTP client close deferred until active requests finish',
        error: {'client': debugLabel, 'activeRequests': _active.length},
      );
    }
  }

  Future<void> _abortActive() async {
    await Future.wait(_active.toList().map((request) => request.cancel()), eagerError: false);
  }

  http.BaseRequest _wrapRequest(http.BaseRequest request, Future<void> managedAbortTrigger) {
    final requestAbortTrigger = request is http.Abortable ? request.abortTrigger : null;
    final abortTrigger = requestAbortTrigger == null
        ? managedAbortTrigger
        : Future.any<void>([managedAbortTrigger, requestAbortTrigger]);
    final body = request.finalize();

    final abortable = http.AbortableStreamedRequest(request.method, request.url, abortTrigger: abortTrigger)
      ..headers.addAll(request.headers)
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..persistentConnection = request.persistentConnection
      ..contentLength = request.contentLength;

    unawaited(
      body.pipe(abortable.sink).catchError((Object e, StackTrace st) {
        appLogger.d('HTTP request body pipe failed', error: e, stackTrace: st);
      }),
    );
    return abortable;
  }

  http.StreamedResponse _wrapResponse(http.StreamedResponse response, _TrackedRequest tracked) {
    late final StreamController<List<int>> controller;
    StreamSubscription<List<int>>? subscription;
    var subscribed = false;
    var cancelledBeforeListen = false;

    Future<void> cancelResponse() async {
      if (tracked.isDone) return;
      tracked.abort();
      cancelledBeforeListen = !subscribed;
      if (subscribed) {
        await subscription?.cancel();
      } else {
        final cancelSubscription = response.stream.listen(null, onError: (_) {});
        await cancelSubscription.cancel();
      }
      unawaited(controller.close());
      _complete(tracked);
    }

    controller = StreamController<List<int>>(
      sync: true,
      onListen: () {
        if (cancelledBeforeListen) {
          unawaited(controller.close());
          return;
        }
        subscribed = true;
        subscription = response.stream.listen(
          controller.add,
          onError: controller.addError,
          onDone: () {
            _complete(tracked);
            unawaited(controller.close());
          },
        );
      },
      onPause: () => subscription?.pause(),
      onResume: () => subscription?.resume(),
      onCancel: () async {
        tracked.abort();
        await subscription?.cancel();
        _complete(tracked);
      },
    );

    tracked.cancelResponse = cancelResponse;

    if (response case http.BaseResponseWithUrl(:final url)) {
      return _ManagedStreamedResponseWithUrl(
        controller.stream,
        response.statusCode,
        url: url,
        contentLength: response.contentLength,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    }

    return http.StreamedResponse(
      controller.stream,
      response.statusCode,
      contentLength: response.contentLength,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  void _complete(_TrackedRequest tracked) {
    if (!_active.remove(tracked)) return;
    tracked.complete();
    if (_closing && _active.isEmpty) {
      _tryCloseInner();
    }
  }

  void _tryCloseInner() {
    if (_innerClosed || _active.isNotEmpty) return;
    try {
      _inner.close();
      _innerClosed = true;
      _instances.remove(this);
    } catch (e, st) {
      appLogger.w('HTTP client close failed', error: e, stackTrace: st);
    }
  }
}

class _ManagedStreamedResponseWithUrl extends http.StreamedResponse implements http.BaseResponseWithUrl {
  _ManagedStreamedResponseWithUrl(
    super.stream,
    super.statusCode, {
    required this.url,
    super.contentLength,
    super.request,
    super.headers,
    super.isRedirect,
    super.persistentConnection,
    super.reasonPhrase,
  });

  @override
  final Uri url;
}

/// Deliberately not `AbortController`: this layer stays a plain [http.Client]
/// with no media-server dependency, and it needs two independent latches
/// (aborted vs. drained) plus the response canceller.
class _TrackedRequest {
  _TrackedRequest(this.url);

  final Uri url;
  final Completer<void> _abortCompleter = Completer<void>();
  final Completer<void> _doneCompleter = Completer<void>();

  Future<void> get abortTrigger => _abortCompleter.future;
  Future<void> get done => _doneCompleter.future;
  bool get isDone => _doneCompleter.isCompleted;

  Future<void> Function()? cancelResponse;

  void abort() {
    if (!_abortCompleter.isCompleted) _abortCompleter.complete();
  }

  Future<void> cancel() async {
    abort();
    await cancelResponse?.call();
  }

  void complete() {
    if (!_doneCompleter.isCompleted) _doneCompleter.complete();
  }
}
