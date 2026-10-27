import 'dart:async';
import 'dart:collection';

/// A queue that processes jobs serially, one after another.
///
/// [J] is the type of the job data.
/// [R] is the type of the result returned by the processor.
class SerialJobQueue<J, R>(final Future<R> Function(J) _processor) {
  final Queue<_Job<J, R>> _queue = Queue();
  bool _isProcessing = false;

  /// Adds data to the queue and returns a Future that completes
  /// when this specific item has been processed.
  Future<R> add(J data) {
    final completer = Completer<R>();
    _queue.add(_Job(data, completer));

    // Trigger the processing loop if it's not already running
    _processQueue();

    return completer.future;
  }

  Future<void> _processQueue() async {
    // If already running, do nothing. The loop will pick up the new item.
    if (_isProcessing) return;

    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final job = _queue.removeFirst();
      try {
        // Await the processing to ensure order
        final result = await _processor(job.data);
        job.completer.complete(result);
      } catch (e, stack) {
        job.completer.completeError(e, stack);
      }
    }

    _isProcessing = false;
  }
}

// Simple container for the data and the completer
class _Job<J, R>(final J data, final Completer<R> completer);
