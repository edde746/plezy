import 'dart:io';

import '../task.dart';

typedef OnAuthCallback = Future<Task?> Function(Task original);

/// Default onAuth callback
///
/// Called when a task starts and the task has an auth object and the
/// object indicated that the access token has expired.
/// The callback attempts to refresh the access token using the information
/// contained in the [Auth] object, and returns the task, which now contains an
/// updated [Auth] object
@pragma("vm:entry-point")
Future<Task?> defaultOnAuth(Task task) async {
  final auth = task.options?.auth;
  if (auth == null) {
    throw ArgumentError('Task has no auth object');
  }
  final (updatedAccessToken, updatedRefreshToken) = await auth
      .refreshAccessToken();
  if (!updatedAccessToken) {
    throw const HttpException('Could not refresh access token');
  }
  return task;
}
