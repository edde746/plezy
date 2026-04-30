/// Throw from a [pollWithBackoff] probe to stop polling without a value.
/// Used for terminal server responses (e.g. 404 secret expired) where the
/// outer caller wants `null` rather than the next iteration.
class PollTerminatedSignal implements Exception {
  const PollTerminatedSignal();
}

/// Poll [probe] until it returns a non-null value, [shouldCancel] returns
/// true, [endTime] is reached, or [PollTerminatedSignal] is thrown.
///
/// Uses exponential backoff between probes: starts at [initial], doubles
/// each iteration, capped at [maxBackoff]. Returns the first non-null
/// probe result, or null on cancel / timeout / terminated signal.
///
/// Other exceptions thrown from [probe] propagate to the caller — wrap
/// the probe with your own try/catch if you want to swallow transient
/// network errors.
Future<T?> pollWithBackoff<T>({
  required Future<T?> Function() probe,
  required DateTime endTime,
  bool Function()? shouldCancel,
  Duration initial = const Duration(seconds: 1),
  Duration maxBackoff = const Duration(seconds: 5),
}) async {
  var backoff = initial;
  while (DateTime.now().isBefore(endTime)) {
    if (shouldCancel?.call() ?? false) return null;
    try {
      final result = await probe();
      if (result != null) return result;
    } on PollTerminatedSignal {
      return null;
    }
    await Future.delayed(backoff);
    final next = backoff * 2;
    backoff = next > maxBackoff ? maxBackoff : next;
  }
  return null;
}
