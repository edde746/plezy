import 'dart:async';

extension NamedTimeoutExtension<T> on Future<T> {
  /// Like [Future.timeout], but the [TimeoutException] includes [operation]
  /// so crash reports identify which call timed out.
  Future<T> namedTimeout(Duration timeLimit, {required String operation}) {
    return timeout(timeLimit, onTimeout: () {
      throw TimeoutException('$operation timed out', timeLimit);
    });
  }
}
