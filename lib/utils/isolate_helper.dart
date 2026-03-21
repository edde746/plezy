import 'dart:isolate';

/// Runs [computation] in a background isolate via [Isolate.run].
///
/// Falls back to synchronous execution when the isolate infrastructure is
/// unavailable (e.g. iOS killed background isolates while the app was
/// suspended).
Future<R> tryIsolateRun<R>(R Function() computation) async {
  try {
    return await Isolate.run(computation);
  } on StateError {
    return computation();
  }
}
