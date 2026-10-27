import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'base_downloader.dart';
import 'models.dart';
import 'task.dart';

/// Commands to be executed by the background isolate
sealed class JsonCommand {
  final int id;
  const JsonCommand(this.id);
}

class _TaskFromJson extends JsonCommand {
  final String jsonString;
  const _TaskFromJson(super.id, this.jsonString);
}

class _DownloadTaskListFromJson extends JsonCommand {
  final String jsonString;
  const _DownloadTaskListFromJson(super.id, this.jsonString);
}

class _TaskListFromListStrings extends JsonCommand {
  final List<dynamic> jsonStrings;
  const _TaskListFromListStrings(super.id, this.jsonStrings);
}

class _TaskAndNotificationConfigJsonStrings extends JsonCommand {
  final List<Task> tasks;
  final Set<TaskNotificationConfig> notificationConfigs;
  const _TaskAndNotificationConfigJsonStrings(
    super.id,
    this.tasks,
    this.notificationConfigs,
  );
}

/// Singleton object that manages a background isolate for JSON encoding/decoding
class JsonProcessor {
  static final JsonProcessor _instance = JsonProcessor._internal();

  factory JsonProcessor() => _instance;

  JsonProcessor._internal();

  Isolate? _isolate;
  SendPort? _sendPort;
  final Map<int, Completer<dynamic>> _pendingCompleters = {};
  Timer? _shutdownTimer;
  int _nextId = 0;
  bool _isStarting = false;
  Completer<void> _startCompleter = Completer<void>();

  /// Public API

  Future<Task> decodeTask(String jsonString) async =>
      await _process<Task>((id) => _TaskFromJson(id, jsonString));

  Future<List<DownloadTask>> decodeDownloadTaskList(String jsonString) async =>
      await _process<List<DownloadTask>>(
        (id) => _DownloadTaskListFromJson(id, jsonString),
      );

  Future<List<Task>> decodeTaskList(List<dynamic> jsonStrings) async =>
      await _process<List<Task>>(
        (id) => _TaskListFromListStrings(id, jsonStrings),
      );

  Future<(String, String)> encodeTaskAndNotificationConfig(
    Iterable<Task> tasks,
    Set<TaskNotificationConfig> notificationConfigs,
  ) async {
    // Convert Iterable to List to ensure it's sendable and fixed
    final taskList = tasks.toList();
    return await _process<(String, String)>(
      (id) => _TaskAndNotificationConfigJsonStrings(
        id,
        taskList,
        notificationConfigs,
      ),
    );
  }

  /// Internal processing logic

  Future<T> _process<T>(JsonCommand Function(int id) commandBuilder) async {
    await _ensureStarted();
    _resetShutdownTimer();

    final id = _nextId++;
    final completer = Completer<T>();
    _pendingCompleters[id] = completer;

    final command = commandBuilder(id);
    _sendPort!.send(command);

    try {
      final result = await completer.future;
      return result;
    } catch (e) {
      rethrow;
    } finally {
      _resetShutdownTimer(); // Reset timer on completion too
    }
  }

  Future<void> _ensureStarted() async {
    if (_isolate != null && _sendPort != null) return;

    if (_isStarting) {
      await _startCompleter.future;
      return;
    }

    _isStarting = true;
    _startCompleter = Completer<void>();

    try {
      final receivePort = ReceivePort();
      _isolate = await Isolate.spawn(_isolateMain, receivePort.sendPort);

      // Wait for the isolate to send its SendPort
      _sendPort = await receivePort.first as SendPort;

      // Create a new receive port for responses
      final responsePort = ReceivePort();
      _sendPort!.send(responsePort.sendPort);

      responsePort.listen(_handleResponse);

      if (!_startCompleter.isCompleted) {
        _startCompleter.complete();
      }
    } catch (e) {
      _isolate?.kill();
      _isolate = null;
      _sendPort = null;
      _isStarting = false;
      if (!_startCompleter.isCompleted) {
        _startCompleter.completeError(e);
      }
      rethrow;
    } finally {
      _isStarting = false;
    }
  }

  void _handleResponse(dynamic message) {
    if (message is _JsonResponse) {
      final completer = _pendingCompleters.remove(message.id);
      if (completer != null) {
        if (message.error != null) {
          completer.completeError(message.error!);
        } else {
          completer.complete(message.result);
        }
      }
    }
  }

  void _resetShutdownTimer() {
    _shutdownTimer?.cancel();
    _shutdownTimer = Timer(const Duration(minutes: 1), _shutdown);
  }

  void _shutdown() {
    if (_pendingCompleters.isNotEmpty) {
      // Defer shutdown while requests are still in flight
      _resetShutdownTimer();
      return;
    }
    _isolate?.kill();
    _isolate = null;
    _sendPort = null;
    _shutdownTimer?.cancel();
    _shutdownTimer = null;
  }
}

class _JsonResponse {
  final int id;
  final dynamic result;
  final Object? error;

  _JsonResponse(this.id, this.result, this.error);
}

void _isolateMain(SendPort mainSendPort) {
  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort);

  SendPort? replyPort;

  receivePort.listen((message) async {
    if (message is SendPort) {
      replyPort = message;
    } else if (message is JsonCommand) {
      if (replyPort == null) {
        return; // Should not happen if protocol is followed
      }

      try {
        final result = await _executeCommand(message);
        replyPort!.send(_JsonResponse(message.id, result, null));
      } catch (e) {
        replyPort!.send(_JsonResponse(message.id, null, e));
      }
    }
  });
}

Future<dynamic> _executeCommand(JsonCommand command) async {
  switch (command) {
    case final _TaskFromJson c:
      return Task.createFromJson(jsonDecode(c.jsonString));

    case final _DownloadTaskListFromJson c:
      return (jsonDecode(c.jsonString) as List)
          .map((e) => Task.createFromJson(e as Map<String, dynamic>))
          .cast<DownloadTask>()
          .toList();

    case final _TaskListFromListStrings c:
      return c.jsonStrings
          .map((e) => Task.createFromJson(jsonDecode(e as String)))
          .toList();

    case final _TaskAndNotificationConfigJsonStrings c:
      final tasksJsonString = jsonEncode(c.tasks);
      final configs = c.tasks
          .map(
            (task) => BaseDownloader.notificationConfigForTaskUsingConfigSet(
              task,
              c.notificationConfigs,
            ),
          )
          .toList();
      final notificationConfigsJsonString = jsonEncode(configs);
      return (tasksJsonString, notificationConfigsJsonString);
  }
}
