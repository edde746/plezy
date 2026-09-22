import 'dart:async';

import 'app_logger.dart';

extension NamedTimeoutExtension<T> on Future<T> {
  /// Like [Future.timeout], but the [TimeoutException] includes [operation]
  /// so crash reports identify which call timed out.
  Future<T> namedTimeout(Duration timeLimit, {required String operation}) {
    return timeout(
      timeLimit,
      onTimeout: () {
        throw TimeoutException('$operation timed out', timeLimit);
      },
    );
  }

  /// Like [namedTimeout], but the work is not abandoned at [timeLimit]: a
  /// value that still arrives after the caller stopped waiting is handed to
  /// [releaseLate].
  ///
  /// For requests whose success allocates a server-side resource that only
  /// the response can name — a tuner opened by a live tune. Cancelling such a
  /// request does not stop the server's work, so the resource would otherwise
  /// belong to nobody. Late failures, including from [releaseLate], are
  /// logged and dropped.
  Future<T> timeoutReleasingLate(
    Duration timeLimit, {
    required String operation,
    required FutureOr<void> Function(T value) releaseLate,
  }) {
    return timeout(
      timeLimit,
      onTimeout: () {
        unawaited(
          then<void>(releaseLate).catchError((Object error, StackTrace stackTrace) {
            appLogger.d('$operation finished after its caller stopped waiting', error: error, stackTrace: stackTrace);
          }),
        );
        throw TimeoutException('$operation timed out', timeLimit);
      },
    );
  }
}
