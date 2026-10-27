import 'dart:ui';

import '../models.dart';
import '../task.dart';
import 'auth.dart';

typedef BeforeTaskStartCallback = Future<TaskStatusUpdate?> Function(Task task);

typedef OnTaskStartCallback = Future<Task?> Function(Task original);

typedef OnTaskFinishedCallback = Future<void> Function(
  TaskStatusUpdate taskStatusUpdate,
);

/// Holds various options related to the task that are not included in the
/// task's properties, as they are rare
class TaskOptions {
  final int? _beforeTaskStartRawHandle;
  final int? _onTaskStartRawHandle;
  final int? _onTaskFinishedRawHandle;

  /// The [Auth] object associated with this task
  final Auth? auth;

  /// Constructor for [TaskOptions], containing "native" callbacks:
  ///
  /// * `beforeTaskStart`: a callback called before a task starts executing.
  ///    The callback receives the `Task` and returns `null` if the task should
  ///    continue, or a `TaskStatusUpdate` if it should not start - in which
  ///    case the `TaskStatusUpdate` is posted as the last state update for the task
  /// * `onTaskStart`: a callback called before a task starts executing.
  ///    The callback receives the `Task` and returns `null` if it did not
  ///    change anything, or a modified `Task` if it needs to use a different
  ///    url or header. It is called after `onAuth` for token refresh, if that is set
  /// * `onTaskFinished`: a callback called when the task has finished.
  ///    The callback receives the final `TaskStatusUpdate`.
  /// * `auth`: an [Auth] object that facilitates management of authorization
  ///    tokens and refresh tokens, and includes an `onAuth` callback similar to
  ///    `onTaskStart`
  TaskOptions({
    BeforeTaskStartCallback? beforeTaskStart,
    OnTaskStartCallback? onTaskStart,
    OnTaskFinishedCallback? onTaskFinished,
    this.auth,
  }) : _beforeTaskStartRawHandle = beforeTaskStart != null
           ? PluginUtilities.getCallbackHandle(beforeTaskStart)?.toRawHandle()
           : null,
       _onTaskStartRawHandle = onTaskStart != null
           ? PluginUtilities.getCallbackHandle(onTaskStart)?.toRawHandle()
           : null,
       _onTaskFinishedRawHandle = onTaskFinished != null
           ? PluginUtilities.getCallbackHandle(onTaskFinished)?.toRawHandle()
           : null {
    assert(
      beforeTaskStart == null || _beforeTaskStartRawHandle != null,
      _notTopLevel('beforeTaskStart'),
    );
    assert(
      onTaskStart == null || _onTaskStartRawHandle != null,
      _notTopLevel('onTaskStart'),
    );
    assert(
      onTaskFinished == null || _onTaskFinishedRawHandle != null,
      _notTopLevel('onTaskFinished'),
    );
  }

  static String _notTopLevel(String callbackName) =>
      '$callbackName callback must be a top level or static function, '
      'and marked with @pragma("vm:entry-point")';

  /// Create the object from JSON
  TaskOptions.fromJson(Map<String, dynamic> json)
    : _beforeTaskStartRawHandle = json['beforeTaskStartRawHandle'] as int?,
      _onTaskStartRawHandle = json['onTaskStartRawHandle'] as int?,
      _onTaskFinishedRawHandle = json['onTaskFinishedRawHandle'] as int?,
      auth = json['auth'] != null ? Auth.fromJson(json['auth']) : null;

  /// Returns the [BeforeTaskStartCallback] registered with this [TaskOptions], or null
  BeforeTaskStartCallback? get beforeTaskStartCallBack =>
      _beforeTaskStartRawHandle != null
      ? PluginUtilities.getCallbackFromHandle(
          CallbackHandle.fromRawHandle(_beforeTaskStartRawHandle),
        ) as BeforeTaskStartCallback
      : null;

  /// Returns the [OnTaskStartCallback] registered with this [TaskOptions], or null
  OnTaskStartCallback? get onTaskStartCallBack => _onTaskStartRawHandle != null
      ? PluginUtilities.getCallbackFromHandle(
          CallbackHandle.fromRawHandle(_onTaskStartRawHandle),
        ) as OnTaskStartCallback
      : null;

  /// Returns the [OnTaskFinishedCallback] registered with this [TaskOptions], or null
  OnTaskFinishedCallback? get onTaskFinishedCallBack =>
      _onTaskFinishedRawHandle != null
      ? PluginUtilities.getCallbackFromHandle(
          CallbackHandle.fromRawHandle(_onTaskFinishedRawHandle),
        ) as OnTaskFinishedCallback
      : null;

  /// True if [TaskOptions] contains any callback
  bool get hasCallback =>
      beforeTaskStartCallBack != null ||
      onTaskStartCallBack != null ||
      onTaskFinishedCallBack != null ||
      auth?.onAuthCallback != null;

  /// Creates JSON map of this object
  Map<String, dynamic> toJson() => {
    'beforeTaskStartRawHandle': _beforeTaskStartRawHandle,
    'onTaskStartRawHandle': _onTaskStartRawHandle,
    'onTaskFinishedRawHandle': _onTaskFinishedRawHandle,
    'auth': auth?.toJson(),
  };
}
